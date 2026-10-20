[CmdletBinding()]
param(
    [switch]$ReplacePending
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$credentialPath = Join-Path $repositoryRoot '.env.apex'
$pendingPath = Join-Path $repositoryRoot '.env.apex.pending'
$previousPath = Join-Path $repositoryRoot '.env.apex.previous'
$sqlScript = Join-Path $PSScriptRoot 'provision_apex_script_admin.sql'
$sqlPlus = (Get-Command sqlplus -ErrorAction Stop).Source

if (-not (Test-Path $credentialPath)) {
    throw '.env.apex is missing.'
}
if (-not (Test-Path $sqlScript)) {
    throw "Provisioning SQL script is missing: $sqlScript"
}
if ((Test-Path $pendingPath) -and -not $ReplacePending) {
    throw '.env.apex.pending already exists; inspect it or pass -ReplacePending explicitly.'
}
if (Test-Path $pendingPath) {
    Remove-Item -LiteralPath $pendingPath -Force
}
if (Test-Path $previousPath) {
    throw '.env.apex.previous already exists; inspect it before retrying.'
}
foreach ($ignoredPath in @('.env.apex', '.env.apex.pending', '.env.apex.previous')) {
    & git -C $repositoryRoot check-ignore --quiet $ignoredPath
    if ($LASTEXITCODE -ne 0) {
        throw "Git does not ignore $ignoredPath; refusing to write credentials."
    }
}

$existingLines = [System.Collections.Generic.List[string]]::new()
foreach ($line in [System.IO.File]::ReadAllLines($credentialPath)) {
    if ($line -notmatch '^APEX_SCRIPT_ADMIN_(USERNAME|EMAIL|PASSWORD)=') {
        $existingLines.Add($line)
    }
}
if ($ReplacePending -and (Test-Path $pendingPath)) {
    foreach ($line in [System.IO.File]::ReadAllLines($pendingPath)) {
        if ($line -match '^APEX_LOGIN_TEST_(USERNAME|PASSWORD)=') {
            $existingLines.Add($line)
        }
    }
}
$upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
$lower = 'abcdefghijkmnopqrstuvwxyz'
$digits = '23456789'
$punctuation = '!@#$%^*_+=?.-'
$alphabet = $upper + $lower + $digits + $punctuation
$random = [System.Security.Cryptography.RandomNumberGenerator]::Create()

function Get-SecureIndex {
    param([Parameter(Mandatory)][int]$Maximum)

    $bytes = [byte[]]::new(1)
    $limit = 256 - (256 % $Maximum)
    do {
        $script:random.GetBytes($bytes)
        $candidate = [int]$bytes[0]
    } while ($candidate -ge $limit)

    return $candidate % $Maximum
}

try {
    $characters = [System.Collections.Generic.List[char]]::new()
    foreach ($requiredSet in @($upper, $lower, $digits, $punctuation)) {
        $characters.Add($requiredSet[(Get-SecureIndex -Maximum $requiredSet.Length)])
    }
    for ($index = $characters.Count; $index -lt 24; $index++) {
        $characters.Add($alphabet[(Get-SecureIndex -Maximum $alphabet.Length)])
    }
    for ($index = $characters.Count - 1; $index -gt 0; $index--) {
        $swapIndex = Get-SecureIndex -Maximum ($index + 1)
        $temporary = $characters[$index]
        $characters[$index] = $characters[$swapIndex]
        $characters[$swapIndex] = $temporary
    }
    $password = -join $characters

    $credentialLines = @($existingLines) + @(
        'APEX_SCRIPT_ADMIN_USERNAME=QAFE_DEMO_SCRIPT_ADMIN'
        'APEX_SCRIPT_ADMIN_EMAIL=qafe-demo-script-admin@localhost.invalid'
        "APEX_SCRIPT_ADMIN_PASSWORD=$password"
    )
    [System.IO.File]::WriteAllLines(
        $pendingPath,
        $credentialLines,
        [System.Text.UTF8Encoding]::new($false)
    )

    $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    & icacls.exe $pendingPath /inheritance:r /grant:r `
        "*$($currentSid):(F)" '*S-1-5-18:(F)' '*S-1-5-32-544:(F)' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Remove-Item -LiteralPath $pendingPath -Force
        throw 'Could not restrict pending credential-file permissions; no database provisioning was attempted.'
    }

    $info = [System.Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $sqlPlus
    $info.Arguments = '-L /nolog'
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $info
    if (-not $process.Start()) {
        throw 'SQL*Plus could not be started; pending credentials were retained.'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $inputLines = @(
        'set echo off'
        'set verify off'
        'set define on'
        'set heading off'
        'set feedback off'
        'whenever oserror exit failure'
        'whenever sqlerror exit sql.sqlcode'
        'connect / as sysdba'
        'alter session set container=ORACLE_FORMS_EXAMPLES;'
        "@$sqlScript"
        $password
        'variable auth_status number'
        "declare l_auth apex_240200.wwv_flow_workspace_user_api.t_authentication_result; begin l_auth:=apex_240200.wwv_flow_fnd_user_int.authenticate(p_user_name=>'QAFE_DEMO_SCRIPT_ADMIN',p_password=>'&apex_password',p_workspace=>'QAFE_FORMS_DEMO'); :auth_status:=l_auth.status; end;"
        '/'
        "select 'APEX_AUTH_STATUS='||:auth_status from dual;"
        "select 'APEX_USER_COUNT='||count(*) from apex_workspace_apex_users where workspace_id=apex_util.find_security_group_id(p_workspace=>'QAFE_FORMS_DEMO') and user_name='QAFE_DEMO_SCRIPT_ADMIN';"
        'exit'
    )
    foreach ($line in $inputLines) {
        $process.StandardInput.WriteLine($line)
    }
    $process.StandardInput.Close()

    if (-not $process.WaitForExit(120000)) {
        $process.Kill()
        throw 'Provisioning timed out; pending credentials were retained. Inspect workspace state before retrying.'
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $safeOutput = "$stdout`n$stderr".Replace($password, '[REDACTED]')
    $authMatch = [regex]::Match($safeOutput, '(?m)^APEX_AUTH_STATUS=(\d+)\s*$')
    $userMatch = [regex]::Match($safeOutput, '(?m)^APEX_USER_COUNT=(\d+)\s*$')
    if ($process.ExitCode -ne 0) {
        $errors = [regex]::Matches($safeOutput, '\b(?:ORA|SP2)-\d{4,5}\b') |
            ForEach-Object { $_.Value } | Select-Object -Unique
        $summary = if ($errors) { $errors -join ', ' } else { 'SQL*Plus provisioning failed' }
        throw "Sibling-pattern provisioning failed ($summary); credentials remain pending."
    }
    if (-not $authMatch.Success -or $authMatch.Groups[1].Value -ne '0' -or
        -not $userMatch.Success -or $userMatch.Groups[1].Value -ne '1') {
        $authStatus = if ($authMatch.Success) { $authMatch.Groups[1].Value } else { 'missing' }
        $userCount = if ($userMatch.Success) { $userMatch.Groups[1].Value } else { 'missing' }
        throw "Provisioning verification failed (auth=$authStatus; user_count=$userCount); credentials remain pending."
    }

    [System.IO.File]::Replace($pendingPath, $credentialPath, $previousPath)
    Remove-Item -LiteralPath $previousPath -Force
    Write-Output 'QAFE_DEMO_SCRIPT_ADMIN created and authenticated (status 0); credentials saved in ignored .env.apex without display.'
}
finally {
    Set-Clipboard -Value 'CLEARED'
    $random.Dispose()
    $password = $null
    $characters = $null
    $credentialLines = $null
    $existingLines = $null
    $inputLines = $null
    $stdout = $null
    $stderr = $null
    $safeOutput = $null
}
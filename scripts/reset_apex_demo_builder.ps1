[CmdletBinding()]
param(
    [switch]$ReplacePending
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$credentialPath = Join-Path $repositoryRoot '.env.apex'
$pendingPath = Join-Path $repositoryRoot '.env.apex.pending'
$previousPath = Join-Path $repositoryRoot '.env.apex.previous'
$sqlPlus = (Get-Command sqlplus -ErrorAction Stop).Source

if (-not (Test-Path $credentialPath)) {
    throw '.env.apex is missing.'
}
if ((Test-Path $pendingPath) -and -not $ReplacePending) {
    throw '.env.apex.pending already exists; inspect it before retrying.'
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

$existingLines = [System.IO.File]::ReadAllLines($credentialPath) |
    Where-Object { $_ -notmatch '^APEX_DEMO_PASSWORD=' }
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

    $credentialLines = @($existingLines) + "APEX_DEMO_PASSWORD=$password"
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
        throw 'Could not restrict pending credential-file permissions; no database update was attempted.'
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
        throw 'SQL*Plus could not be started; pending credentials are retained.'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $plsql = @"
variable auth_status number
declare
    l_security_group_id number;
    l_user_id number;
    l_auth apex_240200.wwv_flow_workspace_user_api.t_authentication_result;
begin
    l_security_group_id := apex_util.find_security_group_id(p_workspace => 'QAFE_FORMS_CLEAN');
    if l_security_group_id is null then
        raise_application_error(-20020, 'QAFE_FORMS_CLEAN workspace not found.');
    end if;

    apex_util.set_security_group_id(p_security_group_id => l_security_group_id);
    select user_id into l_user_id
      from apex_240200.wwv_flow_fnd_user
     where security_group_id = l_security_group_id
    and user_name = 'QAFE_FORMS_BUILDER';

    apex_util.edit_user(
        p_user_id                      => l_user_id,
        p_user_name                    => 'QAFE_FORMS_BUILDER',
        p_web_password                 => '$password',
        p_new_password                 => '$password',
        p_email_address                => 'qafe-forms-builder@localhost.invalid',
        p_allow_access_to_schemas      => 'STUDENT',
        p_default_schema               => 'STUDENT',
        p_developer_roles              => 'CREATE:EDIT',
        p_account_locked               => 'N',
        p_failed_access_attempts       => 0,
        p_change_password_on_first_use => 'N',
        p_first_password_use_occurred  => 'N');
    commit;

    l_auth := apex_240200.wwv_flow_fnd_user_int.authenticate(
        p_user_name => 'QAFE_FORMS_BUILDER',
        p_password  => '$password',
        p_workspace => 'QAFE_FORMS_CLEAN');
    :auth_status := l_auth.status;
end;
/
select 'AUTH_STATUS='||:auth_status as auth_status from dual;
"@
    $inputLines = @(
        'set echo off'
        'set verify off'
        'set define off'
        'set feedback off'
        'set heading off'
        'whenever oserror exit failure'
        'whenever sqlerror exit sql.sqlcode'
        'connect / as sysdba'
        'alter session set container=QAFE_CLEAN;'
        $plsql
        'exit'
    )
    foreach ($line in $inputLines) {
        $process.StandardInput.WriteLine($line)
    }
    $process.StandardInput.Close()
    if (-not $process.WaitForExit(120000)) {
        $process.Kill()
        throw 'Reset timed out; pending credentials remain. Do not retry until account state is checked.'
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $safeOutput = "$stdout`n$stderr".Replace($password, '[REDACTED]')
    $statusMatch = [regex]::Match($safeOutput, '(?m)^\s*AUTH_STATUS=(\d+)\s*$')
    if ($process.ExitCode -ne 0) {
        $errors = [regex]::Matches($safeOutput, '\b(?:ORA|SP2)-\d{4,5}\b') |
            ForEach-Object { $_.Value } | Select-Object -Unique
        $summary = if ($errors) { $errors -join ', ' } else { 'SQL*Plus failed' }
        throw "APEX_UTIL.EDIT_USER failed ($summary); pending credentials remain and were not promoted."
    }
    if (-not $statusMatch.Success -or $statusMatch.Groups[1].Value -ne '0') {
        $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value } else { 'not returned' }
        throw "APEX authentication check returned status $status; pending credentials remain and were not promoted."
    }

    [System.IO.File]::Replace($pendingPath, $credentialPath, $previousPath)
    Remove-Item -LiteralPath $previousPath -Force
    Write-Output 'APEX_UTIL.EDIT_USER completed; APEX authentication status is 0 and .env.apex was updated without displaying the password.'
}
finally {
    Set-Clipboard -Value 'CLEARED'
    $random.Dispose()
    $password = $null
    $characters = $null
    $credentialLines = $null
    $existingLines = $null
    $plsql = $null
    $inputLines = $null
    $stdout = $null
    $stderr = $null
    $safeOutput = $null
}
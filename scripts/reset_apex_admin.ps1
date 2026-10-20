[CmdletBinding()]
param(
    [switch]$RotateExisting,
    [switch]$ReplacePending,
    [switch]$PromotePending
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$credentialPath = Join-Path $repositoryRoot '.env.apex'
$pendingPath = Join-Path $repositoryRoot '.env.apex.pending'
$previousPath = Join-Path $repositoryRoot '.env.apex.previous'
$ignorePath = Join-Path $repositoryRoot '.gitignore'
$apexHome = 'C:\Oracle\ORDS\apex-media\apex_24.2_en_restored_tar\apex'
$resetScript = Join-Path $apexHome 'apxchpwd.sql'

if ($PromotePending) {
    if ($RotateExisting -or $ReplacePending) {
        throw 'Use -PromotePending by itself.'
    }
    if (-not (Test-Path $credentialPath) -or -not (Test-Path $pendingPath)) {
        throw 'Both .env.apex and .env.apex.pending must exist to promote a completed reset.'
    }
    if (Test-Path $previousPath) {
        throw '.env.apex.previous already exists; refusing to overwrite the backup.'
    }
}
else {
    if (Test-Path $previousPath) {
        throw '.env.apex.previous already exists; refusing to overwrite the backup.'
    }
    if ((Test-Path $credentialPath) -and -not $RotateExisting) {
        throw '.env.apex already exists. Refusing to overwrite local credentials.'
    }
    if ((Test-Path $pendingPath) -and -not $ReplacePending) {
        throw '.env.apex.pending already exists. Review or remove that ignored pending file before retrying.'
    }
    if (Test-Path $pendingPath) {
        Remove-Item -LiteralPath $pendingPath -Force
    }
}

if (-not $PromotePending -and -not (Test-Path $resetScript)) {
    throw "APEX password reset script not found: $resetScript"
}

if (-not $PromotePending -and -not (Test-Path (Join-Path $apexHome 'core\scripts\set_appun.sql'))) {
    throw 'The APEX home is incomplete; core/scripts/set_appun.sql is missing.'
}

if (-not (Select-String -Path $ignorePath -SimpleMatch '/.env.apex' -Quiet)) {
    throw '.gitignore must ignore /.env.apex before credentials are generated.'
}

foreach ($ignoredPath in @('.env.apex', '.env.apex.pending', '.env.apex.previous')) {
    & git -C $repositoryRoot check-ignore --quiet $ignoredPath
    if ($LASTEXITCODE -ne 0) {
        throw "Git does not currently ignore $ignoredPath; refusing to create credentials."
    }
}

if ($PromotePending) {
    [System.IO.File]::Replace($pendingPath, $credentialPath, $previousPath)
    Remove-Item -LiteralPath $previousPath -Force
    Write-Output 'The completed APEX password reset is now stored in Git-ignored .env.apex; the password was not displayed.'
    return
}

$sqlPlus = (Get-Command sqlplus -ErrorAction Stop).Source

$upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
$lower = 'abcdefghijkmnopqrstuvwxyz'
$digits = '23456789'
$symbols = '!#$%*+-=?@^_'
$alphabet = $upper + $lower + $digits + $symbols
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
    $passwordCharacters = [System.Collections.Generic.List[char]]::new()
    foreach ($requiredSet in @($upper, $lower, $digits, $symbols)) {
        $passwordCharacters.Add($requiredSet[(Get-SecureIndex -Maximum $requiredSet.Length)])
    }
    for ($index = $passwordCharacters.Count; $index -lt 32; $index++) {
        $passwordCharacters.Add($alphabet[(Get-SecureIndex -Maximum $alphabet.Length)])
    }
    for ($index = $passwordCharacters.Count - 1; $index -gt 0; $index--) {
        $swapIndex = Get-SecureIndex -Maximum ($index + 1)
        $temporary = $passwordCharacters[$index]
        $passwordCharacters[$index] = $passwordCharacters[$swapIndex]
        $passwordCharacters[$swapIndex] = $temporary
    }
    $password = -join $passwordCharacters

    $workspaceCredentials = @()
    if (Test-Path $credentialPath) {
        $workspaceCredentials = [System.IO.File]::ReadAllLines($credentialPath) |
            Where-Object { $_ -match '^APEX_DEMO_(WORKSPACE|USERNAME|EMAIL|PASSWORD)=' }
    }
    $credentialLines = @(
        '# Generated locally by scripts/reset_apex_admin.ps1; ignored by Git.'
        'APEX_ADMIN_URL=http://127.0.0.1:8080/ords/qafe_clean/apex_admin'
        'APEX_ADMIN_USERNAME=ADMIN'
        'APEX_ADMIN_EMAIL=apex-admin@localhost.invalid'
        "APEX_ADMIN_PASSWORD=$password"
        'APEX_WORKSPACE_URL=http://127.0.0.1:8080/ords/qafe_clean/apex'
        'APEX_PDB_SERVICE=QAFE_CLEAN'
    ) + $workspaceCredentials
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
        throw 'Could not restrict pending credential-file permissions; the file was removed and no password reset was attempted.'
    }

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $sqlPlus
    $startInfo.Arguments = '-L /nolog'
    $startInfo.WorkingDirectory = $apexHome
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        Remove-Item -LiteralPath $pendingPath -Force
        throw 'SQL*Plus could not be started; the credential file was removed.'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $sqlInput = @(
        'whenever oserror exit failure'
        'whenever sqlerror exit sql.sqlcode'
        'connect / as sysdba'
        'alter session set container=QAFE_CLEAN;'
        "@$resetScript"
        'ADMIN'
        'apex-admin@localhost.invalid'
        $password
        'exit'
    )
    foreach ($line in $sqlInput) {
        $process.StandardInput.WriteLine($line)
    }
    $process.StandardInput.Close()

    if (-not $process.WaitForExit(120000)) {
        $process.Kill()
        throw 'SQL*Plus timed out. .env.apex was retained because reset completion is uncertain; do not assume the password is active.'
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    if ($process.ExitCode -ne 0) {
        $errorCodes = [regex]::Matches("$stdout`n$stderr", '\b(?:ORA|SP2)-\d{4,5}\b') |
            ForEach-Object { $_.Value } |
            Select-Object -Unique
        $safeErrorSummary = if ($errorCodes) { $errorCodes -join ', ' } else { 'SQL*Plus returned a non-zero exit code' }
        $safeOutput = "$stdout`n$stderr".Replace($password, '[REDACTED]')
        $safeLines = ($safeOutput -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 12) -join ' | '
        throw "APEX administrator reset failed (exit $($process.ExitCode); $safeErrorSummary). Sanitized SQL*Plus context: $safeLines. .env.apex.pending was retained and .env.apex was not changed; verify reset status before attempting sign-in."
    }

    if (Test-Path $credentialPath) {
        [System.IO.File]::Replace($pendingPath, $credentialPath, $previousPath)
        Remove-Item -LiteralPath $previousPath -Force
    }
    else {
        [System.IO.File]::Move($pendingPath, $credentialPath)
    }

    Write-Output 'APEX ADMIN password reset completed. Local connection details are in the Git-ignored .env.apex; the password was not displayed.'
}
finally {
    $random.Dispose()
    $password = $null
    $passwordCharacters = $null
    $sqlInput = $null
    $stdout = $null
    $stderr = $null
    $workspaceCredentials = $null
}
[CmdletBinding()]
param(
    [switch]$ReplacePending,
    [switch]$PromotePending
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$credentialPath = Join-Path $repositoryRoot '.env.apex'
$pendingPath = Join-Path $repositoryRoot '.env.apex.pending'
$previousPath = Join-Path $repositoryRoot '.env.apex.previous'
$ignorePath = Join-Path $repositoryRoot '.gitignore'
$sqlPlus = (Get-Command sqlplus -ErrorAction Stop).Source

$workspaceName = 'QAFE_FORMS_CLEAN'
$workspaceUsername = 'QAFE_FORMS_BUILDER'
$workspaceEmail = 'qafe-forms-builder@localhost.invalid'
$workspaceDescription = 'Local loopback-only read-only demonstration for QAFE_FORM1.'
$defaultSchema = 'STUDENT'

if ($PromotePending) {
    if ($ReplacePending) {
        throw 'Use -PromotePending by itself.'
    }
    if (-not (Test-Path $credentialPath) -or -not (Test-Path $pendingPath)) {
        throw 'Both .env.apex and .env.apex.pending must exist before promotion.'
    }
    if (Test-Path $previousPath) {
        throw '.env.apex.previous already exists; refusing to overwrite the backup.'
    }

    foreach ($ignoredPath in @('.env.apex', '.env.apex.pending', '.env.apex.previous')) {
        & git -C $repositoryRoot check-ignore --quiet $ignoredPath
        if ($LASTEXITCODE -ne 0) {
            throw "Git does not ignore $ignoredPath; refusing to promote credentials."
        }
    }

    $verifyInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $verifyInfo.FileName = $sqlPlus
    $verifyInfo.Arguments = '-L /nolog'
    $verifyInfo.UseShellExecute = $false
    $verifyInfo.CreateNoWindow = $true
    $verifyInfo.RedirectStandardInput = $true
    $verifyInfo.RedirectStandardOutput = $true
    $verifyInfo.RedirectStandardError = $true
    $verifyProcess = [System.Diagnostics.Process]::new()
    $verifyProcess.StartInfo = $verifyInfo
    if (-not $verifyProcess.Start()) {
        throw 'SQL*Plus could not verify workspace state; pending credentials were left untouched.'
    }
    $verifyOutTask = $verifyProcess.StandardOutput.ReadToEndAsync()
    $verifyErrTask = $verifyProcess.StandardError.ReadToEndAsync()
    @(
        'set echo off'
        'set feedback off'
        'set heading off'
        'set linesize 200'
        'whenever oserror exit failure'
        'whenever sqlerror exit sql.sqlcode'
        'connect / as sysdba'
        'alter session set container=QAFE_CLEAN;'
        "select 'WORKSPACE_ID='||apex_util.find_security_group_id(p_workspace=>'QAFE_FORMS_CLEAN') from dual;"
        "select 'SCHEMAS='||apex_instance_admin.get_schemas(p_workspace=>'QAFE_FORMS_CLEAN') from dual;"
        "select 'BUILDER_COUNT='||count(*) from apex_240200.wwv_flow_fnd_user where user_name='QAFE_FORMS_BUILDER' and security_group_id=apex_util.find_security_group_id(p_workspace=>'QAFE_FORMS_CLEAN');"
        'exit success'
    ) | ForEach-Object { $verifyProcess.StandardInput.WriteLine($_) }
    $verifyProcess.StandardInput.Close()
    if (-not $verifyProcess.WaitForExit(60000)) {
        $verifyProcess.Kill()
        throw 'SQL*Plus verification timed out; pending credentials were left untouched.'
    }
    $verifyOutput = $verifyOutTask.GetAwaiter().GetResult()
    $verifyError = $verifyErrTask.GetAwaiter().GetResult()
    $workspaceIdMatch = [regex]::Match($verifyOutput, 'WORKSPACE_ID=(\d+)')
    $schemaMatch = [regex]::Match($verifyOutput, 'SCHEMAS=([^\r\n]+)')
    $builderMatch = [regex]::Match($verifyOutput, 'BUILDER_COUNT=(\d+)')
    $schemaList = if ($schemaMatch.Success) { $schemaMatch.Groups[1].Value.Trim() } else { '' }
    $builderCount = if ($builderMatch.Success) { [int]$builderMatch.Groups[1].Value } else { 0 }
    if ($verifyProcess.ExitCode -ne 0 -or -not $workspaceIdMatch.Success -or
        -not $schemaList.Split(',') -contains 'STUDENT' -or $builderCount -ne 1) {
        throw 'Workspace state did not pass verification; pending credentials were left untouched.'
    }

    [System.IO.File]::Replace($pendingPath, $credentialPath, $previousPath)
    Remove-Item -LiteralPath $previousPath -Force
    Write-Output 'Verified QAFE_FORMS_CLEAN, STUDENT mapping, and QAFE_FORMS_BUILDER. Credentials were promoted to ignored .env.apex without displaying the password.'
    return
}

if (-not (Test-Path $credentialPath)) {
    throw '.env.apex is missing. Reset the local APEX ADMIN account first.'
}
if ((Test-Path $pendingPath) -and -not $ReplacePending) {
    throw '.env.apex.pending already exists. Review or remove it before creating workspace credentials.'
}
if (Test-Path $pendingPath) {
    Remove-Item -LiteralPath $pendingPath -Force
}
if (Test-Path $previousPath) {
    throw '.env.apex.previous already exists. Review that backup before continuing.'
}
foreach ($ignoredPath in @('.env.apex', '.env.apex.pending', '.env.apex.previous')) {
    & git -C $repositoryRoot check-ignore --quiet $ignoredPath
    if ($LASTEXITCODE -ne 0) {
        throw "Git does not ignore $ignoredPath; refusing to write workspace credentials."
    }
}

$existingLines = [System.IO.File]::ReadAllLines($credentialPath) |
    Where-Object { $_ -notmatch '^APEX_DEMO_WORKSPACE(_USERNAME|_EMAIL|_PASSWORD)?=' }

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
    for ($index = $passwordCharacters.Count; $index -lt 36; $index++) {
        $passwordCharacters.Add($alphabet[(Get-SecureIndex -Maximum $alphabet.Length)])
    }
    for ($index = $passwordCharacters.Count - 1; $index -gt 0; $index--) {
        $swapIndex = Get-SecureIndex -Maximum ($index + 1)
        $temporary = $passwordCharacters[$index]
        $passwordCharacters[$index] = $passwordCharacters[$swapIndex]
        $passwordCharacters[$swapIndex] = $temporary
    }
    $password = -join $passwordCharacters

    $credentialLines = @($existingLines) + @(
        "APEX_DEMO_WORKSPACE=$workspaceName"
        "APEX_DEMO_USERNAME=$workspaceUsername"
        "APEX_DEMO_EMAIL=$workspaceEmail"
        "APEX_DEMO_PASSWORD=$password"
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
        throw 'Could not restrict pending credential-file permissions; no database changes were attempted.'
    }

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $sqlPlus
    $startInfo.Arguments = '-L /nolog'
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        Remove-Item -LiteralPath $pendingPath -Force
        throw 'SQL*Plus could not be started; the pending file was removed.'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $plsql = @"
declare
    l_workspace_id number;
    l_user_count number;
    l_schemas varchar2(4000);
begin
    l_workspace_id := apex_util.find_security_group_id(p_workspace => '$workspaceName');
    if l_workspace_id = 0 then
        apex_instance_admin.add_workspace(
            p_workspace          => '$workspaceName',
            p_source_identifier  => 'QAFEDEMO',
            p_primary_schema     => '$defaultSchema',
            p_additional_schemas => null,
            p_host_prefix        => '127.0.0.1');

        l_workspace_id := apex_util.find_security_group_id(p_workspace => '$workspaceName');
        if l_workspace_id = 0 then
            raise_application_error(-20002, 'Workspace creation did not return an APEX workspace ID.');
        end if;
    end if;

    l_schemas := apex_instance_admin.get_schemas(p_workspace => '$workspaceName');
    if instr(':' || replace(upper(l_schemas), ',', ':') || ':', ':${defaultSchema}:') = 0 then
        apex_instance_admin.add_schema(
            p_workspace             => '$workspaceName',
            p_schema                => '$defaultSchema',
            p_grant_apex_privileges => true);
    end if;

    select count(*) into l_user_count
      from apex_240200.wwv_flow_fnd_user
     where security_group_id = l_workspace_id
       and user_name = '$workspaceUsername';
    if l_user_count > 0 then
        raise_application_error(-20003, 'Workspace builder account already exists; refusing duplicate provisioning.');
    end if;

    apex_util.set_security_group_id(l_workspace_id);
    apex_util.create_user(
        p_user_name                    => '$workspaceUsername',
        p_first_name                   => 'QAFE',
        p_last_name                    => 'Demo Builder',
        p_description                  => '$workspaceDescription',
        p_email_address                => '$workspaceEmail',
        p_web_password                 => '$password',
        p_web_password_format          => 'CLEAR_TEXT',
        p_developer_privs              => 'CREATE:EDIT',
        p_default_schema               => '$defaultSchema',
        p_allow_access_to_schemas      => '$defaultSchema',
        p_account_locked               => 'N',
        p_change_password_on_first_use => 'N',
        p_allow_app_building_yn        => 'Y',
        p_allow_sql_workshop_yn        => 'N',
        p_allow_websheet_dev_yn        => 'N',
        p_allow_team_development_yn    => 'N');
    commit;
    dbms_output.put_line('QAFE_DEMO_WORKSPACE_CREATED');
end;
/
"@
    $sqlInput = @(
        'set echo off'
        'set verify off'
        'set define off'
        'set serveroutput on'
        'whenever oserror exit failure'
        'whenever sqlerror exit sql.sqlcode'
        'connect / as sysdba'
        'alter session set container=QAFE_CLEAN;'
        $plsql
        'exit'
    )
    foreach ($line in $sqlInput) {
        $process.StandardInput.WriteLine($line)
    }
    $process.StandardInput.Close()

    if (-not $process.WaitForExit(120000)) {
        $process.Kill()
        throw 'Workspace provisioning timed out. The pending credential file was retained; inspect APEX before retrying.'
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $safeOutput = "$stdout`n$stderr".Replace($password, '[REDACTED]')
    if ($process.ExitCode -ne 0) {
        $errorCodes = [regex]::Matches($safeOutput, '\b(?:ORA|SP2)-\d{4,5}\b') |
            ForEach-Object { $_.Value } |
            Select-Object -Unique
        $safeErrorSummary = if ($errorCodes) { $errorCodes -join ', ' } else { 'Workspace creation was not confirmed by SQL*Plus' }
        $safeLines = ($safeOutput -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 12) -join ' | '
        throw "Workspace provisioning failed (exit $($process.ExitCode); $safeErrorSummary). Sanitized context: $safeLines. Credentials remain in the ignored pending file; inspect workspace state before retrying."
    }

    [System.IO.File]::Replace($pendingPath, $credentialPath, $previousPath)
    Remove-Item -LiteralPath $previousPath -Force
    Write-Output 'QAFE_FORMS_CLEAN and QAFE_FORMS_BUILDER were created. Workspace password is in Git-ignored .env.apex and was not displayed.'
}
finally {
    $random.Dispose()
    $password = $null
    $passwordCharacters = $null
    $credentialLines = $null
    $existingLines = $null
    $plsql = $null
    $sqlInput = $null
    $stdout = $null
    $stderr = $null
    $safeOutput = $null
}
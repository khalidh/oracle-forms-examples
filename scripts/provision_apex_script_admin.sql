set define on
accept apex_password char prompt "Enter generated APEX script-test password: " hide

declare
    l_security_group_id number;
    l_existing_user_count pls_integer;
begin
    l_security_group_id := apex_util.find_security_group_id(
        p_workspace => 'QAFE_FORMS_DEMO'
    );
    if l_security_group_id is null then
        raise_application_error(-20001, 'QAFE_FORMS_DEMO workspace was not found.');
    end if;

    select count(*)
      into l_existing_user_count
      from apex_workspace_apex_users
     where workspace_id = l_security_group_id
       and upper(user_name) = 'QAFE_DEMO_SCRIPT_ADMIN';
    if l_existing_user_count > 0 then
        raise_application_error(-20002, 'Diagnostic APEX user already exists; refusing to overwrite it.');
    end if;

    if instr(':' || apex_instance_admin.get_schemas('QAFE_FORMS_DEMO') || ':', ':STUDENT:') = 0 then
        raise_application_error(-20003, 'STUDENT is not mapped to QAFE_FORMS_DEMO.');
    end if;

    apex_util.set_security_group_id(p_security_group_id => l_security_group_id);
    apex_util.create_user(
        p_user_name                     => 'QAFE_DEMO_SCRIPT_ADMIN',
        p_first_name                    => 'QAFE',
        p_last_name                     => 'Script Diagnostic',
        p_description                   => 'Temporary local diagnostic account using sibling provisioning pattern.',
        p_email_address                 => 'qafe-demo-script-admin@localhost.invalid',
        p_web_password                  => '&apex_password',
        p_web_password_format           => 'CLEAR_TEXT',
        p_developer_privs               => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_default_schema                => 'STUDENT',
        p_allow_access_to_schemas       => 'STUDENT',
        p_account_locked                => 'N',
        p_failed_access_attempts        => 0,
        p_change_password_on_first_use  => 'N',
        p_first_password_use_occurred   => 'N',
        p_allow_app_building_yn         => 'Y',
        p_allow_sql_workshop_yn         => 'Y',
        p_allow_websheet_dev_yn         => 'N',
        p_allow_team_development_yn     => 'Y'
    );
    commit;
end;
/

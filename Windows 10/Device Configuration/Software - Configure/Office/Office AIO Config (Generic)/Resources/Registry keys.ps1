<#
    .RESOURCES
        Office 365 / 2016
            Disable first use with registry
            https://www.autoitconsulting.com/site/deployment/automating-office-365-click-run-first-use-without-group-policy/
            
            Disable first run wizard with GPO
            https://osddeployment.dk/2016/04/26/automating-office-365-click-to-run-first-use-with-group-policy/
            
            Office 2016 Administrative Template files (ADMX/ADML) and Office Customization Tool
            https://www.microsoft.com/en-us/download/details.aspx?id=49030

        Office 365 / 2013
            How to disable office first run wizard
            https://serverfault.com/questions/698846/how-to-disable-microsoft-offices-first-run-wizard
#>




# HKCU | HKEY_CURRENT_USER
    # Common
    $HKCU_QMEnable           = @('HKCU:\Software\Microsoft\Office\16.0\Common',         'QMEnable',          'DWord',1)
    # Common \ General
    $HKCU_ShownFileFmtPrompt = @('HKCU:\Software\Microsoft\Office\16.0\Common\General', 'ShownFileFmtPrompt','DWord',1)
    $HKCU_ShownFirstRunOptin = @('HKCU:\Software\Microsoft\Office\16.0\Common\General', 'ShownFirstRunOptin','DWord',1)
    # Common \ PTWatson
    $HKCU_PTWOptIn           = @('HKCU:\Software\Microsoft\Office\16.0\Common\PTWatson','PTWOptIn',          'DWord',1)
    # FirstRun
    $HKCU_BootedRTM          = @('HKCU:\Software\Microsoft\Office\16.0\FirstRun',       'BootedRTM',         'DWord',1)
    $HKCU_DisableMovie       = @('HKCU:\Software\Microsoft\Office\16.0\FirstRun',       'DisableMovie',      'DWord',1)
    # Registration
    $HKCU_AcceptAllEulas     = @('HKCU:\Software\Microsoft\Office\16.0\Registration',   'AcceptAllEulas',    'DWord',1)


# HKLM | HKEY_LOCAL_MACHINE
    # Common \ General
    $HKLM_ShownFileFmtPrompt = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\General','ShownFileFmtPrompt','DWord',1)
    $HKLM_ShownFirstRunOptin = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\General','ShownFirstRunOptin','DWord',1)
    # Registration
    $HKLM_AcceptAllEulas     = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Registration',  'AcceptAllEulas',    'DWord',1)


# HKLM - Apply to HKCU on Office firstrun
$64bitOS32bitOffice13 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\User Settings\MyCustomSettings'
$64bitOS64bitOffice13 = 'HKLM:\SOFTWARE\Microsoft\Office\16.0\User Settings\MyCustomSettings'


# Apply to firstrun
$HKLM_Apply_QMEnable = @(('{0}\Create\Software\Microsoft\Office\16.0\Common' -f ($64bitOS32bitOffice13)),'QMEnable','DWord',1)
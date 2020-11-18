<#
    .SYNOPSIS
    Tests if a registry value exists, if not, add it

    .DESCRIPTION
    Tests if a registry value exists, if not, add it
    Written with PowerShell v5.1 documentation

    .USAGE
    Export values from registry, paste it to $RegFile 

    Sources:
    - https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    - https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    - https://docs.microsoft.com/en-us/intune/intune-management-extension
    
#>


#region Variables
# Settings
[bool] $DebugWinTemp = $true
[bool] $DebugConsole = $false
[bool] $ReadOnly = $false
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Citrix Config'
[String] $ValuePath = 'HKCU:\Software\Citrix\Dazzle\Sites\backegrupp-ea578b8b\'
[String] $ValueName = 'configUrl'
[String] $Value = 'https://storefront.backe.no/Citrix/BackeGruppen/discovery'

# Registry file
[String] $RegFile = 'Windows Registry Editor Version 5.00'
[String] $RegFile += ("`r`n" + '
[HKEY_CURRENT_USER\Software\Citrix]

[HKEY_CURRENT_USER\Software\Citrix\Dazzle]
"FirstRunInstalledDate"="28.11.2017 14:05:58"
"CurrentAccount"="backegrupp-ea578b8b"

[HKEY_CURRENT_USER\Software\Citrix\Dazzle\Sites]

[HKEY_CURRENT_USER\Software\Citrix\Dazzle\Sites\backegrupp-ea578b8b]
"type"="DS"
"name"="BackeGruppen"
"configUrl"="https://storefront.backe.no/Citrix/BackeGruppen/discovery"
"ConfiguredByAdministrator"="False"
"enabledByAdmin"="True"
"description"=""
"serviceRecordId"="3509872913"
"SubStoreOf"=""
"resourcesUrl"="https://storefront.backe.no/Citrix/BackeGruppen/resources/v2"
"sessionUrl"="https://storefront.backe.no/Citrix/BackeGruppen/sessions/v1/available"
"authEndpointUrl"="https://storefront.backe.no/Citrix/Authentication/endpoints/v1"
"tokenValidationUrl"="https://storefront.backe.no/Citrix/Authentication/auth/v1/token/validate/"
"tokenServiceUrl"="https://storefront.backe.no/Citrix/Authentication/auth/v1/token"
"LastRefreshTime"="28.11.2017 14:06:32"

[HKEY_CURRENT_USER\Software\Citrix\ICA Client]

[HKEY_CURRENT_USER\Software\Citrix\ICA Client\AutoUpdate]
"LastUpgradeCheckTime"=hex(b):74,41,ca,9e,49,68,d3,01

[HKEY_CURRENT_USER\Software\Citrix\ICA Client\CEIP]

[HKEY_CURRENT_USER\Software\Citrix\ICA Client\CEIP\Data]
"Receiver_Language"="nb"
"Receiver_UILanguage"=dword:00000809
"LocalIME"=dword:00000000
"Receiver_AuthAttempts"=dword:00000002
"Receiver_AuthFailures"=dword:00000000
"X1_UI"="false"

[HKEY_CURRENT_USER\Software\Citrix\ICA Client\CEIP\Data\Auth Manager]
"AuthManager_ChangedSettingsTracingEnabled"=""
"AuthManager_ChangedSettingsLoggingMode"=""
"AuthManager_ChangedSettingsSavePasswordMode"=""
"AuthManager_ChangedSettingsConnectionSecurityMode"=""
"AuthManager_ChangedSettingsRememberUsername"=""
"AuthManager_ChangedSettingsCertificateSelectionMode"=""
"AuthManager_ChangedSettingsSmartCardPinEntry"=""
"AuthManager_ChangedSettingsSmartCardRemovalAction"=""
"AuthManager_ChangedSettingsCertificateFilteringEnabled"=""
"AuthManager_ChangedSettingsSdkTracingEnabled"=""
"AuthManager_NsgAuthAttempts"=dword:00000001
"AuthManager_SfAuthAttempts"=dword:00000000
"AuthManager_SfViaNsgAuthAttempts"=dword:00000001
"AuthManager_AuthIwa"=dword:00000000
"AuthManager_AuthIwaTotalDuration"=dword:00000000
"AuthManager_AuthCertificate"=dword:00000000
"AuthManager_AuthCertificateTotalDuration"=dword:00000000
"AuthManager_AuthExplicitForms"=dword:00000000
"AuthManager_AuthExplicitFormsTotalDuration"=dword:00000000
"AuthManager_AuthCustomForms"=dword:00000000
"AuthManager_AuthCustomFormsTotalDuration"=dword:00000000
"AuthManager_AuthCitrixAgBasic"=dword:00000001
"AuthManager_AuthCitrixAgBasicTotalDuration"=dword:0000009c
"AuthManager_AuthCitrixAgBasicNoPassword"=dword:00000000
"AuthManager_AuthCitrixAgBasicNoPasswordTotalDuration"=dword:00000000
"AuthManager_AuthHttpBasic"=dword:00000000
"AuthManager_AuthHttpBasicTotalDuration"=dword:00000000
"AuthManager_AuthAg"=dword:00000000
"AuthManager_AuthAgTotalDuration"=dword:00000000
"AuthManager_AuthAgLegacy"=dword:00000001
"AuthManager_AuthAgLegacyTotalDuration"=dword:000025c7
"AuthManager_AuthAgPlugin"=dword:00000000
"AuthManager_AuthAgPluginTotalDuration"=dword:00000000
"AuthManager_AuthAgLegacyClientCert"=dword:00000000
"AuthManager_AuthAgLegacyClientCertTotalDuration"=dword:00000000
"AuthManager_AuthSuccess"=dword:00000002
"AuthManager_AuthProtocolError"=dword:00000000
"AuthManager_AuthNetworkError"=dword:00000000
"AuthManager_AuthCertificateError"=dword:00000000
"AuthManager_AuthSystemError"=dword:00000000
"AuthManager_AuthInteractionNotAllowed"=dword:00000000
"AuthManager_AuthCancelledByUser"=dword:00000000
"AuthManager_AuthDisallowedBySecurityPolicy"=dword:00000000
"AuthManager_AuthAuthenticationServerError"=dword:00000000
"AuthManager_AuthInvalidGatewaySession"=dword:00000000
"AuthManager_AuthUnsuitableProtocol"=dword:00000000
"AuthManager_AuthGatewayNotSupported"=dword:00000000
"AuthManager_AuthBadGatewaySessionCredentials"=dword:00000000
"AuthManager_AuthAccessDenied"=dword:00000000
"AuthManager_AuthAborted"=dword:00000000
"AuthManager_AuthOutOfLicenses"=dword:00000000
"AuthManager_AuthGatewayClientSoftwareUpdated"=dword:00000000
"AuthManager_AuthUserSwitchedProtocol"=dword:00000000
"AuthManager_AuthSoftToken"=dword:00000000
"AuthManager_AuthInternal"=dword:00000000
"AuthManager_AuthExternal"=dword:00000001
"AuthManager_SsonEnabled"=dword:00000000
"AuthManager_Asserts"=dword:00000000
"AuthManager_Crashed"=dword:00000001
"AuthManager_Crashes"=dword:00000000
"AuthManager_Version"="12.0.0.1 (Release)"
"AuthManager_ScReaderName"=""
"AuthManager_ScName"=""
"AuthManager_ScDriver"=""
"AuthManager_ScCertificateDialogs"=dword:00000000
"AuthManager_ScCertificateSelected"=dword:00000000
"AuthManager_ScCertificates"=dword:00000000
"AuthManager_ScFallbacksWithScLogonAvailable"=dword:00000000
"AuthManager_ScLogonsWithFallbackAvailable"=dword:00000000
"AuthManager_DataEntryDialogsDisplayed"=dword:00000001
"AuthManager_DataEntryDialogsTotalDisplayTime"=dword:00002385
"AuthManager_SuccessfulLogonsTotalDuration"=dword:000026a3
"AuthManager_CustomWindowTitle"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\ICA Client\CEIP\Data\Installer]
"InstallMode"="UI"
"CustomPath"="No"
"InstallState"="Fresh"
"SSONState"="Disabled"
"InstallationTime"="00:00:16"
"IsVDA"="No"

[HKEY_CURRENT_USER\Software\Citrix\Plugins]

[HKEY_CURRENT_USER\Software\Citrix\Plugins\{9FAB00CA-B032-4E4E-8D0C-E3B35802335D}]

[HKEY_CURRENT_USER\Software\Citrix\Receiver]
"VPNInstalled"=dword:00000000
"VPNIsFB"=dword:00000000
"VPNConnected"=dword:00000000
"NetworkConnectivity"=dword:00000001
"ConnectivityStatusMessage"=""
"EnableFTU"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\CtxAccount]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\CtxAccount\20069db4-8b1a-4f3e-8b24-32532510aa2b]
"Name"="BackeGruppen"
"UpdaterType"="none"
"Description"=""
"ContentHash"="1700013019"
"AccountServiceUrl"="https://storefront.backe.no/Citrix/Roaming/Accounts"
"TokenServiceUrl"="https://storefront.backe.no/Citrix/Authentication/auth/v1/token"
"IsPublished"="true"
"IsPrimary"="true"
"IsEnabled"="true"
"Plugins"=""

[HKEY_CURRENT_USER\Software\Citrix\Receiver\CtxAccount\20069db4-8b1a-4f3e-8b24-32532510aa2b\3509872913]
"Type"="Store"

[HKEY_CURRENT_USER\Software\Citrix\Receiver\InstallDetect]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\InstallDetect\{562822F7-CBD4-406E-A9EA-3B8B13E14BB9}]
"DisplayName"="Citrix Receiver Inside"
"CTX_DisplayName"="Citrix Receiver Inside"
"DisplayVersion"="4.10.0.65534"
"Rules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,00,6f,\
  00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,6f,00,\
  73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,5c,\
  00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,69,00,\
  6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,00,5c,\
  00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,31,00,\
  2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,00,74,\
  00,73,00,5c,00,44,00,32,00,34,00,44,00,36,00,43,00,45,00,45,00,45,00,30,00,\
  45,00,45,00,33,00,33,00,38,00,34,00,35,00,41,00,31,00,33,00,46,00,35,00,38,\
  00,33,00,31,00,38,00,36,00,36,00,35,00,33,00,30,00,31,00,5c,00,49,00,6e,00,\
  73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,00,69,\
  00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,65,00,\
  72,00,73,00,69,00,6f,00,6e,00,00,00,00,00

[HKEY_CURRENT_USER\Software\Citrix\Receiver\InstallDetect\{826AB1F5-F73D-43E9-AC5E-14A3AE8A8E15}]
"DisplayName"="Citrix Authentication Manager"
"CTX_DisplayName"="Citrix Authentication Manager"
"DisplayVersion"="12.0.0.1"
"Rules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,00,6f,\
  00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,6f,00,\
  73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,5c,\
  00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,69,00,\
  6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,00,5c,\
  00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,31,00,\
  2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,00,74,\
  00,73,00,5c,00,33,00,30,00,42,00,34,00,42,00,32,00,34,00,30,00,34,00,33,00,\
  36,00,36,00,38,00,31,00,35,00,34,00,37,00,39,00,38,00,33,00,35,00,32,00,45,\
  00,37,00,42,00,41,00,42,00,33,00,35,00,32,00,46,00,32,00,5c,00,49,00,6e,00,\
  73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,00,69,\
  00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,65,00,\
  72,00,73,00,69,00,6f,00,6e,00,00,00,00,00

[HKEY_CURRENT_USER\Software\Citrix\Receiver\InstallDetect\{8C92B884-C818-45D0-A757-7123B78AA247}]
"DisplayName"="Online Plug-in"
"CTX_DisplayName"="Online Plug-in"
"DisplayVersion"="14.10.0.16036"
"Rules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,00,6f,\
  00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,6f,00,\
  73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,5c,\
  00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,69,00,\
  6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,00,5c,\
  00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,31,00,\
  2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,00,74,\
  00,73,00,5c,00,31,00,35,00,39,00,36,00,43,00,46,00,32,00,39,00,35,00,33,00,\
  36,00,30,00,45,00,45,00,37,00,34,00,39,00,41,00,43,00,37,00,36,00,38,00,46,\
  00,35,00,39,00,45,00,34,00,33,00,35,00,39,00,46,00,33,00,5c,00,49,00,6e,00,\
  73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,00,69,\
  00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,65,00,\
  72,00,73,00,69,00,6f,00,6e,00,00,00,00,00

[HKEY_CURRENT_USER\Software\Citrix\Receiver\InstallDetect\{A9852000-047D-11DD-95FF-0800200C9A66}]
"DisplayName"="Self-service Plug-in"
"CTX_DisplayName"="Self-service Plug-in"
"DisplayVersion"="4.10.0.16017"
"Rules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,00,6f,\
  00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,6f,00,\
  73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,5c,\
  00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,69,00,\
  6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,00,5c,\
  00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,31,00,\
  2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,00,74,\
  00,73,00,5c,00,37,00,34,00,30,00,42,00,31,00,32,00,34,00,46,00,43,00,37,00,\
  30,00,42,00,34,00,45,00,41,00,34,00,31,00,38,00,43,00,43,00,45,00,37,00,35,\
  00,31,00,30,00,39,00,43,00,33,00,38,00,32,00,33,00,44,00,5c,00,49,00,6e,00,\
  73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,00,69,\
  00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,65,00,\
  72,00,73,00,69,00,6f,00,6e,00,00,00,00,00

[HKEY_CURRENT_USER\Software\Citrix\Receiver\Inventory]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\Inventory\{562822F7-CBD4-406E-A9EA-3B8B13E14BB9}]
"Version"="4.10.0.65534"
"VersionRules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,\
  00,6f,00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,\
  6f,00,73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,\
  00,5c,00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,\
  69,00,6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,\
  00,5c,00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,\
  31,00,2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,\
  00,74,00,73,00,5c,00,44,00,32,00,34,00,44,00,36,00,43,00,45,00,45,00,45,00,\
  30,00,45,00,45,00,33,00,33,00,38,00,34,00,35,00,41,00,31,00,33,00,46,00,35,\
  00,38,00,33,00,31,00,38,00,36,00,36,00,35,00,33,00,30,00,31,00,5c,00,49,00,\
  6e,00,73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,\
  00,69,00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,\
  65,00,72,00,73,00,69,00,6f,00,6e,00,00,00,00,00
"Name"="Citrix Receiver Inside"
"Description"=""
"ShortDescription"=""
"FullPlugin"=dword:00000001
"AppReceiverComponent"=dword:00000000
"InventoryFromMetadata"=dword:00000000
"IsDazzle"=dword:00000000
"LaunchAfterCompletionDialog"=dword:00000000
"InstallOnce"=dword:00000000
"StartAfterInstall"=dword:00000000
"Visible"=dword:00000000
"StatusCode"=dword:00000024
"StatusSubCode"=dword:00000000
"StatusMessage"=""
"StatusParameter"=""
"HasMenu"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\Inventory\{826AB1F5-F73D-43E9-AC5E-14A3AE8A8E15}]
"Version"="12.0.0.1"
"VersionRules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,\
  00,6f,00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,\
  6f,00,73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,\
  00,5c,00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,\
  69,00,6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,\
  00,5c,00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,\
  31,00,2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,\
  00,74,00,73,00,5c,00,33,00,30,00,42,00,34,00,42,00,32,00,34,00,30,00,34,00,\
  33,00,36,00,36,00,38,00,31,00,35,00,34,00,37,00,39,00,38,00,33,00,35,00,32,\
  00,45,00,37,00,42,00,41,00,42,00,33,00,35,00,32,00,46,00,32,00,5c,00,49,00,\
  6e,00,73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,\
  00,69,00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,\
  65,00,72,00,73,00,69,00,6f,00,6e,00,00,00,00,00
"Name"="Citrix Authentication Manager"
"Description"=""
"ShortDescription"=""
"FullPlugin"=dword:00000001
"AppReceiverComponent"=dword:00000000
"InventoryFromMetadata"=dword:00000000
"IsDazzle"=dword:00000000
"LaunchAfterCompletionDialog"=dword:00000000
"InstallOnce"=dword:00000000
"StartAfterInstall"=dword:00000000
"Visible"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\Inventory\{8C92B884-C818-45D0-A757-7123B78AA247}]
"Version"="14.10.0.16036"
"VersionRules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,\
  00,6f,00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,\
  6f,00,73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,\
  00,5c,00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,\
  69,00,6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,\
  00,5c,00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,\
  31,00,2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,\
  00,74,00,73,00,5c,00,31,00,35,00,39,00,36,00,43,00,46,00,32,00,39,00,35,00,\
  33,00,36,00,30,00,45,00,45,00,37,00,34,00,39,00,41,00,43,00,37,00,36,00,38,\
  00,46,00,35,00,39,00,45,00,34,00,33,00,35,00,39,00,46,00,33,00,5c,00,49,00,\
  6e,00,73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,\
  00,69,00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,\
  65,00,72,00,73,00,69,00,6f,00,6e,00,00,00,00,00
"Name"="Online Plug-in"
"Description"=""
"ShortDescription"=""
"FullPlugin"=dword:00000001
"AppReceiverComponent"=dword:00000000
"InventoryFromMetadata"=dword:00000000
"IsDazzle"=dword:00000000
"LaunchAfterCompletionDialog"=dword:00000000
"InstallOnce"=dword:00000000
"StartAfterInstall"=dword:00000000
"Visible"=dword:00000001
"FriendlyName"="Online Sessions"
"StatusCode"=dword:00000020
"StatusSubCode"=dword:00000001
"StatusMessage"=""
"StatusParameter"=""

[HKEY_CURRENT_USER\Software\Citrix\Receiver\Inventory\{A9852000-047D-11DD-95FF-0800200C9A66}]
"Version"="4.10.0.16017"
"VersionRules"=hex(7):72,00,65,00,67,00,3a,00,48,00,4b,00,4c,00,4d,00,5c,00,53,\
  00,6f,00,66,00,74,00,77,00,61,00,72,00,65,00,5c,00,4d,00,69,00,63,00,72,00,\
  6f,00,73,00,6f,00,66,00,74,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,\
  00,5c,00,43,00,75,00,72,00,72,00,65,00,6e,00,74,00,56,00,65,00,72,00,73,00,\
  69,00,6f,00,6e,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,65,00,72,\
  00,5c,00,55,00,73,00,65,00,72,00,44,00,61,00,74,00,61,00,5c,00,53,00,2d,00,\
  31,00,2d,00,35,00,2d,00,31,00,38,00,5c,00,50,00,72,00,6f,00,64,00,75,00,63,\
  00,74,00,73,00,5c,00,37,00,34,00,30,00,42,00,31,00,32,00,34,00,46,00,43,00,\
  37,00,30,00,42,00,34,00,45,00,41,00,34,00,31,00,38,00,43,00,43,00,45,00,37,\
  00,35,00,31,00,30,00,39,00,43,00,33,00,38,00,32,00,33,00,44,00,5c,00,49,00,\
  6e,00,73,00,74,00,61,00,6c,00,6c,00,50,00,72,00,6f,00,70,00,65,00,72,00,74,\
  00,69,00,65,00,73,00,5c,00,44,00,69,00,73,00,70,00,6c,00,61,00,79,00,56,00,\
  65,00,72,00,73,00,69,00,6f,00,6e,00,00,00,00,00
"Name"="Self-service Plug-in"
"Description"=""
"ShortDescription"=""
"FullPlugin"=dword:00000001
"AppReceiverComponent"=dword:00000000
"InventoryFromMetadata"=dword:00000000
"IsDazzle"=dword:00000000
"LaunchAfterCompletionDialog"=dword:00000000
"InstallOnce"=dword:00000000
"StartAfterInstall"=dword:00000000
"Visible"=dword:00000000
"StatusCode"=dword:00000020
"StatusSubCode"=dword:00000000
"StatusMessage"=""
"StatusParameter"=""

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913]
"Name"="BackeGruppen"
"Addr"="https://storefront.backe.no/Citrix/BackeGruppen/discovery"
"SRType"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Beacons]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Beacons\External]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Beacons\External\Addr0]
"Address"="https://citrix.backe.no"
"DSconfirmed"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Beacons\External\Addr1]
"Address"="http://www.citrix.com"
"DSconfirmed"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Beacons\Internal]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Beacons\Internal\Addr0]
"Address"="https://storefront.backe.no/"
"DSconfirmed"=dword:00000000

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Gateways]

[HKEY_CURRENT_USER\Software\Citrix\Receiver\SR\Store\3509872913\Gateways\99x Netscaler]
"LogonPoint"="https://citrix.backe.no"
"Edition"=dword:00000002
"Auth"=dword:00000002
"AGMode"=dword:00000000
"TrustedByUser"=dword:00000000
"TrustedByDS"=dword:00000000
"IsDefault"=dword:00000001

[HKEY_CURRENT_USER\Software\Citrix\Receiver\Transient]
')
#endregion Variables



#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In
        )
        If ($DebugConsole) {
            Write-Output -InputObject $In
        }
        If ($DebugWinTemp) {
            $Global:DebugStr += ($In + "`r`n")
        }
    }
    #endregion Write-DebugIfOn


    #region Test-RegistryString
    Function Test-RegistryString {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Key,

            [Parameter(Mandatory=$true, Position=0)]
            [String] $Val
        )
        
        [bool] $IsThere = $false
        [String] $OutputStr = [String]::Empty

        $Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Key) -ErrorAction SilentlyContinue
        If (($Exists -ne $null) -and ($Exists.Length -ne 0)) {
            If ($Exists.$Key -like $Val) {
                $OutputStr = ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, and is equal to new value.' + "`r`n" + '(' + $Exists.$ValueName + ' == ' + $Value + ')')       
                $IsThere = $true
            }
            Else { 
                $OutputStr = ($WhatToConfig + ' present in registry: ' + $ValueName + ' exists, but is not equal to new value.' + "`r`n" + '(' + $Exists.$Valuename + ' != ' + $Value + ')')
            }
        }
        Else {
            $OutputStr = ($WhatToConfig + ' not present in registry.')
        }

        Return @($IsThere,$OutputStr)
    }
    #endregion Test-RegistryString
#endregion Functions



#region Initialize
If ($DebugWinTemp -or $DebugConsole) {
    [String] $ComputerName = $env:COMPUTERNAME
    [String] $WindowsEdition = (Get-WmiObject -Class win32_operatingsystem).Caption
    [String] $WindowsVersion = (Get-WmiObject -Class win32_operatingsystem).Version
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = ' + $DebugConsole + ' | DebugWinTemp = ' + $DebugWinTemp + ' ' + ' | ReadOnly = ' + $ReadOnly)
    Write-DebugIfOn -In ('Host runs: ' + $WindowsEdition + ' v' + $WindowsVersion)
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)

    # Check if value exists
    $Exists = Test-RegistryString -Dir $ValuePath -Key $ValueName -Val $Value
    Write-DebugIfOn -In $Exists[1]

    # Write to registry if Test-RegistryKey returns false
    If (!($Exists[0])) {
        [String] $global:TempRegFile = ('C:\Windows\Temp\' + $WhatToConfig + '.reg')
        Out-File -FilePath $TempRegFile -InputObject $RegFile
        If (!($?)) {
             Write-DebugIfOn -In ('- Could not place temp reg file at ' + $TempRegFile + '. ')
             $global:TempRegFile = ($env:TEMP + '\' + $WhatToConfig + '.reg')
             Write-DebugIfOn -In ('Trying ' + $TempRegFile)
             Out-File -FilePath $TempRegFile -InputObject $RegFile
             If (!($)) {
                Write-DebugIfOn -In ('- Success writing to ' + $TempRegFile + '.')
             } Else {
                Write-DebugIfOn -In ('- Could not place temp reg file to ' + $TempRegFile)
             }        
        }
    
        If (!($ReadOnly)) {
            Write-DebugIfOn -In ('   $ReadOnly is false, attempting to write new value')
            $RegStatus = reg.exe import ('{0}' -f $Global:TempRegFile) 2>&1
    
            If (!($RegStatus -Like '*completed successfully*' -or $RegStatus -Like '*operasjonen er utf*rt*')) {
                Write-DebugIfOn -In ('Error reg.exe' + "`r`n")  
                Write-DebugIfOn -In ('Reg.exe output:' + "`r`n" + $RegStatus + "`r`n" + ($Error | Select * ) + "`r`n")    
            }
    
            Else {
                If ((Test-RegistryString -Dir $ValuePath -Key $ValueName -Val $Value)[0]) {
                    Write-DebugIfOn -In ('      Success, ' + $WhatToConfig + ' was written to registry')
                }
                Else {
                    Write-DebugIfOn -In ('      Error, ' + $WhatToConfig + ' was not written to registry.')
                }
            }
        }
        Else {
            Write-DebugIfOn -In ('   $ReadOnly, wont attempt to write new registry value')
        }
    }
#endregion Main



#region Debug
If ($DebugWinTemp) {
    If ([String]::IsNullOrEmpty($DebugStr)) {
        $DebugStr = 'Everything failed'
    }

    # Write Output
    $DebugPath = 'C:\Windows\Temp\'
    $CurDate = Get-Date -Uformat "%y%m%d"
    $CurTime = Get-Date -Format "HHmmss"
    $DebugFileName = ('Debug Powershell ' + $WhatToConfig + ' ' + $CurDate + $CurTime + '.txt')

    $DebugStr | Out-File -FilePath ($DebugPath + $DebugFileName) -Encoding 'utf8'
    If (!($?)) {
        $DebugStr | Out-File -FilePath ($env:TEMP + '\' + $DebugFileName) -Encoding 'utf8'
    }
}
#endregion Debug
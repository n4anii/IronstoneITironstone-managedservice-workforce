@ECHO OFF
:: Version 1.5.0.0
SETLOCAL ENABLEDELAYEDEXPANSION
IF "%USERNAME%"=="WDAGUtilityAccount" (
	SET _SANDBOX=Yes
) ELSE (
	SET _SANDBOX=No
)

SET "RequiredFiles=Toolkit\Deploy-Application.exe PsExec64.exe Toolkit\Invoke-ServiceUI.ps1"
SET "MissingFiles="
FOR %%F IN (%RequiredFiles%) DO (
    IF NOT EXIST "%~dp0%%F" (
        SET "MissingFiles=!MissingFiles!%%F "
    )
)
IF NOT "!MissingFiles!"=="" (
    ECHO Unable to find the following required files:
    FOR %%F IN (!MissingFiles!) DO (
        ECHO %~dp0%%F
    )
    PAUSE
    EXIT /B
)

:MENU
CLS
ECHO.
ECHO  1. Install Interactive
ECHO  2. Install Interactive (With PsExec as NT AUTHORITY\SYSTEM)
ECHO  3. Install Force Interactive (With ServiceUI)
ECHO  4. Install Silent
ECHO  5. Install Silent (With PsExec as NT AUTHORITY\SYSTEM)
ECHO  6. Install Silent Winget (With PsExec as NT AUTHORITY\SYSTEM)
ECHO  7. Repair Interactive
ECHO  8. Repair Interactive (With PsExec as NT AUTHORITY\SYSTEM)
ECHO  9. Repair Force Interactive (With ServiceUI)
ECHO 10. Repair Silent
ECHO 11. Repair Silent (With PsExec as NT AUTHORITY\SYSTEM)
ECHO 12. Uninstall Interactive
ECHO 13. Uninstall Interactive (With PsExec as NT AUTHORITY\SYSTEM)
ECHO 14. Uninstall Force Interactive (With ServiceUI)
ECHO 15. Uninstall Silent
ECHO 16. Uninstall Silent (With PsExec as NT AUTHORITY\SYSTEM)
ECHO 17. Uninstall Silent Winget (With PsExec as NT AUTHORITY\SYSTEM)
ECHO 18. Launch CMD (With PsExec as NT AUTHORITY\SYSTEM)
ECHO 19. Exit
ECHO.

SET /P CHOICE=Enter your choice: 
IF "%CHOICE%"=="0" GOTO :EOF
IF "%CHOICE%"=="1" CALL :Install_interactive
IF "%CHOICE%"=="2" CALL :Install_interactive_psexec
IF "%CHOICE%"=="3" CALL :Install_force_interactive_ServiceUI
IF "%CHOICE%"=="4" CALL :Install_silent
IF "%CHOICE%"=="5" CALL :Install_silent_psexec
IF "%CHOICE%"=="6" CALL :Install_silent_winget_psexec
IF "%CHOICE%"=="7" CALL :Repair_interactive
IF "%CHOICE%"=="8" CALL :Repair_interactive_psexec
IF "%CHOICE%"=="9" CALL :Repair_force_interactive_ServiceUI
IF "%CHOICE%"=="10" CALL :Repair_silent
IF "%CHOICE%"=="11" CALL :Repair_silent_psexec
IF "%CHOICE%"=="12" CALL :Uninstall_interactive
IF "%CHOICE%"=="13" CALL :Uninstall_interactive_psexec
IF "%CHOICE%"=="14" CALL :Uninstall_force_interactive_ServiceUI
IF "%CHOICE%"=="15" CALL :Uninstall_silent
IF "%CHOICE%"=="16" CALL :Uninstall_silent_psexec
IF "%CHOICE%"=="17" CALL :Uninstall_silent_winget_psexec
IF "%CHOICE%"=="18" CALL :Launch_CMD_psexec
IF "%CHOICE%"=="19" GOTO :EOF 
GOTO :MENU

:Install_interactive
ECHO install_interactive
"%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Interactive -AllowRebootPassThru
TIMEOUT 10 >NUL
GOTO :MENU

:Install_interactive_psexec
ECHO install_interactive_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox it does not support Interactive without ServiceUI
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Interactive -AllowRebootPassThru
) ELSE (
"%~dp0PsExec64.exe" /accepteula /s /i "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Interactive -AllowRebootPassThru
)
TIMEOUT 10 >NUL
GOTO :MENU

:Install_silent
ECHO install_silent
"%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Silent -AllowRebootPassThru
TIMEOUT 10 >NUL
GOTO :MENU

:Install_silent_psexec
ECHO install_silent_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Silent -AllowRebootPassThru
) ELSE (
"%~dp0PsExec64.exe" /accepteula /s /i "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Silent -AllowRebootPassThru
)
TIMEOUT 10 >NUL
GOTO :MENU

:Install_silent_winget_psexec
CLS
SET /P WingetFriendlyName=Enter Winget Friendly Name (Cannot contain spaces):
SET /P WingetID=Enter Winget ID: 
ECHO install_silent_winget_psexec
IF "%_SANDBOX%"=="Yes" (
    ECHO Machine is detected as Sandbox
    ECHO Friendly warning: Winget is not supported in Sandbox. So this will fail!
    "%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Silent -AllowRebootPassThru -WingetFriendlyName %WingetFriendlyName% -WingetID %WingetID%
) ELSE (
    "%~dp0PsExec64.exe" /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Install -DeployMode Silent -AllowRebootPassThru -WingetFriendlyName %WingetFriendlyName% -WingetID %WingetID%
)
TIMEOUT 10 >NUL
GOTO :MENU

:Install_force_interactive_ServiceUI
ECHO Install Force Interactive ServiceUI
"%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Toolkit\Invoke-ServiceUI.ps1" -ProcessName explorer -DeploymentType Install
TIMEOUT 10 >NUL
GOTO :MENU

:Repair_interactive
ECHO repair_interactive
"%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Repair -DeployMode Interactive -AllowRebootPassThru
TIMEOUT 10 >NUL
GOTO :MENU

:Repair_interactive_psexec
ECHO repair_interactive_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox it does not support Interactive without ServiceUI
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Repair -DeployMode Interactive -AllowRebootPassThru
) ELSE (
"%~dp0PsExec64.exe" /accepteula /s /i "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Repair -DeployMode Interactive -AllowRebootPassThru
)
TIMEOUT 10 >NUL
GOTO :MENU

:Repair_silent
ECHO repair_silent
"%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Repair -DeployMode Silent -AllowRebootPassThru
TIMEOUT 10 >NUL
GOTO :MENU

:Repair_silent_psexec
ECHO repair_silent_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Repair -DeployMode Silent -AllowRebootPassThru
) ELSE (
"%~dp0PsExec64.exe" /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Repair -DeployMode Silent -AllowRebootPassThru
)

TIMEOUT 10 >NUL
GOTO :MENU

:Repair_force_interactive_ServiceUI
ECHO Repair Force Interactive ServiceUI
"%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Toolkit\Invoke-ServiceUI.ps1" -ProcessName explorer -DeploymentType Repair
TIMEOUT 10 >NUL
GOTO :MENU

:Uninstall_interactive
ECHO uninstall_interactive
"%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Interactive -AllowRebootPassThru
TIMEOUT 10 >NUL
GOTO :MENU

:Uninstall_interactive_psexec
ECHO uninstall_interactive_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox it does not support Interactive without ServiceUI
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Interactive -AllowRebootPassThru
) ELSE (
"%~dp0PsExec64.exe" /accepteula /s /i "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Interactive -AllowRebootPassThru
)
TIMEOUT 10 >NUL
GOTO :MENU

:Uninstall_silent
ECHO uninstall_silent
"%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Silent -AllowRebootPassThru
TIMEOUT 10 >NUL
GOTO :MENU

:Uninstall_silent_psexec
ECHO uninstall_silent_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Silent -AllowRebootPassThru
) ELSE (
"%~dp0PsExec64.exe" /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Silent -AllowRebootPassThru
)
TIMEOUT 10 >NUL
GOTO :MENU

:Uninstall_silent_winget_psexec
CLS
SET /P WingetFriendlyName=Enter Winget Friendly Name (Cannot contain spaces) : 
SET /P WingetID=Enter Winget ID: 
ECHO uninstall_silent_winget_psexec
IF "%_SANDBOX%"=="Yes" (
    ECHO Machine is detected as Sandbox
    ECHO Friendly warning: Winget is not supported in Sandbox. So this will fail!
    "%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Silent -AllowRebootPassThru -WingetFriendlyName %WingetFriendlyName% -WingetID %WingetID%
) ELSE (
    "%~dp0PsExec64.exe" /accepteula /s "%~dp0Toolkit\Deploy-Application.exe" -DeploymentType Uninstall -DeployMode Silent -AllowRebootPassThru -WingetFriendlyName %WingetFriendlyName% -WingetID %WingetID%
)
TIMEOUT 10 >NUL
GOTO :MENU

:Uninstall_force_interactive_ServiceUI
ECHO Uninstall Force Interactive ServiceUI
"%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Toolkit\Invoke-ServiceUI.ps1" -ProcessName explorer -DeploymentType Uninstall
TIMEOUT 10 >NUL
GOTO :MENU

:Launch_CMD_psexec
ECHO Launch_CMD_psexec
IF "%_SANDBOX%"=="Yes" (
ECHO Machine is detected as Sandbox
"%~dp0PsExec64.exe" \\localhost /accepteula /s "%~dp0Toolkit\ServiceUI_x64.exe" -process:explorer.exe cmd.exe /k whoami
) ELSE (
"%~dp0PsExec64.exe" /accepteula /SID cmd.exe /k whoami
)
TIMEOUT 10 >NUL
GOTO :MENU

EXIT
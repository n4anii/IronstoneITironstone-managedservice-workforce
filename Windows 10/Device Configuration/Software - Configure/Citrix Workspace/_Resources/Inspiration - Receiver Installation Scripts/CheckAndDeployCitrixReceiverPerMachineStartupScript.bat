REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM *** DATE:        May 9, 2011                              ***
REM ***                                                       ***
REM *** DESCRIPTION:                                          ***
REM ***         Check and Deploy Citrix Receiver PM           ***
REM ***         Via Active Directory Startup Script           ***
REM ***                                                       ***
REM *** INPUTS: (1) Current version of package                ***
REM ***         (2) Package Location/Deployment Directory     ***
REM ***         (3) Script Logging Directory                  ***
REM ***         (4) Package Installer Command Line Options    ***
REM ***                                                       ***
REM *** OUTPUTS:     Installs the Citrix Receiver PM          ***
REM ***              Reports an error if the package          ***
REM ***              is already installed                     ***
REM ***                                                       ***
REM ***                                                       ***
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
setlocal
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM *** INPUTS (MODIFY AS APPROPRIATE)                        ***
REM ***                                                       ***
REM ***                                                       ***
REM ***         (1) Current version of package                ***
REM ***         (2) Package Location/Deployment Directory     ***
REM ***         (3) Script Logging Directory                  ***
REM ***         (4) Package Installer Command Line Options    ***
REM ***                                                       ***
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM *** (1) CURRENT VERSION OF PACKAGE                        ***
REM ***                                                       ***
set DesiredVersion=13.0.0
REM ***                                                       ***
REM *** (2) PACKAGE LOCATION/DEPLOYMENT DIRECTORY             ***
REM ***                                                       ***
set DeployDirectory=\\10.8.168.34\test
REM ***                                                       ***
REM *** (3) SCRIPT LOGGING DIRECTORY                          ***
REM ***                                                       ***
set logshare=\\10.8.168.34\test\
REM ***                                                       ***
REM *** (4) PACKAGE INSTALLER COMMAND LINE OPTIONS            ***
REM ***                                                       ***
set CommandLineOptions=/silent SERVER_LOCATION="BVVNinstsrvr22.ftltest.eng.citrite.net" ENABLE_SSON="Yes"
REM ***                                                       ***
REM ***                                                       ***
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM ***                                                       ***
REM *** BEGIN SCRIPT PROCESSING                               ***
REM ***                                                       ***
REM ***                                                       ***
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************

echo %date% %time% the %0 script is running >> %logshare%%ComputerName%.log

set CustomConfig=None
REM Check if the admin has placed a Custom appsrv.ini in Default User
IF EXIST "%SYSTEMDRIVE%\Documents and Settings\Default User\Application Data\ICAClient" set CustomConfig=exists_XP-2003
IF EXIST "%SYSTEMDRIVE%\Users\Default\AppData\Roaming\ICAClient" set CustomConfig=exists_Vista-WS08-Win7
REM
echo %date% %time% the %0 script result for CustomConfig is %CustomConfig% >> %logshare%%ComputerName%.log

REM Check if the machine is 64bit
REM
IF NOT "%ProgramFiles(x86)%"=="" SET WOW6432NODE=WOW6432NODE\


REM This script is not verifying the machine has a supported legacy client (10.200 or higher), or no client
REM


REM Check if the Desired plug-in is installed
REM
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\%WOW6432NODE%Citrix\PluginPackages\XenAppSuite\ICA_Client" | findstr %DesiredVersion%
if %errorlevel%==1 (goto NotFound) else (goto Found)
REM
REM If 1 was returned, the registry query found the Desired Version is not installed.

REM *************************************************************
REM Deployment begins here
REM *************************************************************

:NotFound
REM

echo %date% %time% Package not detected, Begin Deployment >> %logshare%%ComputerName%.log

start /wait %DeployDirectory%\CitrixReceiver.exe DONOTSTARTCC=1 /silent
REM
echo %date% %time% Deployment ended with error code %errorlevel%. >> %logshare%%ComputerName%.log

echo %date% %time%             : >> %logshare%%ComputerName%.log
echo %date% %time% Install Logs: >> %logshare%%ComputerName%.log
echo %date% %time%             : >> %logshare%%ComputerName%.log

type %temp%\TrolleyExpress*.log >> %logshare%%ComputerName%.log


if %CustomConfig%==exists goto End


REM Cleaning up if Custom Config was not present
IF EXIST "%SYSTEMDRIVE%\Documents and Settings\Default User\Application Data\ICAClient" (
    ECHO %date% %time% about to delete in XP-2003: >> %logshare%%ComputerName%.log
    dir "%SYSTEMDRIVE%\Documents and Settings\Default User\Application Data\ICAClient" >> %logshare%%ComputerName%.log
    RMDIR /S /Q "%SYSTEMDRIVE%\Documents and Settings\Default User\Application Data\ICAClient"
   )

IF EXIST "%SYSTEMDRIVE%\Users\Default\AppData\Roaming\ICAClient" (
    ECHO %date% %time% about to delete in Vista-WS08-Win7: >> %logshare%%ComputerName%.log
    dir "%SYSTEMDRIVE%\Users\Default\AppData\Roaming\ICAClient" >> %logshare%%ComputerName%.log
    RMDIR /S /Q "%SYSTEMDRIVE%\Users\Default\AppData\Roaming\ICAClient"
   )

goto End

:Found
echo %date% %time% Package was detected, Halting >> %logshare%%ComputerName%.log
goto End


:End
echo %date% %time% the %0 script has completed successfully >> %logshare%%ComputerName%.log
Endlocal

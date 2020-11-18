REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM *** DATE:        May 9, 2011                              ***
REM ***                                                       ***
REM *** DESCRIPTION:                                          ***
REM ***         Check and Deploy Citrix Receiver PU           ***
REM ***         Via Active Directory Startup Script           ***
REM ***                                                       ***
REM *** INPUTS: (1) Current version of package                ***
REM ***         (2) Package Location/Deployment Directory     ***
REM ***         (3) Script Logging Directory                  ***
REM ***         (4) Package Installer Command Line Options    ***
REM ***                                                       ***
REM *** OUTPUTS:     Installs the Citrix Receiver PU          ***
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

REM *************************************************************
REM System verification
REM *************************************************************

REM Check if the machine is 64bit
IF NOT "%ProgramFiles(x86)%"=="" SET WOW6432NODE=WOW6432NODE\

REM This script does not verify if a legacy client is already installed


REM Check if the Desired citrix Receiver is installed
REM
reg query "HKEY_CURRENT_USER\SOFTWARE\%WOW6432NODE%Citrix\PluginPackages\XenAppSuite\ICA_Client" | findstr %DesiredVersion%
if %errorlevel%==1 (goto NotFound) else (goto Found)
REM
REM If 1 was returned, the registry query found the Desired Version is not installed.


REM *************************************************************
REM Deployment begins here
REM *************************************************************

:NotFound
start /wait %DeployDirectory%\CitrixReceiver.exe /SILENT
REM
echo %date% %time% Setup ended with error code %errorlevel%. >> %logshare%%ComputerName%.log
type %temp%\TrolleyExpress*.log >> %logshare%%ComputerName%.log

goto End

:Found
echo %date% %time% Package was detected, Halting >> %logshare%%ComputerName%.log
goto End


:End
echo %date% %time% the %0 script has completed successfully >> %logshare%%ComputerName%.log
Endlocal

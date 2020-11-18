REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM *** DATE:    May 9, 2011                                  ***
REM ***                                                       ***
REM ***                                                       ***
REM *** DESCRIPTION:                                          ***
REM ***          Check and Remove Citrix Receiver PU          ***
REM ***          Via Active Directory Startup Script          ***
REM ***                                                       ***
REM *** INPUTS:                                               ***
REM ***          (1) Package Location/Deployment Directory    ***
REM ***          (2) Script Logging Directory                 ***
REM ***                                                       ***
REM *** OUTPUTS: Removes the Citrix Receiver PU               ***
REM ***          Reports an error if the package              ***
REM ***          is not installed                             ***
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
REM ***         (1) Package Location/Deployment Directory     ***
REM ***         (2) Script Logging Directory                  ***
REM ***                                                       ***
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM ***                                                       ***
REM ***         (1) PACKAGE LOCATION/DEPLOYMENT DIRECTORY     ***
REM ***                                                       ***
set DeployDirectory=\\10.8.168.34\test
REM ***                                                       ***
REM ***         (2) SCRIPT LOGGING DIRECTORY                  ***
REM ***                                                       ***
set logshare=\\10.8.168.34\test\
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
REM
IF NOT "%ProgramFiles(x86)%"=="" SET WOW6432NODE=WOW6432NODE\

REM Check if Citrix receiver is installed
REM
reg query "HKEY_CURRENT_USER\SOFTWARE\%WOW6432NODE%Citrix\ICA Client"
if %errorlevel%==1 (goto NotFound) else (goto Found)

REM If 1 returned, the product was not found.


REM *************************************************************
REM Deployment begins here
REM *************************************************************

:Found

echo %date% %time% Package detected, Begin Removal >> %logshare%%ComputerName%.log

start /wait %DeployDirectory%\CitrixReceiver.exe /SILENT /uninstall /cleanup
REM
echo %date% %time% Setup ended with error code %errorlevel%. >> %logshare%%ComputerName%.log
type %stemp%\TrolleyExpress*.log >> %logshare%%ComputerName%.log

goto End

:NotFound
echo %date% %time% Package was NOT detected, Halting >> %logshare%%ComputerName%.log
goto End

:End
echo %date% %time% the %0 script has completed successfully >> %logshare%%ComputerName%.log
Endlocal

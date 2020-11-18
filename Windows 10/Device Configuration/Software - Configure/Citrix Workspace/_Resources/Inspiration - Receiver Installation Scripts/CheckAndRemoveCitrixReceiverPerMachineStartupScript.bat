REM *************************************************************
REM *************************************************************
REM *************************************************************
REM *************************************************************
REM ***                                                       ***
REM *** DATE:    May 9, 2011                                  ***
REM ***                                                       ***
REM ***                                                       ***
REM *** DESCRIPTION:                                          ***
REM ***          Check and Remove Citrix Receiver PM          ***
REM ***          Via Active Directory Startup Script          ***
REM ***                                                       ***
REM *** INPUTS:                                               ***
REM ***          (1) Package Location/Deployment Directory    ***
REM ***          (2) Script Logging Directory                 ***
REM ***                                                       ***
REM *** OUTPUTS: Removes the Citrix Receiver PM               ***
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

set CustomConfig=None
REM Check if the admin has placed a Custom appsrv.ini in Default User
IF EXIST "%SYSTEMDRIVE%\Documents and Settings\Default User\Application Data\ICAClient" set CustomConfig=exists_XP-2003
IF EXIST "%SYSTEMDRIVE%\Users\Default\AppData\Roaming\ICAClient" set CustomConfig=exists_Vista-WS08-Win7
REM
echo %date% %time% the %0 script result for CustomConfig is %CustomConfig% >> %logshare%%ComputerName%.log

REM Check if the machine is 64bit
REM
IF NOT "%ProgramFiles(x86)%"=="" SET WOW6432NODE=WOW6432NODE\

REM Check if Citrix receiver installed
REM
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\%WOW6432NODE%Citrix\ICA Client"
if %errorlevel%==1 (goto NotFound) else (goto Found)

REM If 1 returned, the product was not found.

:Found

echo %date% %time% Package detected, Begin Removal >> %logshare%%ComputerName%.log

REM
REM Place the product installer in the same Script directory or else specify the path
REM
start /wait %deploydirectory%\CitrixReceiver.exe /SILENT /uninstall /cleanup

echo %date% %time% Removal ended with error code %errorlevel%. >> %logshare%%ComputerName%.log


echo %date% %time%             : >> %logshare%%ComputerName%.log
echo %date% %time% Install Logs: >> %logshare%%ComputerName%.log
echo %date% %time%             : >> %logshare%%ComputerName%.log

type %temp%\TrolleyExpress*.log >> %logshare%%ComputerName%.log


if %CustomConfig%==exists_XP-2003 goto End
if %CustomConfig%==exists_Vista-WS08-Win7 goto End

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


:NotFound
echo %date% %time% Package was NOT detected, Halting >> %logshare%%ComputerName%.log
goto End

:End
echo %date% %time% the %0 script has completed successfully >> %logshare%%ComputerName%.log
Endlocal

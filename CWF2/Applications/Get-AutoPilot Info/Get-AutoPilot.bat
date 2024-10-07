@ECHO OFF
SETLOCAL

TITLE Get Autopilot information

::---------------------------------------------------------------------------------------------------------------------
"%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system" >nul 2>&1 
IF %ERRORLEVEL% NEQ 0 (
CLS
ECHO.
ECHO.
ECHO ***************************************************
ECHO * This script needs to be run as administrator.   *
ECHO * Please close the script, rightclick and choose  *
ECHO *         "Run as administrator"                  *
ECHO ***************************************************
PAUSE
EXIT
)
::---------------------------------------------------------------------------------------------------------------------

:: Get the computer name
SET "computername=%COMPUTERNAME%"

:: Export system information to a text file named after the computer name
systeminfo > "%~dp0%computername%.txt"

:: Export TPM information to the same text file
tpmtool getdeviceinformation >> "%~dp0%computername%.txt"

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GetAutopilotInfo.ps1"
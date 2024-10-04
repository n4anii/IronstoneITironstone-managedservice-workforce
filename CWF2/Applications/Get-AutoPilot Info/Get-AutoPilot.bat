@echo off
setlocal

:: Get the computer name
set "computername=%COMPUTERNAME%"

:: Export system information to a text file named after the computer name
systeminfo > "%~dp0%computername%.txt"

:: Export TPM information to the same text file
tpmtool getdeviceinformation >> "%~dp0%computername%.txt"

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GetAutopilotInfo.ps1"


@ECHO OFF
:: Version 1.1.0.0
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Create IntuneWin
CLS

SET "RequiredFiles=Toolkit\Deploy-Application.exe IntuneWinAppUtil.exe"
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

SET _Setup_Folder=%~dp0Toolkit
SET _Source_Setup_File=Deploy-Application.exe
SET _Output_Folder=%~dp0Output
SET _IntuneWinAppUtil=%~dp0IntuneWinAppUtil.exe

IF NOT EXIST "%_Setup_Folder%" (
    ECHO The setup folder "%_Setup_Folder%" does not exist.
    PAUSE
    EXIT /B
)

IF NOT EXIST "%_Setup_Folder%\%_Source_Setup_File%" (
    ECHO The source setup file "%_Setup_Folder%\%_Source_Setup_File%" does not exist.
    PAUSE
    EXIT /B
)

IF NOT EXIST "%_Output_Folder%" (
    MKDIR "%_Output_Folder%" >NUL
)

:: Download new version from https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool
ECHO ******************************************************************
ECHO * Creating IntuneWin from PSADT content found in Toolkit folder! *
ECHO ******************************************************************
"%_IntuneWinAppUtil%" -c "%_Setup_Folder%" -s "%_Source_Setup_File%" -o "%_Output_Folder%" -q
IF %ERRORLEVEL% GTR 0 ECHO Something went wrong! ERRORLEVEL=%ERRORLEVEL%

PAUSE
@ECHO OFF
:: Version 1.0.0.2
TITLE Create IntuneWin
CLS

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

IF NOT EXIST "%_IntuneWinAppUtil%" (
    ECHO IntuneWinAppUtil.exe does not exist at "%_IntuneWinAppUtil%".
	PAUSE
    EXIT /B
)
:: Download new version from https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool
ECHO ******************************************************************
ECHO * Creating IntuneWin from PSADT content found in Toolkit folder! *
ECHO ******************************************************************
TIMEOUT 5 >NUL
"%_IntuneWinAppUtil%" -c "%_Setup_Folder%" -s "%_Source_Setup_File%" -o "%_Output_Folder%" -q
IF %ERRORLEVEL% GTR 0 ECHO Something went wrong! ERRORLEVEL=%ERRORLEVEL%

PAUSE
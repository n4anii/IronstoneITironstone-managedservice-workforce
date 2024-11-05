@ECHO OFF
:: Version 1.1.0.0
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Extract IntuneWin
CLS

:: Configuration
SET "_ExtractUtility=IntuneWinAppUtilDecoder.exe"

:: First check if decoder exists
IF NOT EXIST "%~dp0%_ExtractUtility%" (
    ECHO Error: %_ExtractUtility% not found in the current directory.
    ECHO Please ensure the decoder utility is in the same folder as this script.
    ECHO.
    PAUSE
    EXIT /B 1
)

:: Find .intunewin file
SET "_IntunewinPath="
FOR %%F IN ("%~dp0*.intunewin") DO (
    SET "_IntunewinPath=%%~nxF"
)

:: Check if .intunewin file exists
IF "%_IntunewinPath%"=="" (
    ECHO Error: No .intunewin file found in the current directory.
    ECHO Please place an .intunewin file in the same folder as this script.
    ECHO.
    PAUSE
    EXIT /B 1
)

ECHO *********************************************
ECHO * Extracting IntuneWin to current directory *
ECHO *********************************************

:: Run extraction with error handling
"%_ExtractUtility%" "%_IntunewinPath%" /silent
IF %ERRORLEVEL% GTR 0 (
    ECHO Error: Extraction failed with error code %ERRORLEVEL%
)

PAUSE
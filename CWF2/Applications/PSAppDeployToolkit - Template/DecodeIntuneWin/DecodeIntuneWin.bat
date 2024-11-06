@ECHO OFF
:: Version 1.3.0.0
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Decode IntuneWin
CLS
:: Configuration
PUSHD %~dp0
SET "_DecodeUtilityPath=%~dp0IntuneWinAppUtilDecoder.exe"
:: First check if decoder exists
IF NOT EXIST "%_DecodeUtilityPath%" (
    ECHO Error: %_DecodeUtilityPath% not found in the current directory.
    ECHO Please ensure the decoder utility is in the same folder as this script.
    ECHO.
    PAUSE
    EXIT /B 1
)
:: Find .intunewin file
SET "_IntunewinPath="
FOR %%F IN ("*.intunewin") DO (
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

ECHO Decoding IntuneWin to current directory
:: Run extraction with error handling
"%_DecodeUtilityPath%" "%_IntunewinPath%" /silent
IF %ERRORLEVEL% GTR 0 (
    ECHO Error: Extraction failed with error code %ERRORLEVEL%
    PAUSE
    EXIT /B 1
)

:: Extract the decoded .zip file
FOR %%F IN ("*.decoded.zip") DO (
    SET "_DecodedZipPath=%%~nxF"
)
ECHO Extracting %_DecodedZipPath% to the current directory\Extracted
"%SystemRoot%\System32\WindowsPowerShell\v1.0\PowerShell.exe" -Command "Expand-Archive -Path '%_DecodedZipPath%' -DestinationPath 'Extracted' -Force"
IF %ERRORLEVEL% GTR 0 (
    ECHO Error: Extraction of %_DecodedZipPath% failed with error code %ERRORLEVEL%
    PAUSE
    EXIT /B 1
)

POPD
PAUSE
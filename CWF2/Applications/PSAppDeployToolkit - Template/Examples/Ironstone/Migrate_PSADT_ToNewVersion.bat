@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Migrate PSADT to new Template

ECHO Listing all directories under %~dp0

PUSHD %~dp0
DIR /AD /B

SET /P _NewPSADTContent=Enter the path to new PSADT content: 
SET /P _OldPSADTContent=Enter the path to old PSADT content: 

IF NOT EXIST "%_NewPSADTContent%" (
    ECHO Unable to find folder "%_NewPSADTContent%".
    PAUSE
    EXIT /B
)

IF NOT EXIST "%_OldPSADTContent%" (
    ECHO Unable to find folder "%_OldPSADTContent%".
    PAUSE
    EXIT /B
)

ROBOCOPY "%_OldPSADTContent%\Examples\Ironstone" "%_NewPSADTContent%\Examples\Ironstone" >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit\AppDeployToolkit" "%_NewPSADTContent%\Toolkit\AppDeployToolkit" AppDeployToolkitExtensions.ps1 >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit\AppDeployToolkit" "%_NewPSADTContent%\Toolkit\AppDeployToolkit" AppDeployToolkitLogo.ico >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit\AppDeployToolkit" "%_NewPSADTContent%\Toolkit\AppDeployToolkit" AppDeployToolkitLogo.png >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit\AppDeployToolkit" "%_NewPSADTContent%\Toolkit\AppDeployToolkit" AppDeployToolkitBanner.png >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit\Files" "%_NewPSADTContent%\Toolkit\Files" _DeleteMe.txt >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit\SupportFiles" "%_NewPSADTContent%\Toolkit\SupportFiles" _DeleteMe.txt >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit" "%_NewPSADTContent%\Toolkit" Deploy-Application.ps1 >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit" "%_NewPSADTContent%\Toolkit" Logs.lnk >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit" "%_NewPSADTContent%\Toolkit" Invoke-ServiceUI.ps1 >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit" "%_NewPSADTContent%\Toolkit" ServiceUI_x86.exe >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%\Toolkit" "%_NewPSADTContent%\Toolkit" ServiceUI_x64.exe >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%" "%_NewPSADTContent%" _Install.bat >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%" "%_NewPSADTContent%" CHANGELOG_Ironstone.txt >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%" "%_NewPSADTContent%" CMTrace.exe >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%" "%_NewPSADTContent%" CreateIntuneWin.bat >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%" "%_NewPSADTContent%" IntuneWinAppUtil.exe >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)
ROBOCOPY "%_OldPSADTContent%" "%_NewPSADTContent%" PsExec64.exe >NUL
IF %ERRORLEVEL% GTR 1 (ECHO Robocopy failed copying a file! && PAUSE)

PAUSE
@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SET "MSIPATH=%~dp0"

FOR %%I IN ("%MSIPATH%*.msi") DO (
    SET "MSIFILEPATH=%%I"
    FOR %%F IN ("!MSIFILEPATH!") DO SET "MSIFILENAME=%%~nxF"
)

SET "LOGFILE=!MSIFILEPATH:~-\=_%_Uninstall.log!"
SET "LOGFILE=%TEMP%\!LOGFILE!"

"C:\Windows\System32\msiexec.exe" /X "!MSIFILEPATH!" /QN /NORESTART /LOG "%TEMP%\!MSIFILENAME!_Uninstall.log"

ENDLOCAL

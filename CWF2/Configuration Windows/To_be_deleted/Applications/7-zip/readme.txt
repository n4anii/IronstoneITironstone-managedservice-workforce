Name 7-zip
Description * 
7-zip

Publisher
Ironstone/7

LOGO: C:\Git\Ironstone-ManagedService-Workforce\Client Apps\Logos\Windows 10

Install command: 
7z2107-x64.exe /s
Uninstall command:
"%ProgramFiles%\7-Zip\Uninstall.exe" /s


Detection:
Manually configure detection
Rule type: File
Path: C:\Program Files\
File or folder: 7-Zip
Detection method: file or folder exists
$PathDirOfficeInstall = $(if (Test-Path -Path ('{0}\Microsoft Office' -f (${env:ProgramFiles(x86)}))){('{0}\Microsoft Office' -f (${env:ProgramFiles(x86)}))}else{('{0}\Microsoft Office' -f ($env:ProgramFiles))})
$PathFileNotePadPlusPlus =  ('{0}\Notepad++\notepad++.exe' -f ($env:ProgramW6432))

Get-ChildItem -Path $DirOfficeInstall -Recurse -File | Where-Object -Property 'Name' -EQ 'WINWORD.EXE' | Select-Object *




[PSCustomObject[]] $Software = @(
    [PSCustomObject[]]@('Microsoft Office Word','path\to\exe')
)



# Different ways of getting file info
Get-ChildItem -Path $PathFileNotePadPlusPlus -File | Select-Object -Property *
Get-ItemProperty -Path $PathFileNotePadPlusPlus | Select-Object -Property *
Get-Item -Path $PathFileNotePadPlusPlus | Select-Object -Property *
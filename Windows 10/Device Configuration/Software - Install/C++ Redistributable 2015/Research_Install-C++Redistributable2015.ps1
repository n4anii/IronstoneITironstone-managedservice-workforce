[string[]] $UrisDownload = @('https://download.visualstudio.microsoft.com/download/pr/20ef12bb-5283-41d7-90f7-eb3bb7355de7/8b58fd89f948b2430811db3da92299a6/vc_redist.x64.exe',
                             'https://download.visualstudio.microsoft.com/download/pr/749aa419-f9e4-4578-a417-a43786af205e/d59197078cc425377be301faba7dd87a/vc_redist.x86.exe')
[string] $PathDirOut  = '{0}\Temp\VCRedist' -f $env:windir

if (Test-Path -Path $PathDirOut) {Remove-Item -Path $PathDirOut -Recurse -Force -ErrorAction Stop}
$null = New-Item -ItemType 'Directory' -Path $PathDirOut -Force


foreach ($Uri in $UrisDownload) {
    [string] $NameFileOut = $Uri.Split('/')[-1]
    [string] $PathFileOut = ('{0}\{1}' -f ($PathDirOut,$NameFileOut))
    Start-BitsTransfer -Source $Uri -Destination $PathFileOut -ErrorAction Stop
    #if ($?) {Start-Job -FilePath $PathFileOut -ArgumentList '/install /passive /quiet /norestart'}
}
# Assets - Generic
$PathIronShowDir       = [string]$('{0}\IronstoneIT\IronShow' -f ($env:ProgramW6432))
$RegPathIronShowDir    = [string]$('Registry::HKEY_CURRENT_USER\Software\IronstoneIT\IronShow')
$PathWallpapersDir     = [string]$('{0}\Wallpapers' -f ($PathIronShowDir))
$FileTypesWallpapers   = [string[]]$('jpg','jpeg')

# Get All Wallpapers
$PathWallpaperFiles    = [string[]]$(Get-ChildItem -Path $PathWallpapersDir -File -Force -Recurse:$false -ErrorAction 'Stop' | Select-Object -ExpandProperty 'FullName' | Where-Object -FilterScript {$FileTypesWallpapers -contains $_.Split('.')[-1]} | Sort-Object) 

# Last Set Wallpaper
$LastSetWallpaperIndex = [byte]$($x=[byte]$(Get-ItemProperty -Path $RegPathIronShowDir -Name 'LastSetWallpaper' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'LastSetWallpaper' -ErrorAction 'SilentlyContinue' );if($?){$x}else{0})

# Make sure we don't goof
if ($PathWallpaperFiles.Count -le 0) {
    Write-Verbose -Message ('BREAK: Can`t change wallpapers when no wallpapers is found.')
    Break
}
else {
    # Help Variables
    $NextWallpaperIndex = [byte]$(0)
    
    # If only one wallpaper is found
    if ($PathWallpaperFiles.Count -le 1) {
        if ($LastSetWallpaperIndex -ne 0) {
            $NextWallpaperIndex = [byte]$(0)
        }
        else {
            Write-Verbose -Message ('BREAK: Only one wallpaper found, and it`s already set.')
            Break
        }
    }
    
    # If multiple wallpapers are found
    else {
        # If last set wallpaper has a higher index than available wallpapers
        if ($PathWallpaperFiles.Count -lt $LastSetWallpaperIndex) {
            $LastSetWallpaperIndex = [byte]$(0)
        }
        
        # Choose next wallpaper
        $PossibilitiesIndex    = [byte]$($PathWallpaperFiles.Count)
        $NextWallpaperIndex    = [byte]$($x=[byte]$($LastSetWallpaperIndex);while($x -eq $LastSetWallpaperIndex){$x=[System.Random]::new().Next($PossibilitiesIndex)};$x)
    }


#region    Set Next Wallpaper
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper {

    public class Setter {
        public const int SetDesktopWallpaper = 20;
        public const int UpdateIniFile = 0x01;
        public const int SendWinIniChange = 0x02;

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo (int uAction, int uParam, string lpvPara, int fuWinIni);

        public static void SetWallpaper (string path) {

            SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);

            RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);

            //Style, "Fill" = 10, "Fit" = 6
            key.SetValue(@"WallpaperStyle", "10");
            key.SetValue(@"TileWallpaper", "0");

            key.Close();
        }
    }
}
'@

[Wallpaper.Setter]::SetWallpaper($PathWallpaperFiles[$NextWallpaperIndex])
#endregion Set Next Wallpaper


    # Store Info in Registry
    if (-not(Test-Path -Path $RegPathIronShowDir)){$null = New-Item -Path $RegPathIronShowDir -ItemType 'Directory' -Force -ErrorAction 'Stop'}
    $null = Set-ItemProperty -Path $RegPathIronShowDir -Name 'LastSetWallpaper' -Value $NextWallpaperIndex -Type 'DWord' -Force -ErrorAction 'Stop'
}
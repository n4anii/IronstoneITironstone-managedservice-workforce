<#
    User_Add-ShortcutToDesktop&StartMenu_URL(Backe-u4).ps1

    .SYNOPSIS
        Creates a shortcut on the users desktop, pointing to a URL.

    .DESCRIPTION
        Creates a shortcut on the users desktop, pointing to a URL.
        * Create a 128x128pc icon in PNG. 
            * Background: Rounded rectangle with 17px radius (Paint.NET)
        * Losslessly compress with Pinga or similar
        * Convert to .ICO here:   https://convertico.com/
        * Convert to BASE64 here: https://www.browserling.com/tools/file-to-base64

    .NOTES
        * In Intune, remember to set "Run this script using the logged in credentials"  according to the $DeviceContext variable.
            * Intune -> Device Configuration -> PowerShell Scripts -> $NameScriptFull -> Properties -> "Run this script using the logged in credentials"
            * DEVICE (Local System) or USER (Logged in user).
        * Only edit $NameScript and add your code in the #region Your Code Here.
        * You might want to touch "Settings - PowerShell - Output Preferences" for testing / development. 
            * $VerbosePreference, eventually $DebugPreference, to 'Continue' will print much more details.
#>


# Script Variables
$NameScript            = [string] 'Add-ShortcutToDesktop&StartMenu_URL(Backe-UBWWeb)'
$DeviceContext         = [bool]   $false
$WriteToHKCUFromSystem = [bool]   $false

# Script Settings
$AddToDesktop          = [bool]   $true
$AddToStartMenu        = [bool]   $true
$ShortcutName          = [string] 'UBW Web'
$ShortcutURL           = [string] 'https://ubwweb-backe8.msappproxy.net/agrprod/'
$ShortcutNameToRemove  = [string[]]$('U4 Prod')
$ShortcutIconAsBase64  = [string] 'AAABAAEAMDAAAAAAAACoJQAAFgAAACgAAAAwAAAAYAAAAAEAIAAAAAAAACQAAAAAAAAAAAAAAAAAAAAAAACOh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/4+Iff+QiX7/j4h9/46HfP+Oh3z/j4h9/5CJfv+PiH3/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Nh3z/jYh9/42Iff+NiH3/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+PiH3/j4h9/4mCd/+GfnP/iIF2/4yFev+Nhnr/iYF2/4Z+c/+JgXb/j4h9/4+Iff+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+RhXr/k4N5/5ODef+ThHn/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/4+Ifv+MhXn/iIF1/6Self/IxL//3tzZ/+nn5f/p6Ob/4N7b/8rHwv+nopn/iYJ2/4uEeP+PiX7/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jYh9/5KEev9tn4//UbOf/1Sxnf9ZrZr/iop+/4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4h+/4qDd/+Vj4T/2tfU////////////////////////////////////////////4N7b/5qUiv+Jgnb/kIl+/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/42HfP+Nh3z/jYd8/42HfP+Nh3z/jIh9/5SDef9Yrpv/Ks+1/zDLsf84xq3/iIt//4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+PiH3/ioN4/5qUiv/w7+7///////39/f/8/Pz///////////////////////z8/P/9/f3///////b19P+hm5L/iYJ2/4+Ifv+Oh3z/jod8/46HfP+Oh3z/jod8/5CFe/+QhXv/kIV7/5CFe/+QhXv/j4Z8/5aBd/9dq5j/Msqx/zfGrf8+wan/iYt//4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/+bk4v///////Pz8//7+/v//////8vHw/+De2//f3dr/8O/t///////+/v7//Pz8///////u7Ov/koyB/42Gev+Oh33/jod8/46HfP+Qhnv/j4Z7/4WNgf+FjYH/hY2B/4WNgf+FjYH/hI6C/4uJfv9Xr5v/Mcux/zXHrv89wqr/iYt//4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/5CJfv+Hf3P/vLix///////8/Pz///////j39/+2sqv/kIl+/4qCd/+Jgnf/jod8/7Gtpf/19PP///////z8/P//////xsK8/4Z/c/+QiX7/jod8/4+HfP+MiX3/ULSf/zjGrf86xKz/OsSs/zrErP86xKz/OsSs/zvEq/84xq3/N8eu/zXIr/89wqr/iYt//4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+MhXr/5+bj///////+/f3//////66pof+Ce27/jod8/4+Iff+PiH3/j4h9/4N7b/+oopr///////7+/v//////7+7s/5GKf/+Nhnv/jYh9/5SDef9ynIz/Ls2z/zbHrv81yK//Nciu/zTJr/8zybD/NMmv/zPJr/80yK//Nciv/zPJsP88w6v/iYt//4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4h9/4uDeP+dl43//Pz7//7+/v//////5OPg/4mCdv+QiX7/jod9/46HfP+Oh3z/jod8/5GKf/+Hf3T/3dvY///////9/f3//////6Sflv+Jgnb/jol+/5GFev9/koT/Nseu/zbHrv83xq7/Nseu/zvDq/89wqr/PMOr/zzCqv88w6v/PMKq/zrErP9Cvqf/iYt//4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4h+/4iBdf+rpp7///////z8/P//////zcrF/4Z/c/+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+Gf3P/xsK8///////8/Pv//////7SwqP+HgHT/kIl+/42Iff+Ug3n/ZKaU/y/Msv84xa3/M8mw/0S9pv+HjID/iYt//4iLgP+Ii3//iIt//4iLf/+Ji3//jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////xsO9/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+Gf3P/wb23///////8+/v//////7u2sP+Gf3P/kIl+/46HfP+Oh3z/kYV6/0y3ov8xy7H/OcWs/zDMsv9fqZf/loF4/46HfP+Qhnv/j4Z7/5CGe/+Phnv/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb64///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+NiH3/kYV6/4SOgf86xKz/Nciv/zfGrf8yyrD/dpiJ/5OEef+MiH3/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jIh9/5SDef9wnY3/Mcux/zjGrf8zya//P8Cp/4qKfv+Phnv/jYd8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jod8/42Iff+Ug3n/V6+b/zDMsv85xaz/MMyy/1WxnP+Tg3n/jYh9/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jod8/42HfP+Phnv/jIl9/0G/p/8zybD/OMWt/zHLsf9vno7/lIN5/4yIff+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jod8/46HfP+NiH3/k4R5/3qVh/80yK//N8au/zXIr/86xKz/hY6B/5GFe/+NiHz/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jod8/46HfP+Oh3z/jIh9/5WCeP9jppT/L8yy/znFrP8xy7H/Tbah/5GEev+Nh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+RhXv/S7ii/zHLsf85xaz/MMyy/2akkv+Vgnj/jIh9/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wq6T///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wb23///////8+/v//////7q2r/+Gf3P/kIl+/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/42Iff+RhXr/hI+C/znFrP81yK//Nseu/zbHrv9/koX/koR6/42Iff+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4iAdP+wq6P///////r6+v//////xsK9/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+Gf3P/wb23///////6+vn//////7q1r/+Gf3P/kIl+/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+MiH3/lIN5/2+ejv8xy7H/OcWs/zPJsP9HuqT/kIZ7/4+Ge/+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4l+/4eAdP+wrKT///////z8+///////x8O+/4Z+cv+QiX7/jod8/46HfP+Oh3z/jod8/5CJfv+GfnP/wr65///////7+/v//////7u3sP+Gf3P/kIl+/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jYh9/5SDef9Xr5z/LM+0/zPJsP8q0LX/WK6b/5KEev+NiHz/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4h9/4qCd/+kn5b/3NnW/9bTz//d29j/s66n/4mBdv+PiH3/jod8/46HfP+Oh3z/jod8/4+Iff+JgXb/sKuj/93b2P/W08//3drX/6umnv+Jgnb/j4h9/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jYd8/5CGe/+Ji3//V6+b/1Sxnf9VsZ3/VLGd/4WNgf+Qhnv/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+MhXr/h4B0/4iAdf+HgHT/i4R4/46Iff+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh33/i4R5/4eAdP+IgHX/h4B0/4uEef+Oh33/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Phnz/k4N5/5ODef+Tg3n/k4N5/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh33/kIl+/4+Ifv+QiX7/j4h9/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/j4h9/5CJfv+PiH7/kIl+/4+Iff+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jYh9/42Iff+NiH3/jYh9/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP+Oh3z/jod8/46HfP8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'

#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptFull' -Value ([string]('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptVerb' -Value ([string]$NameScript.Split('-')[0])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptNoun' -Value ([string]$NameScript.Split('-')[-1])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureProcess' -Value ([string]$(if([System.Environment]::Is64BitProcess){'64'}else{'32'}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureOS' -Value ([string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'}))

# Dynamic Variables - User
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrSIDRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$(([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$($Script:StrSIDRunningAs -like ([string]$('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($Script:DeviceContext -and $Script:BoolIsSystem){$true}elseif(((-not($DeviceContext))) -and (-not($Script:BoolIsSystem))){$true}else{$false}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolWriteToHKCUFromSystem' -Value ([bool]$(if($DeviceContext -and $WriteToHKCUFromSystem){$true}else{$false}))

# Dynamic Variables - Logging
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'Timestamp' -Value ([string]$([datetime]::Now.ToString('yyMMdd-HHmmssffff')))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathDirLog' -Value ([string]$('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ([string]$(if($BoolIsSystem){$env:ProgramW6432}else{[System.Environment]::GetEnvironmentVariable('AppData')}))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathFileLog' -Value ([string]$('{0}{1}-{2}bit-{3}.txt' -f ($Script:PathDirLog,$Script:NameScriptFull,$Script:StrArchitectureProcess,$Script:Timestamp)))

# Start Transcript
if (-not(Test-Path -Path $Script:PathDirLog)) {$null = New-Item -ItemType 'Directory' -Path $Script:PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $Script:PathFileLog -ErrorAction 'Stop'


# Wrap in Try/Catch, so we can always end the transcript
Try {
    # Output User Info, Exit if not $BoolIsCorrectUser
    Write-Output -InputObject ('Running as user "{0}" ({1}). Has admin privileges? {2}. $DeviceContext? {3}. Running as correct user? {4}.' -f ($Script:StrUserNameRunningAs,$Script:StrSIDRunningAs,$Script:BoolIsAdmin.ToString(),$Script:DeviceContext.ToString(),$Script:BoolIsCorrectUser.ToString()))
    if (-not($Script:BoolIsCorrectUser)){Throw 'Not running as correct user!'; Break}


    # Output Process and OS Architecture Info
    Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($Script:StrArchitectureProcess,$Script:StrArchitectureOS))


    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if (-not([string]::IsNullOrEmpty($MyInvocation.'Line'))) {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $MyInvocation.'Line'}
        else {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($MyInvocation.'InvocationName')) $args}
        exit $LASTEXITCODE
    }

    
    #region    Get SID and "Domain\Username" for Intune User only if $WriteToHKCUFromSystem
        # If running in Device Context as "NT Authority\System"
        if ($DeviceContext -and $Script:BoolIsSystem -and $BoolWriteToHKCUFromSystem) {
            # Help Variables
            $Script:RegistryLoadedProfiles = [string[]]@()
            $Local:SID                     = [string]::Empty
            $Local:LengthInterval          = [byte[]]@(40 .. 80)


            # Load User Profiles NTUSER.DAT (Registry) that is not available from current context
            $PathProfileList = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
            $SIDsProfileList = [string[]]@(Get-ChildItem -Path $PathProfileList -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process {$_.Split('\')[-1]} | Where-Object -FilterScript {$_ -like 'S-1-12-*'})
            foreach ($SID in $SIDsProfileList) {
                if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID)) -ErrorAction 'SilentlyContinue') {
                    Write-Output -InputObject ('User with SID "{0}" is already logged in and/or NTUSER.DAT is loaded.' -f ($SID))
                }
                else {
                    Write-Output -InputObject ('User with SID "{0}" is not logged in, thus NTUSER.DAT is not loaded into registry.' -f ($SID))
                    
                    # Get User Directory
                    $PathUserDirectory = [string]$(Get-ItemProperty -Path ('{0}\{1}' -f ($PathProfileList,$SID)) -Name 'ProfileImagePath' | Select-Object -ExpandProperty 'ProfileImagePath')
                    if ([string]::IsNullOrEmpty($PathUserDirectory)) {
                        Throw ('ERROR: No User Directory was found for user with SID "{0}".' -f ($SID))
                    }

                    # Get User Registry File, NTUSER.DAT
                    $PathFileUserRegistry = ('{0}\NTUSER.DAT' -f ($PathUserDirectory))
                    if (-not(Test-Path -Path $PathFileUserRegistry)) {
                        Throw ('ERROR: "{0}" does not exist.' -f ($PathFileUserRegistry))
                    }

                    # Load NTUSER.DAT
                    $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]([system.environment]::SystemDirectory))) -ArgumentList ('LOAD "HKEY_USERS\{0}" "{1}"' -f ($SID,$PathFileUserRegistry)) -WindowStyle 'Hidden' -Wait
                    if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID))) {
                        Write-Output -InputObject ('{0}Successfully loaded "{1}".' -f ("`t",$PathFileUserRegistry))
                        $RegistryLoadedProfiles += @($SID)
                    }
                    else {
                        Throw ('ERROR: Failed to load registry hive for SID "{0}", NTUSER.DAT location "{1}".' -f ($SID,$PathFileUserRegistry))
                    }
                }
            }


            # Get Intune User Information from Registry
            $IntuneUser = [PSCustomObject]([PSCustomObject[]]@(
                foreach ($x in [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {[bool]$($_ -like 'S-1-12-*') -and [bool]$(Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($_)))})) {
                    [PSCustomObject]@{
                        'IntuneUserSID' =[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserSID' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'IntuneUserSID');
                        'IntuneUserName'=[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserName' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'IntuneUserName');
                        'DateSet'       =Try{[datetime](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'DateSet' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'DateSet')}Catch{[datetime]::MinValue};
                    }
                }) | Where-Object {-not([string]::IsNullOrEmpty($_.IntuneUserSID) -or [string]::IsNullOrEmpty($_.IntuneUserName))} | Sort-Object -Property 'DateSet' -Descending:$false | Select-Object -Last 1
            )


            # Get Intune User SID
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value (
                [string]$(
                    $Local:SID = [string]::Empty
                    # Try by registry values in HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo
                    if (-not([string]::IsNullOrEmpty([string]($IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID')))) {
                        $Local:SID = [string]($IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID')
                    }

                    # If no valid SID yet, try Registry::HKEY_USERS
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                        # Get all potential SIDs from Registry::HKEY_USERS
                        $Local:SIDsFromRegistryAll = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes' -and $Local:LengthInterval.Contains([byte]$_.'Length')})
                        $Local:SID = [string]$(
                            # If none where found - Return emtpy string: Finding SID by registry will not be possible
                            if (@($Local:SIDsFromRegistryAll).'Count' -le 0) {
                                [string]::Empty
                            }
                            # If only one where found - Return it
                            elseif (@($Local:SIDsFromRegistryAll).'Count' -eq 1) {
                                [string]([string[]]@($Local:SIDsFromRegistryAll | Select-Object -First 1))
                            }
                            # If multiple where found - Try to filter out unwanted SIDs
                            else {
                                # Try to get all where IronstoneIT folder exist withing HKU (HKCU) registry
                                $Local:SIDs = [string[]]@([string[]]@($Local:SIDsFromRegistryAll) | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT' -f ($_))})
                                # If none or more than 1 where found - Try getting only SIDs with AAD joined info in HKU (HKCU) registry
                                if (@($Local:SIDs).'Count' -le 0 -or @($Local:SIDs).'Count' -ge 2) {
                                    $Local:SIDs = [string[]]@([string[]]@($Local:SIDsFromRegistryAll) | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_))})
                                }
                                # If none or more than 1 where found - Try matching Tenant ID for AAD joined HKLM with Tenant ID for AAD joined HKU (HKCU)
                                if (@($Local:SIDs).'Count' -le 0 -or @($Local:SIDs).'Count' -ge 2) {
                                    if (-not([string]::IsNullOrEmpty(($Local:TenantGUIDFromHKLM = [string]$($x='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'; Get-ItemProperty -Path ('{0}\{1}' -f ($x,[string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId'))))) {
                                        $Local:SIDs = [string[]]@(@($Local:SIDsFromRegistryAll) | Where-Object {$Local:TenantGUIDFromHKLM -eq ([string]$($x=[string]('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)); Get-ItemProperty -Path ('{0}\{1}' -f ($x,([string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]})))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantDomain'))})
                                    }
                                }
                                if(@($Local:SIDs).'Count' -eq 1){
                                    [string]([string[]]@($Local:SIDs | Select-Object -First 1))
                                }
                                else{
                                    [string]::Empty
                                }
                            }
                        )
                    }

                    # If no valid SID yet, try by running process "Explorer"
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                        $Local:SID = [string]$(
                            $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.'ReturnValue' -eq 0 -and $Owner.'Domain' -notlike 'nt *' -and $Owner.'Domain' -notlike 'nt-*'){('{0}\{1}' -f ($Owner.'Domain',$Owner.'User'))})}) | Select-Object -Unique -First 1)
                            if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                                $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                            }
                            if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                                [string]::Empty
                            }
                            else {
                                Try{
                                    $Local:SID = [string]$([System.Security.Principal.NTAccount]::new($Local:UN).Translate([System.Security.Principal.SecurityIdentifier]).'Value')
                                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                                        [string]::Empty
                                    }
                                    else {
                                        $Local:SID
                                    }
                                }
                                catch{
                                    [string]::Empty
                                }
                            }
                        )
                    }
                
                    # If no valid SID yet, throw error
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                        Throw 'ERROR: Did not manage to get Intune user SID from SYSTEM context'
                    }

                    # If valid SID, return it
                    else {
                        $Local:SID
                    }         
                )
            )
        

            # Get Intune User Domain\UserName
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserName' -Value (
                [string]$(
                    # Help Variables
                    $Local:UN = [string]::Empty

                    # Try by registry values in HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo
                    if (-not([string]::IsNullOrEmpty($IntuneUser.'IntuneUserName'))) {
                        $Local:UN = [string]($IntuneUser.'IntuneUserName')
                    }
                
                    # If no valid UN yet, try by convertid $Script:StrIntuneUserSID to "Domain\Username"
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3 -and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                        $Local:UN = [string]$(Try{[System.Security.Principal.SecurityIdentifier]::new($Script:StrIntuneUserSID).Translate([System.Security.Principal.NTAccount]).Value}Catch{[string]::Empty})
                    }

                    # If no valid UN yet, try by Registry::HKEY_USERS\$Script:StrIntuneUserSID\Volatile Environment
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3-and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                        $Local:UN = [string]$(Try{$Local:x = Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrIntuneUserSID)) -Name 'USERDOMAIN','USERNAME' -ErrorAction 'SilentlyContinue';('{0}\{1}' -f ([string]($Local:x | Select-Object -ExpandProperty 'USERDOMAIN'),[string]($Local:x | Select-Object -ExpandProperty 'USERNAME')))}Catch{[string]::Empty})
                    }
                
                    # If no valid UN yet, try by running process Explorer.exe - Method 1
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                        $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.'ReturnValue' -eq 0 -and $Owner.'Domain' -notlike 'nt *' -and $Owner.'Domain' -notlike 'nt-*'){('{0}\{1}' -f ($Owner.'Domain',$Owner.'User'))})}) | Select-Object -Unique -First 1)
                    }
                
                    # If no valid UN yet, try by running process Explorer.exe - Method 2
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                        $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                    }                   

                    # If no valid UN yet, throw Error
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                        Throw 'ERROR: Did not manage to get "Domain"\"UserName" for Intune User.'
                    }

                    # If valid UN, return it
                    else {
                        $Local:UN
                    }
                )
            )
        }
        

        # If running in User Context / Not running as "NT Authority\System"
        elseif ((-not($Script:BoolIsSystem)) -and (-not($DeviceContext))) {
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserName' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))

            #region    Write SID and UserName to HKCU if running in User Context
                # Assets
                $Local:RegPath   = [string]('Registry::HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo')
                $Local:RegNames  = [string[]]@('IntuneUserSID','IntuneUserName','DateSet')
                $Local:RegValues = [string[]]@($Script:StrIntuneUserSID,$Script:StrIntuneUserName,([string]([datetime]::Now.ToString('o'))))

                # Get Current Info
                $Local:CurrentUserSID     = [string](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[0] -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty $Local:RegNames[0] -ErrorAction 'SilentlyContinue')
                $Local:CurrentUserName    = [string](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[1] -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty $Local:RegNames[1] -ErrorAction 'SilentlyContinue')
                $Local:CurrentUserDateSet = [datetime]$(Try{[datetime](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[2] -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty $Local:RegNames[2] -ErrorAction 'SilentlyContinue')}catch{[datetime]::MinValue})

                # Set Info if any of the values does not match wanted values
                if ($Local:CurrentUserSID -ne $Local:RegValues[0] -or $Local:CurrentUserName -ne $Local:RegValues[1] -or $Local:CurrentUserDateSet -eq [datetime]::MinValue) {      
                    if (-not(Test-Path -Path $Local:RegPath)) {
                        $null = New-Item -Path $Local:RegPath -Force -ErrorAction 'Stop'
                    }

                    foreach ($x in [byte[]]@(0 .. [byte]($Local:RegNames.'Length' - 1))) {
                        $null = Set-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[$x] -Value $Local:RegValues[$x] -Force -ErrorAction 'Stop'
                    }
                }
            #endregion Write SID and UserName to HKCU if running in User Context            
        }
        
        
        # Output Intune User and SID if found
        if (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID))) {
            Write-Output -InputObject ('Intune User SID "{0}", Username "{1}".' -f ($Script:StrIntuneUserSID,$Script:StrIntuneUserName))
        }
    #endregion Get SID and "Domain\Username" for Intune User



    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################



    # Assets
    $NameFileShortcut = [string]$('{0}.lnk' -f ($ShortcutName))
    $NameFileIcon     = [string]$('{0}.ico' -f ($ShortcutName))

    # Paths for shortcut - Define paths
    $PathsDirShortcut = [string[]]$()
    if ($AddToDesktop) {
        $PathsDirShortcut += [string[]]$((('{0}\Desktop' -f ($env:USERPROFILE)),[System.Environment]::GetFolderPath('Desktop')) | Select-Object -Unique)
    }
    if ($AddToStartMenu) {
        $PathsDirShortcut += [string[]]$('{0}\Microsoft\Windows\Start Menu\Programs' -f ($env:APPDATA))
    }

    # Paths for shortcut - Only keep paths that exist
    $PathsDirShortcut = [string[]]$($PathsDirShortcut | Where-Object -FilterScript {[bool]$(Test-Path -Path $_ -ErrorAction 'SilentlyContinue')})

    # Paths for shortcut - Exit if 0 paths in $PathsDirShortcut
    if ($PathsDirShortcut.'Count' -le 0) {
        Throw 'ERROR: Found no directories to put shortcuts in.'
    }

    # Paths for shortcut - Write paths to put shortcut in output
    Write-Output -InputObject ('# Paths where shortcut will be created:')
    $PathsDirShortcut.ForEach{Write-Output -InputObject $_}    

    # Icon file - Define paths
    $PathDirIcon  = [string]('{0}\IronstoneIT\Icons' -f ($env:LOCALAPPDATA))
    $PathFileIcon = [string]('{0}\{1}' -f ($PathDirIcon,$NameFileIcon))


    # Icon file - Export ICO file
    if (-not(Test-Path -Path $PathDirIcon))  {$null = New-Item -Path $PathDirIcon -ItemType 'Directory' -Force}
    if (Test-Path -Path $PathFileIcon)       {Remove-Item -Path $PathFileIcon -Force}
    [IO.File]::WriteAllBytes($PathFileIcon,[Convert]::FromBase64String($ShortcutIconAsBase64))


    # Create Shortcut
    foreach ($PathDirShortcut in $PathsDirShortcut) {        
        # Remove existing shortcut with same name
        foreach ($NameFileShortcutRemove in [string[]]$([string[]]$($ShortcutName)+[string[]]$($ShortcutNameToRemove) | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))} | Select-Object -Unique | Sort-Object)) {
            # For each possible shortcut extension
            foreach ($Extension in [string[]]$('lnk','url')) {
                # Create path to icon to remove
                $PathFileShortcutRemove = [string]('{0}\{1}.{2}' -f ($PathDirShortcut,$NameFileShortcutRemove,$Extension))
            
                # Remove it if it exist
                if(Test-Path -Path $PathFileShortcutRemove){$null = Remove-Item -Path $PathFileShortcutRemove -Force}
            }
        }
        
        # Create path to new shortcut file
        $PathFileShortcut = [string]('{0}\{1}' -f ($PathDirShortcut,$NameFileShortcut))

        # Create Shortcut
        $WshShell = New-Object -ComObject 'WScript.Shell'
        $Shortcut = $WshShell.CreateShortcut($PathFileShortcut)
        $Shortcut.'TargetPath'   = $ShortcutURL
        $ShortCut.'IconLocation' = [string]('{0}, 0' -f ($PathFileIcon))
        $Shortcut.Save()

        # Write Success Status
        Write-Output -InputObject ('Creating shortcut "{0}" pointing to "{1}". Success? {2}.' -f ($PathFileShortcut,$ShortcutURL,$?))
    }



################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = [string]$('Finished with errors:')
    $ErrorMessage += ('{0}{0}Exception:{0}{1}'             -f ("`r`n",$_.'Exception'))
    $ErrorMessage += ('{0}{0}CategoryInfo\Activity:{0}{1}' -f ("`r`n",$_.'CategoryInfo'.'Activity'))
    $ErrorMessage += ('{0}{0}CategoryInfo\Category:{0}{1}' -f ("`r`n",$_.'CategoryInfo'.'Category'))
    $ErrorMessage += ('{0}{0}CategoryInfo\Reason:{0}{1}'   -f ("`r`n",$_.'CategoryInfo'.'Reason'))
    # Write Error Message
    Write-Error -Message $ErrorMessage
}
Finally {
    # Unload Users' Registry Profiles (NTUSER.DAT) if any were loaded
    if ($Script:BoolIsSystem -and $BoolWriteToHKCUFromSystem -and ([string[]]@($RegistryLoadedProfiles | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))})).'Count' -gt 0) {
        # Close Regedit.exe if running, can't unload hives otherwise
        $null = Get-Process -Name 'regedit' -ErrorAction 'SilentlyContinue' | ForEach-Object -Process {Stop-Process -InputObject $_ -ErrorAction 'SilentlyContinue'}
            
        # Get all logged in users
        $SIDsLoggedInUsers = [string[]]$(([string[]]@(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique | ForEach-Object -Process {Try{[System.Security.Principal.NTAccount]::new(($_)).Translate([System.Security.Principal.SecurityIdentifier]).'Value'}Catch{}} | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))}),[string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')) | Select-Object -Unique)

        foreach ($SID in $RegistryLoadedProfiles) {
            # If SID is found in $SIDsLoggedInUsers - Don't Unload Hive
            if ([bool]$(([string[]]@($SIDsLoggedInUsers | ForEach-Object -Process {$_.Trim().ToUpper()})).Contains($SID.Trim().ToUpper()))) {
                Write-Output -InputObject ('User with SID "{0}" is currently logged in, will not unload registry hive.' -f ($SID))
            }
            # If SID is not found in $SIDsLoggedInUsers - Unload Hive
            else {
                $PathUserHive = [string]('Registry::HKEY_USERS\{0}' -f ($SID))
                $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]$([system.environment]::SystemDirectory))) -ArgumentList ('UNLOAD "{0}"' -f ($PathUserHive)) -WindowStyle 'Hidden' -Wait

                # Check success
                if (Test-Path -Path ('Registry::{0}' -f ($PathUserHive)) -ErrorAction 'SilentlyContinue') {
                    Write-Output -InputObject ('ERROR: Failed to unload user registry hive "{0}".' -f ($PathUserHive)) -ErrorAction 'Continue'
                }
                else {
                    Write-Output -InputObject ('Successfully unloaded user registry hive "{0}".' -f ($PathUserHive))
                }
            }
        }
    }
    
    # Stop Transcript
    Stop-Transcript
}
#endregion Don't touch this
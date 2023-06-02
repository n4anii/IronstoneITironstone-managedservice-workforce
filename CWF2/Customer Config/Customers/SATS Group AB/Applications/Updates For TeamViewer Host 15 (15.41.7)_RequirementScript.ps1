function Architecture {
    if ((Get-WmiObject win32_operatingsystem | Select-Object osarchitecture).osarchitecture.StartsWith("64")){
        return "64-bit OS"
    }
    else{
        return "32-bit OS"
    }
}
function filePathDir($path){
    if ($path -match 'programfiles'){ return $env:programfiles}
    if ($path -match 'windir'){ return $env:windir}
    return $env:programfiles
}    
function CheckDetection($cktype,$path,$keyName,$keyValue,$minVer,$maxVer,$archi,$detectionArchi){
    $path = $path -replace 'HKEY_LOCAL_MACHINE','HKLM:'
    if($archi -eq '64-bit OS'){
        if($cktype -eq 3 -OR $cktype -eq 5 -OR $cktype -eq 7 -OR $cktype -eq 9 -OR $cktype -eq 11 -OR $cktype -eq 12 -OR $cktype -eq 14 -OR $cktype -eq 16){
            if($path -like '#*'){
                $regHives = @($path.Split('#'))
                if(Test-Path $regHives[1]){
                    $regPath = $regHives[1]
                    $regKeyName = $regHives[2]
                    $regValueName = $regHives[3]
                    $path = ((Get-ItemProperty -path $regPath | Select-Object $regKeyName).$regKeyName) + $regValueName
                }
                else {return 1}
            }
            elseif($path -like '%#*'){
                $Hives = $path.Split('%')
                $regHives = $Hives[1].Split('#')
                if(Test-Path $regHives[1]){
                    $regPath = $regHives[1]
                    $regKeyName = $regHives[2]
                    $regValueName = $Hives[2]
                    $path = ((Get-ItemProperty -path $regPath | Select-Object $regKeyName).$regKeyName) + $regValueName
                }
                else {return 1}
            }
            else{
                $filePath = filePathDir($path)
                if($detectionArchi -eq 'x86'){ 
                    $filePath = $filePath -replace 'Program Files','Program Files (x86)'
                }
                $path = $filePath + '\' + $path.Split('\',2)[1]
            }    
        }
        if($cktype -eq 1 -OR $cktype -eq 2 -OR $cktype -eq 8 -OR $cktype -eq 21 -OR $cktype -eq 4 -OR $cktype -eq 10 -OR $cktype -eq 17 -OR $cktype -eq 18){
            if($detectionArchi -eq 'x86'){ 
                $path = $path -replace 'HKLM:\\SOFTWARE\\','HKLM:\SOFTWARE\WOW6432Node\'
            }
        }
    }
    if($archi -eq '32-bit OS'){
        if($detectionArchi -eq 'x64'){return 1}
        if($cktype -eq 3 -OR $cktype -eq 5 -OR $cktype -eq 7 -OR $cktype -eq 9 -OR $cktype -eq 11 -OR $cktype -eq 12 -OR $cktype -eq 14 -OR $cktype -eq 16){
            if($path -like '#*'){
                $regHives = $path.Split('#')
                if(Test-Path $regHives[1]){
                    $path = (Get-ItemProperty -path $path | Select-Object $regHives[2]).$regHives[2] + $regHives[3]
                }
                else {return 1}
            }
            elseif($path -like '%#*'){
                $Hives = $path.Split('%')
                $regHives = $Hives[1].Split('#')
                if(Test-Path $regHives[1]){
                    $path = (Get-ItemProperty -path $path | Select-Object $regHives[2]).$regHives[2] + $Hives[2]
                }
                else {return 1}
            }
            else{
                $filePath = filePathDir($path)
                $path = $filePath + '\' + $path.Split('\',2)[1]
            }    
        }
    }
    switch ($cktype){
        1{
            if(Test-Path $path) {return 0}
            return 1
        }
        2{
            if(Test-Path $path){
                $value = (Get-ItemProperty -path $path | Select-Object $keyName).$keyName
                if ($value -eq $keyValue) {return 0}
            }
            return 1
        }
        3{
            if(Test-Path $path){
                $value = (Get-ItemProperty $path).VersionInfo | ForEach-Object {("{0}.{1}.{2}.{3}" -f $_.FileMajorPart,$_.FileMinorPart,$_.FileBuildPart,$_.FilePrivatePart)}
                if ([version]$value -ge [version]$minVer){
                    if([version]$value -le [version]$maxVer){return 0}
                }
            }
            return 1
        }
        4{
            if(Test-Path $path){
                $value = (Get-ItemProperty -path $path | Select-Object $keyName).$keyName
                if ([version]$value -ge [version]$minVer){
                    if([version]$value -le [version]$maxVer){return 0}
                }
            }
            return 1
        }
        5{
            if(Test-Path $path){
                $value = (Get-ItemProperty $path).VersionInfo | ForEach-Object {("{0}.{1}.{2}.{3}" -f $_.FileMajorPart,$_.FileMinorPart,$_.FileBuildPart,$_.FilePrivatePart)}
                if ([version]$value -ge [version]$keyValue){return 0}
            }
            return 1
        }
        7{
            if(Test-Path $path) {return 0}
            return 1
        }
        8{
            if(Test-Path $path){
                $value = (Get-ItemProperty -path $path | Select-Object $keyName).$keyName
                if ([version]$value -ge [version]$keyValue){return 0}
            }
            return 1
        }
        9{
            if(Test-Path $path){
                $value = (Get-ItemProperty $path).VersionInfo | ForEach-Object {("{0}.{1}.{2}.{3}" -f $_.FileMajorPart,$_.FileMinorPart,$_.FileBuildPart,$_.FilePrivatePart)}
                if ($value -eq $keyValue) {return 0}
            }
            return 1
        }
        10{
            if(Test-Path $path){
                if (Get-ItemProperty -Path $path -Name $keyName -ErrorAction SilentlyContinue){return 0}
            }
            return 1
        }
        11{
            if(Test-Path $path){
                $size = (Get-Item $path).length
                if ($size -eq $keyValue){return 0}
            }
            return 1
        }
        12{
            if(Test-Path $path){
                $size = (Get-Item $path).length
                if ($size -ge $minVer){
                    if ($size -le $maxVer){return 0}
                }
            }
            return 1
        }
        14{
            if(Test-Path $path){
                $value = (Get-ItemProperty $path).VersionInfo | ForEach-Object {("{0}.{1}.{2}.{3}" -f $_.FileMajorPart,$_.FileMinorPart,$_.FileBuildPart,$_.FilePrivatePart)}
                if ([version]$value -lt [version]$keyValue){return 0}
            }
            return 1
        }
        16{
            if(Test-Path $path){return 1}
            return 0
        }
        17{
            if(Test-Path $path){return 1}
            return 0
        }
        18{
            if(Test-Path $path){
                if (Get-ItemProperty -Path $path -Name $keyName -ErrorAction SilentlyContinue){return 1}
            }
            return 0
        }
        21{
            if (Test-Path $path){
                $value = (Get-ItemProperty -path $path | Select-Object $keyName).$keyName
                if ($value -eq $keyValue){ return 1}
            }
            return 0
        }
        Default {return 1}
    }
}

$cktypes = 4,2
$Groupids = 0,0
$paths = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TeamViewer','HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TeamViewer'
$keyNames = 'DisplayVersion','DisplayName'
$keyValues = '-','TeamViewer Host'
$minVers = '15.000.0000','-'
$maxVers = '15.999.9999','-'
$Architecture = Architecture

if ($cktypes.length -eq 1){
    $isDetected = 2
    $detectionArchitecture = 'x86'
    if($paths -match '\$x64\$'){
        $detectionArchitecture = 'x64'
        $paths = $paths -replace '\$x64\$',''
    }
    $isDetected = CheckDetection $cktypes $paths $keyNames $keyValues $minVers $maxVers $Architecture $detectionArchitecture
    if ($isDetected -eq 0){
        return 0
    }
    return
}
else {
    $isDetected = @(2) * $cktypes.Length
    $detectionArchitecture = @('x86') * $paths.Length
    for($i=0; $i -lt $paths.Length; $i++){
        if($paths[$i] -match '\$x64\$'){
            $detectionArchitecture[$i] = 'x64'
            $paths[$i] = $paths[$i] -replace '\$x64\$',''
        }
    }
    for($i=0; $i -lt $cktypes.Length; $i++){
        $isDetected[$i] = CheckDetection $cktypes[$i] $paths[$i] $keyNames[$i] $keyValues[$i] $minVers[$i] $maxVers[$i] $Architecture $detectionArchitecture[$i]
    }
    $ckGroupid = $Groupids[0]
    $j = 0
    for($i=1; $i -le $cktypes.Length; $i++){
        if($i -eq $cktypes.Length){
            $compare = 0
            for(; $j -lt ($i) ; $j++){
                if($isDetected[$j] -ne 0){
                    $compare = 1
                    break
                }
            }
            if($compare -eq 0){return 0}
        }
        elseif(($Groupids[$i] -ne $ckGroupid)){
            $compare = 0
            for(; $j -lt ($i) ; $j++){
                if($isDetected[$j] -ne 0){
                    $compare = 1
                    $j+=1
                    break
                }
            }
            if($compare -eq 0){return 0}
            $ckGroupid = $Groupids[$i]
        }
    }
    return
}
if([IntPtr]::Size-eq4){exit 0};try{$r='\d+\.\d+(\.\d+)?(\.\d+)?';$t='silentlycontinue';$z='Mozilla Firefox*(x64 sv-SE)';$o='Detected';$d='113.0.2';function l {param($h,$f,$s)$v=[bool]((whoami /user)-match'S-1-5-18');$l="$(ni $env:programdata\PatchMyPCIntuneLogs -it di -fo -ea $t)\$(($q='PatchMyPC-SoftwareUpdateDetectionScript.log'))";$p=switch($v){$true{$l}default{"$env:temp\$q"}}if((($i=gi $p -ea $t)).length-ge5mb){ri ($w=$i.FullName.Replace('.log','.lo_')) -fo -ea $t;ren $i $w}"$(Get-Date)~[$s]~[Found:$f]~[Purpose:Detection]~[Context:$env:username)]~[Hive:$h]"|Out-File $p -a -fo}function c{param($s)try{switch($s.ToCharArray().Where{$_-eq'.'}.Count){0{$s+='.0'*3}1{$s+='.0.0'}2{$s+='.0'}}[version]$s}catch{$a=foreach($c in $s.Split('.')){try{[int]$c}catch{[int]::MaxValue}}try{c ([String]::Join('.',$a))}catch{[version]('0.0.0.0')}}}foreach($h in 'HKLM'){foreach($x in 'software'){foreach($s in(gp ($G="$h`:\$x\microsoft\windows\currentversion\uninstall\*") ($k='DisplayName'),DisplayVersion -ea $t|select @{l='a';e={$_.$k}},@{l='b';e={[regex]::match($_.DisplayVersion,$r)[0].value}},pschildname,@{l='c';e={[regex]::match($_.$k,$r)[0].value}})|?{if($_.pschildname-eq($m='')){($f=$true)}elseif($e='Mozilla Firefox*ESR*'){$_.a-notlike$e-and$_.a-like$z-and![bool]($_.pschildname-as[guid]-is[guid])}else{$_.a-like$z-and![bool]($_.pschildname-as[guid]-is[guid])}}){if($f){l $g $true "$($s.a) $m";return $o}if((c $s.b)-ge(c $d)-or(!$s.b-and$s.c-ne''-and(c $s.c)-ge(c $d))){if(($s.b-like($v='*')-or$s.c-like$v)){l $g $true "$($s.a) $d";return $o}}}l $g $false "$z $m $d"}}}catch{l '' '' $_.Exception.Message}
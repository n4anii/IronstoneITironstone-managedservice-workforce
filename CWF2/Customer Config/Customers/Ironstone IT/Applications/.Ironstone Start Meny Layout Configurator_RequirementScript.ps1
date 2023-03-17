$Path = ('{0}\Microsoft Intune Management Extension' -f (${env:ProgramFiles(x86)}))
[bool]$(
    [datetime]$(
        if([bool]$(Test-Path -Path $Path -ErrorAction 'SilentlyContinue')){
            Try{
                $Date = [datetime]$(Get-Item -Path $Path -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CreationTimeUtc')
                if ($Date -ne [datetime]::MinValue){$Date}else{[datetime]::UtcNow}
            }
            Catch{
                [datetime]::UtcNow
            }
        }
        else {
            [datetime]::UtcNow
        }
    ) -gt [datetime]::UtcNow.AddDays(-2)
)
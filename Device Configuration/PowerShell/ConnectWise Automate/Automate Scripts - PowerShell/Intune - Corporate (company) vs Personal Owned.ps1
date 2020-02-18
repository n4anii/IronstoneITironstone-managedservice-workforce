# Raw value
Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Ownership' -Name 'CorpOwned' -ErrorAction 'SilentlyContinue'


# Boolean output (Corporate = $true)
[bool]$(Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Ownership' -Name 'CorpOwned' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CorpOwned' -ErrorAction 'SilentlyContinue')


# String output ("Corporate" if true, "Personal" if false)
[string]$(if([bool]$(Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Ownership' -Name 'CorpOwned' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CorpOwned' -ErrorAction 'SilentlyContinue')){'Corporate'}else{'Personal'})


# String output ("Corporate" if true, "Personal" if false, "Unknown" if no value)
[string]$(
    $Value = Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments\Ownership' -Name 'CorpOwned' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CorpOwned' -ErrorAction 'SilentlyContinue'
    if ($?) {
        if ($Value -eq 1) {
            'Corporate'
        }
        elseif ($Value -eq 0) {
            'Personal'
        }
        else {
            ''
        }
    }
    else {
        ''
    }
)

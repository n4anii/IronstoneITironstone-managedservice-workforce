[bool](
    (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS' -Name 'BIOSVendor').'BIOSVendor' -in 'HP','Hewlett-Packard'
)
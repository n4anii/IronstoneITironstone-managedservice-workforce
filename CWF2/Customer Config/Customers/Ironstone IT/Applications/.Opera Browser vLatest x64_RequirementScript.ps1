﻿[bool]$([byte]$(([System.Diagnostics.Process[]]$(Get-Process -Name 'opera' -ErrorAction 'SilentlyContinue')).'Count') -le 0)
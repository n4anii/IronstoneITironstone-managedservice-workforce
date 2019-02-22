if ($false) {
    # Current User
    Remove-Item -Path 'HKCU:\Software\Arixcel' -Recurse -Force

    # Local Machine
    Remove-Item -Path 'HKLM:\SOFTWARE\Arixcel' -Recurse -Force
}
<# WINDOWS DEFENDER - ADVANCED THREAT PROTECTION #>

# Windows Defender - Force enable AntiSpyware and AntiVirus
# Fixes the "Sorry, we ran into a problem" message.
# https://www.virtualmvp.com/windows-defender-error-unexpected-error-sorry-we-ran-into-a-problem-please-try-again/
# HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender
# HKLM\SOFTWARE\Policies\Microsoft\Windows Defender
# DisableAntiSpyware 0 (REG_DWORD)
# DisableAntiVirus   0 (REG_DWORD)
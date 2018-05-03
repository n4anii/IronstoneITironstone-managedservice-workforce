﻿<#
.SYNOPSIS
    <Short, what it does>


.DESCRIPTION
    <Long, what it does>


.OUTPUTS
    <What it outputs during runtime>


Usage:


Todo:


Resources:
- Base64Encode.org (https://www.base64encode.org/) for Base64 encoding of the files

#>


#region Variables
# Settings
[bool] $DebugWinTemp = $true
[bool] $DebugConsole = $false
[bool] $ReadOnly = $false
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Install BitLockerTrigger'

# Files
#region Files
# Enable-BitLockerTrigger.PS1
#region FilePS1
[String] $Local:NamePS1 = 'Enable_BitLocker.ps1'
[String] $Local:FilePS1 = ('PCNQU1NjcmlwdEluZm8gDQouVkVSU0lPTiAxLjcNCi5HVUlEIGY1MTg3ZTNmLWVkMGEtNGNlMS1iNDM4LWQ4ZjQyMTYxOWNhMyANCi5PUklHSU5BTCBBVVRIT1IgSmFuIFZhbiBNZWlydmVubmUgDQouTU9ESUZJRUQgQlkgU29vcmFqIFJhamFnb3BhbGFuLCBQYXVsIEh1aWpicmVndHMsIFBpZXRlciBXaWdsZXZlbiAmIE5pYWxsIEJyYWR5ICh3aW5kb3dzLW5vb2IuY29tIDIwMTcvOC8xNykNCi5DT1BZUklHSFQgDQouVEFHUyBBenVyZSBJbnR1bmUgQml0TG9ja2VyICANCi5MSUNFTlNFVVJJICANCi5QUk9KRUNUVVJJICANCi5JQ09OVVJJICANCi5FWFRFUk5BTE1PRFVMRURFUEVOREVOQ0lFUyAgDQouUkVRVUlSRURTQ1JJUFRTICANCi5FWFRFUk5BTFNDUklQVERFUEVOREVOQ0lFUyAgDQouUkVMRUFTRU5PVEVTICANCiM+DQoNCjwjIA0KIA0KLkRFU0NSSVBUSU9OIA0KIENoZWNrIHdoZXRoZXIgQml0TG9ja2VyIGlzIEVuYWJsZWQsIGlmIG5vdCBFbmFibGUgQml0TG9ja2VyIG9uIEFBRCBKb2luZWQgZGV2aWNlcyBhbmQgc3RvcmUgcmVjb3ZlcnkgaW5mbyBpbiBBQUQgDQogQWRkZWQgbG9nZ2luZw0KIz4gDQoNCltjbWRsZXRiaW5kaW5nKCldDQpwYXJhbSgNCiAgICBbUGFyYW1ldGVyKCldDQogICAgW1ZhbGlkYXRlTm90TnVsbE9yRW1wdHkoKV0NCiAgICBbc3RyaW5nXSAkT1NEcml2ZSA9ICRlbnY6U3lzdGVtRHJpdmUNCikNCltOZXQuU2VydmljZVBvaW50TWFuYWdlcl06OlNlY3VyaXR5UHJvdG9jb2wgPSBbTmV0LlNlY3VyaXR5UHJvdG9jb2xUeXBlXTo6VGxzMTINCg0KRnVuY3Rpb24gTG9nV3JpdGUgew0KICAgIFBhcmFtIChbc3RyaW5nXSRsb2dzdHJpbmcpDQogICAgJGEgPSBHZXQtRGF0ZQ0KICAgICRsb2dzdHJpbmcgPSAkYSwgJGxvZ3N0cmluZw0KICAgIEFkZC1jb250ZW50ICRMb2dmaWxlIC12YWx1ZSAkbG9nc3RyaW5nDQogICAgV3JpdGUtaG9zdCAkbG9nc3RyaW5nDQp9DQoNCkZ1bmN0aW9uIExvZ0Vycm9ycyB7DQogICAgTG9nV3JpdGUgIkNhdWdodCBhbiBleGNlcHRpb246Ig0KICAgIExvZ1dyaXRlICJFeGNlcHRpb24gVHlwZTogJCgkXy5FeGNlcHRpb24uR2V0VHlwZSgpLkZ1bGxOYW1lKSINCiAgICBMb2dXcml0ZSAiRXhjZXB0aW9uIE1lc3NhZ2U6ICQoJF8uRXhjZXB0aW9uLk1lc3NhZ2UpIg0KfQ0KDQojIFNldHRpbmdzDQpbYm9vbF0gJEdVSSA9ICRmYWxzZQ0KW2Jvb2xdICRJc0VuY3J5cHRlZCA9IFtib29sXSAkSXNQcm90ZWN0aW9uUGFzc3cgPSBbYm9vbF0gJElzQmFja3VwT0QgPSBbYm9vbF0gJElzQmFja3VwQUFEID0gJGZhbHNlDQokTG9nZmlsZSA9ICJDOlxXaW5kb3dzXFRlbXBcVHJpZ2dlckJpdExvY2tlci5sb2ciDQpMb2dXcml0ZSAiU3RhcnRpbmcgVHJpZ2dlciBCaXRMb2NrZXIgc2NyaXB0LiINCg0KIyMjIyBHbG9iYWwgVmFyaWFibGVzIENyZWF0ZWQgYXQgcnVudGltZQ0KIyMgVGVuYW50DQokTG9jYWw6SUQgPSAoR2V0LUNoaWxkSXRlbSBDZXJ0OlxMb2NhbE1hY2hpbmVcTXlcIHwgV2hlcmUtT2JqZWN0IHsgJF8uSXNzdWVyIC1tYXRjaCAnQ049TVMtT3JnYW5pemF0aW9uLUFjY2VzcycgfSkuU3ViamVjdC5SZXBsYWNlKCdDTj0nLCcnKQ0KW1N0cmluZ10gJEdsb2JhbDpOYW1lVGVuYW50ID0gKEdldC1JdGVtUHJvcGVydHkgSEtMTTpcU1lTVEVNXEN1cnJlbnRDb250cm9sU2V0XENvbnRyb2xcQ2xvdWREb21haW5Kb2luXEpvaW5JbmZvXCQoJExvY2FsOklEKSkuVXNlckVtYWlsLlNwbGl0KCdAJylbMV0NCltTdHJpbmddICRHbG9iYWw6TmFtZVRlbmFudFNob3J0ID0gJEdsb2JhbDpOYW1lVGVuYW50LlNwbGl0KCcuJylbMF0NCiMjIE90aGVycw0KW1N0cmluZ10gJFNjcmlwdDpTY2hlZHVsZWRUYXNrTmFtZSA9ICdCaXRMb2NrZXJUcmlnZ2VyJw0KDQoNCiMjIyMjIyMjIyMjIyMjIyMjIyMjDQojIyMjIEVOQ1JZUFRJT04gIyMjIw0KIyMjIyMjIyMjIyMjIyMjIyMjIyMNCkxvZ1dyaXRlICgnIyMjIEJpdExvY2tlciBFbmNyeXB0aW9uJykNCiMgR2V0IGVuY3J5cHRpb24gc3RhdHVzDQpbTWljcm9zb2Z0LkJpdExvY2tlci5TdHJ1Y3R1cmVzLkJpdExvY2tlclZvbHVtZV0gJEJpdExvY2tTdGF0dXMgPSBHZXQtQml0TG9ja2VyVm9sdW1lICRPU0RyaXZlDQpbU3RyaW5nXSAkVm9sdW1lRW5jU2F0dXMgPSAoJEJpdExvY2tTdGF0dXMgfCBTZWxlY3QtT2JqZWN0IC1Qcm9wZXJ0eSBWb2x1bWVTdGF0dXMpLlZvbHVtZVN0YXR1cw0KTG9nV3JpdGUgKCcjIEVuY3J5cHRpb24nKQ0KTG9nd3JpdGUgKCdTdGF0dXMgb2YgT1MgZHJpdmUgKCcgKyAkT1NEcml2ZSArICcpID0gJyArICRWb2x1bWVFbmNTYXR1cykNCnRyeSB7DQogICAgIyBFbmNyeXB0IGlmIG5vdCBGdWxseUVuY3J5cHRlZA0KICAgIGlmICgkVm9sdW1lRW5jU3RhdHVzIC1lcSAnRnVsbHlEZWNyeXB0ZWQnKSB7DQogICAgICAgIExvZ1dyaXRlICgnQXR0ZW1wdGluZyB0byBFbmFibGUgQml0TG9ja2VyIG9uIE9TIGRyaXZlICh7MH0pJyAtZiAoJE9TRHJpdmUpKQ0KICAgICAgICAjIEVuYWJsZSBCaXRMb2NrZXIgdXNpbmcgVFBNDQogICAgICAgIEVuYWJsZS1CaXRMb2NrZXIgLU1vdW50UG9pbnQgJE9TRHJpdmUgLVRwbVByb3RlY3RvciAtRXJyb3JBY3Rpb24gU3RvcA0KICAgICAgICBJZiAoJD8pIHsNCiAgICAgICAgICAgICRJc0VuY3J5cHRlZCA9ICR0cnVlDQogICAgICAgIH0NCiAgICAgICAgTG9nd3JpdGUgKCdTdWNjZXNzIEVuYWJsaW5nIEJpdExvY2tlcj8gezB9JyAtZiAoJElzRW5jcnlwdGVkKSkNCiAgICB9IGVsc2Ugew0KICAgICAgICAkSXNFbmNyeXB0ZWQgPSAkdHJ1ZQ0KICAgIH0NCn0gDQpjYXRjaCB7DQogICAgTG9nRXJyb3JzDQogICAgRW5hYmxlLUJpdExvY2tlciAtTW91bnRQb2ludCAkT1NEcml2ZSAtVHBtUHJvdGVjdG9yIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgSWYgKCQ/KSB7DQogICAgICAgICRJc0VuY3J5cHRlZCA9ICR0cnVlDQogICAgfQ0KICAgIExvZ1dyaXRlICgnV2lsbCBhdHRlbXB0IHRvIEVuYWJsZSBCaXRMb2NrZXIgYW55d2F5IGFuZCB0aGVuIGNvbnRpbnVlLiBTdWNjZXNzPyB7MH0nIC1mICgkSXNFbmNyeXB0ZWQpKQ0KfQ0KDQoNCiMgQWRkIEJpdExvY2tlciBSZWNvdmVyeSBQYXNzd29yZCBpZiBub25lIGFyZSBwcmVzZW50DQpMb2dXcml0ZSAoJyMgUmVjb3ZlcnlQYXNzd29yZCcpDQpJZiAoJElzRW5jcnlwdGVkKSB7DQogICAgJEJpdExvY2tTdGF0dXMgPSBHZXQtQml0TG9ja2VyVm9sdW1lICRPU0RyaXZlDQogICAgJEtleVByb3RlY3RvclN0YXR1cyA9ICgkQml0TG9ja1N0YXR1cyB8IFNlbGVjdC1PYmplY3QgLVByb3BlcnR5IEtleVByb3RlY3RvcikuS2V5UHJvdGVjdG9yDQogICAgW1N5c3RlbS5Db2xsZWN0aW9ucy5BcnJheUxpc3RdICRTY3JpcHQ6QXJyYXlQcm90ZWN0aW9uUGFzc3dvcmRzID0gW1N5c3RlbS5Db2xsZWN0aW9ucy5BcnJheUxpc3RdOjpuZXcoKQ0KICAgIFt1aW50MTZdICRTY3JpcHQ6Q291bnRQcm90ZWN0aW9uS2V5cyA9IDANCg0KICAgICRLZXlQcm90ZWN0b3JTdGF0dXMgfCBGb3JFYWNoLU9iamVjdCB7DQogICAgICAgIElmICgkXy5LZXlQcm90ZWN0b3JUeXBlIC1lcSAnUmVjb3ZlcnlQYXNzd29yZCcpIHsNCiAgICAgICAgICAgICRTY3JpcHQ6Q291bnRQcm90ZWN0aW9uS2V5cyArPSAxDQogICAgICAgICAgICAkbnVsbCA9ICRTY3JpcHQ6QXJyYXlQcm90ZWN0aW9uUGFzc3dvcmRzLkFkZChbUFNDdXN0b21PYmplY3RdQHtLZXlQcm90ZWN0b3JJZCA9IFtTdHJpbmddJF8uS2V5UHJvdGVjdG9ySWQ7IFJlY292ZXJ5UGFzc3dvcmQgPSBbU3RyaW5nXSRfLlJlY292ZXJ5UGFzc3dvcmR9KQ0KICAgICAgICB9DQogICAgfQ0KDQoNCiAgICBJZiAoJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzIC1lcSAwKSB7DQogICAgICAgIExvZ1dyaXRlICgnTm8gUmVjb3ZlcnlQYXNzd29yZHMgZm91bmQgZm9yIE9TIERyaXZlIHswfSwgY3JlYXRpbmcgbmV3IG9uZS4nIC1mICRPU0RyaXZlKQ0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgIyRudWxsID0gRW5hYmxlLUJpdExvY2tlciAtTW91bnRQb2ludCAkT1NEcml2ZSAtUmVjb3ZlcnlQYXNzd29yZFByb3RlY3RvciAtRXJyb3JBY3Rpb24gU3RvcA0KICAgICAgICAgICAgJG51bGwgPSBBZGQtQml0TG9ja2VyS2V5UHJvdGVjdG9yIC1Nb3VudFBvaW50ICRPU0RyaXZlIC1SZWNvdmVyeVBhc3N3b3JkUHJvdGVjdG9yIC1FcnJvckFjdGlvbiBTdG9wIC1XYXJuaW5nQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgICAgIElmICgkPykgew0KICAgICAgICAgICAgICAgICRJc1Byb3RlY3Rpb25QYXNzdyA9ICR0cnVlDQogICAgICAgICAgICB9DQogICAgICAgICAgICBMb2dXcml0ZSAoJ0F0dGVtcHRpbmcgdG8gYWRkIFJlY292ZXJ5UGFzc3dvcmRQcm90ZWN0b3Igb24gT1MgRHJpdmUgKHswfSkuIFN1Y2Nlc3M/IHsxfS4nIC1mICgkT1NEcml2ZSwkSXNFbmNyeXB0ZWQpKSANCiAgICAgICAgfSBjYXRjaCB7DQogICAgICAgICAgICBMb2dFcnJvcnMNCiAgICAgICAgICAgICMkbnVsbCA9IEVuYWJsZS1CaXRMb2NrZXIgLU1vdW50UG9pbnQgJE9TRHJpdmUgLVJlY292ZXJ5UGFzc3dvcmRQcm90ZWN0b3IgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgICAgICRudWxsID0gQWRkLUJpdExvY2tlcktleVByb3RlY3RvciAtTW91bnRQb2ludCAkT1NEcml2ZSAtUmVjb3ZlcnlQYXNzd29yZFByb3RlY3RvciAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSAtV2FybmluZ0FjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgICAgICAgICBJZiAoJD8pIHsNCiAgICAgICAgICAgICAgICAkSXNQcm90ZWN0aW9uUGFzc3cgPSAkdHJ1ZQ0KICAgICAgICAgICAgfQ0KICAgICAgICAgICAgTG9nV3JpdGUgKCdXaWxsIGF0dGVtcHQgdG8gRW5hYmxlIEJpdExvY2tlciBSZWNvdmVyeVBhc3N3b3JkUHJvdGVjdG9yIGFueXdheSBhbmQgdGhlbiBjb250aW51ZS4gU3VjY2Vzcz8gezB9LicgLWYgKCRJc0VuY3J5cHRlZCkpDQogICAgICAgIH0NCg0KICAgICAgICAjIENvdW50IGtleShzKSBhbmQgbGlzdCB0aGVtIGlmIHN1Y2Nlc3MNCiAgICAgICAgSWYgKCRJc1Byb3RlY3Rpb25QYXNzdykgew0KICAgICAgICAgICAgJEJpdExvY2tTdGF0dXMgPSBHZXQtQml0TG9ja2VyVm9sdW1lICRPU0RyaXZlDQogICAgICAgICAgICAkS2V5UHJvdGVjdG9yU3RhdHVzID0gKCRCaXRMb2NrU3RhdHVzIHwgU2VsZWN0LU9iamVjdCAtUHJvcGVydHkgS2V5UHJvdGVjdG9yKS5LZXlQcm90ZWN0b3INCiAgICAgICAgICAgICRTY3JpcHQ6QXJyYXlQcm90ZWN0aW9uUGFzc3dvcmRzID0gW1N5c3RlbS5Db2xsZWN0aW9ucy5BcnJheUxpc3RdOjpuZXcoKQ0KICAgICAgICAgICAgJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzID0gMA0KDQogICAgICAgICAgICAkS2V5UHJvdGVjdG9yU3RhdHVzIHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICAgICAgICAgIElmICgkXy5LZXlQcm90ZWN0b3JUeXBlIC1lcSAnUmVjb3ZlcnlQYXNzd29yZCcpIHsNCiAgICAgICAgICAgICAgICAgICAgJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzICs9IDENCiAgICAgICAgICAgICAgICAgICAgJG51bGwgPSAkU2NyaXB0OkFycmF5UHJvdGVjdGlvblBhc3N3b3Jkcy5BZGQoW1BTQ3VzdG9tT2JqZWN0XUB7S2V5UHJvdGVjdG9ySWQgPSBbU3RyaW5nXSRfLktleVByb3RlY3RvcklkOyBSZWNvdmVyeVBhc3N3b3JkID0gW1N0cmluZ10kXy5SZWNvdmVyeVBhc3N3b3JkfSkNCiAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICB9DQogICAgICAgIH0gIA0KICAgIH0NCg0KICAgIEVsc2VJZiAoJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzIC1lcSAxKSB7DQogICAgICAgIExvZ1dyaXRlICgnUGVyZmVjdCwgdGhlcmUgYXJlIG9uZSBCaXRMb2NrZXIgUHJvdGVjdGlvbiBLZXkgcHJlc2VudCBhbHJlYWR5LicpDQogICAgICAgICRJc1Byb3RlY3Rpb25QYXNzdyA9ICR0cnVlDQogICAgDQogICAgfQ0KDQogICAgRWxzZSB7DQogICAgICAgICRJc1Byb3RlY3Rpb25QYXNzdyA9ICR0cnVlDQogICAgICAgIExvZ1dyaXRlICgnVGhlcmUgYXJlIGFscmVhZHkgezB9IFJlY292ZXJ5UGFzc3dvcmRzLCBubyBwb2ludCBpbiBjcmVhdGluZyBtb3JlJyAtZiAoJENvdW50UHJvdGVjdGlvbktleXMpKQ0KICAgICAgICBbdWludDE2XSAkSW50VGVtcENvdW50ZXIgPSAwDQogICAgICAgICRTY3JpcHQ6QXJyYXlQcm90ZWN0aW9uUGFzc3dvcmRzIHwgRm9yRWFjaC1PYmplY3QgeyBMb2dXcml0ZSAoJ3swfSB8IEtleVByb3RlY3RvcklkICJ7MX0iIHwgUmVjb3ZlcnlQYXNzd29yZCAiezJ9IjogJyAtZiAoKCRJbnRUZW1wQ291bnRlciArPSAxKSwkXy5LZXlQcm90ZWN0b3JJZCwkXy5SZWNvdmVyeVBhc3N3b3JkKSkgfQ0KICAgICAgICBMb2dXcml0ZSAoJ1JlbW92aW5nIGFsbCBidXQgdGhlIGZpcnN0IG9uZS4nKQ0KICAgICAgICAkU2NyaXB0OkFycmF5UHJvdGVjdGlvblBhc3N3b3JkcyB8IEZvckVhY2gtT2JqZWN0IHsgDQogICAgICAgICAgICBJZiAoJF8uS2V5UHJvdGVjdG9ySWQgLW5lICRTY3JpcHQ6QXJyYXlQcm90ZWN0aW9uUGFzc3dvcmRzWzBdLktleVByb3RlY3RvcklkKSB7DQogICAgICAgICAgICAgICAgJG51bGwgPSBSZW1vdmUtQml0TG9ja2VyS2V5UHJvdGVjdG9yIC1Nb3VudFBvaW50ICRPU0RyaXZlIC1LZXlQcm90ZWN0b3JJZCAkXy5LZXlQcm90ZWN0b3JJRA0KICAgICAgICAgICAgICAgIElmICgkPykgew0KICAgICAgICAgICAgICAgICAgICBMb2dXcml0ZSAoJ1N1Y2Nlc3NmdWxseSByZW1vdmVkIHwgS2V5UHJvdGVjdG9ySWQgInswfSIgfCBSZWNvdmVyeVBhc3N3b3JkICJ7MX0iJyAtZiAoJF8uS2V5UHJvdGVjdG9ySWQsJF8uUmVjb3ZlcnlQYXNzd29yZCkpDQogICAgICAgICAgICAgICAgfQ0KICAgICAgICAgICAgfQ0KICAgICAgICAgICAgRWxzZSB7DQogICAgICAgICAgICAgICAgTG9nV3JpdGUgKCdTdWNjZXNzZnVsbHkgc2tpcHBlZCB0aGUgZmlyc3Qga2V5LiB8IEtleVByb3RlY3RvcklkICJ7MH0iIHwgUmVjb3ZlcnlQYXNzd29yZCAiezF9IicgLWYgKCRfLktleVByb3RlY3RvcklkLCRfLlJlY292ZXJ5UGFzc3dvcmQpKQ0KICAgICAgICAgICAgfQ0KICAgICAgICB9DQogICAgICAgIExvZ1dyaXRlICdDaGVjayBpZiBzdWNjZXNzLCBBS0Egb25seSBvbmUgUHJvdGVjdGlvblBhc3N3b3JkLicNCiAgICAgICAgJEJpdExvY2tTdGF0dXMgPSBHZXQtQml0TG9ja2VyVm9sdW1lICRPU0RyaXZlDQogICAgICAgICRLZXlQcm90ZWN0b3JTdGF0dXMgPSAoJEJpdExvY2tTdGF0dXMgfCBTZWxlY3QtT2JqZWN0IC1Qcm9wZXJ0eSBLZXlQcm90ZWN0b3IpLktleVByb3RlY3Rvcg0KICAgICAgICAkU2NyaXB0OkFycmF5UHJvdGVjdGlvblBhc3N3b3JkcyA9IFtTeXN0ZW0uQ29sbGVjdGlvbnMuQXJyYXlMaXN0XTo6bmV3KCkNCiAgICAgICAgJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzID0gMA0KDQogICAgICAgICRLZXlQcm90ZWN0b3JTdGF0dXMgfCBGb3JFYWNoLU9iamVjdCB7DQogICAgICAgICAgICBJZiAoJF8uS2V5UHJvdGVjdG9yVHlwZSAtZXEgJ1JlY292ZXJ5UGFzc3dvcmQnKSB7DQogICAgICAgICAgICAgICAgJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzICs9IDENCiAgICAgICAgICAgICAgICAkbnVsbCA9ICRTY3JpcHQ6QXJyYXlQcm90ZWN0aW9uUGFzc3dvcmRzLkFkZChbUFNDdXN0b21PYmplY3RdQHtLZXlQcm90ZWN0b3JJZCA9IFtTdHJpbmddJF8uS2V5UHJvdGVjdG9ySWQ7IFJlY292ZXJ5UGFzc3dvcmQgPSBbU3RyaW5nXSRfLlJlY292ZXJ5UGFzc3dvcmR9KQ0KICAgICAgICAgICAgfQ0KICAgICAgICB9DQogICAgICAgIElmICgkU2NyaXB0OkNvdW50UHJvdGVjdGlvbktleXMgLWVxIDEpIHsNCiAgICAgICAgICAgIExvZ1dyaXRlICgnU1VDQ0VTUywga2V5cyBsZWZ0OiAxLicpDQogICAgICAgIH0NCiAgICAgICAgRWxzZSB7DQogICAgICAgICAgICBMb2dXcml0ZSAnRkFJTCwga2V5cyBsZWZ0OiB7MH0uJyAtZiAoJFNjcmlwdDpBcnJheVByb3RlY3Rpb25QYXNzd29yZHMuQ291bnQpDQogICAgICAgICAgICAkSXNQcm90ZWN0aW9uUGFzc3cgPSAkZmFsc2UNCiAgICAgICAgfQ0KICAgIH0NCg0KICAgICMgT3V0cHV0IHRoZSBvbmUga2V5IHRoYXRzIGhvcGVmdWxseSBsZWZ0ICAgICAgICANCiAgICBMb2dXcml0ZSAoJ1N0YXR1czogezB9IGtleShzKSBwcmVzZW50OicgLWYgKCRHbG9iYWw6Q291bnRQcm90ZWN0aW9uS2V5cykpDQogICAgTG9nV3JpdGUgKCdLZXlQcm90ZWN0b3JJZCAiezB9IiB8IFJlY292ZXJ5UGFzc3dvcmQgInsxfSIuJyAtZiAoJFNjcmlwdDpBcnJheVByb3RlY3Rpb25QYXNzd29yZHNbMF0uS2V5UHJvdGVjdG9ySWQsJFNjcmlwdDpBcnJheVByb3RlY3Rpb25QYXNzd29yZHNbMF0uUmVjb3ZlcnlQYXNzd29yZCkpICAgICAgICAgDQp9DQoNCg0KRWxzZSB7DQogICAgTG9nV3JpdGUgKCdPUyBEcml2ZSBpcyBub3QgZW5jcnlwdGVkLCB0aGVyZWZvcmUgQml0TG9ja2VyIFJlY292ZXJ5UGFzc3dvcmQgY2FuIG5vdCBiZSBhZGRlZCcpDQogICAgJElzUHJvdGVjdGlvblBhc3N3ID0gJGZhbHNlDQp9DQoNCg0KDQojIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyMjIyMjIEJBQ0tVUCAjIyMjIyMNCiMjIyMjIyMjIyMjIyMjIyMjIyMjDQojIEJhY2t1cCBCaXRMb2NrZXIgS2V5IHRvIE9uZURyaXZlIGFuZCBBenVyZUFEDQpMb2dXcml0ZSAoJyMjIyBCYWNrdXAgUHJvdGVjdGlvbiBQYXNzd29yZCcpDQojIENoZWNrIHdoYXRoZXIgT1NEcml2ZSBpcyBlbmNyeXB0ZWQgYW5kIGlmIFByb3RlY3Rpb24gUGFzc3dvcmQocykgZXhpc3QNCklmICgkSXNFbmNyeXB0ZWQgLWFuZCAkSXNQcm90ZWN0aW9uUGFzc3cpIHsNCiAgICBMb2dXcml0ZSAoJ09TIERyaXZlIGlzIGVuY3J5cHRlZCwgYW5kIHRoZXJlIGFyZSB7MH0gUHJvdGVjdGlvblBhc3N3b3JkKHMpIHByZXNlbnQuIENvbnRpbnVpbmcgd2l0aCBiYWNrdXAuJyAtZiAoJFNjcmlwdDpDb3VudFByb3RlY3Rpb25LZXlzKSkNCiAgICBMb2dXcml0ZSAoJ1dpbGwgb25seSBiYWNrdXAgMSBwYXNzd29yZCB0byBBenVyZSwgYWxsIHByZXNlbnQgcGFzc3dvcmRzIHRvIE9uZURyaXZlJykNCiAgICAjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMNCiAgICAjIE9uZURyaXZlIGZvciBCdXNpbmVzcyBiYWNrdXANCiAgICAjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMNCiAgICBMb2dXcml0ZSAoJyMgQmFja3VwIHRvIE9uZURyaXZlJykNCiAgICB0cnkgew0KICAgICAgICAjV3JpdGluZyBWYWx1ZSB0byBPbmVEcml2ZSBmaXJzdCANCiAgICAgICAgJHJlZ1ZhbHVlcyA9IEdldC1DaGlsZEl0ZW0gJ0hLQ1U6XFNPRlRXQVJFXE1pY3Jvc29mdFxPbmVEcml2ZVxBY2NvdW50c1wnDQogICAgICAgIEZvckVhY2ggKCRyZWdWYWx1ZSBpbiAkcmVnVmFsdWVzKSB7DQogICAgICAgICAgICBbU3RyaW5nXSAkTG9jYWw6T0Q0QkFjY1R5cGUgPSBbU3RyaW5nW11dICgoKCRyZWdWYWx1ZSB8IFNlbGVjdC1PYmplY3QgTmFtZSkuTmFtZSkuU3BsaXQoJ3tcfScpWy0xXSkNCiAgICAgICAgICAgIElmICgkTG9jYWw6T0Q0QkFjY1R5cGUgLWxpa2UgJ0J1c2luZXNzKicpIHsNCiAgICAgICAgICAgICAgICBMb2dXcml0ZSAoJ0ZvdW5kIGEgT25lRHJpdmUgZm9yIEJ1c2luZXNzIGFjY291bnQnKQ0KICAgICAgICAgICAgICAgICRMb2NhbDpLZXkgPSAkcmVnVmFsdWUubmFtZS5SZXBsYWNlKCdIS0VZX0NVUlJFTlRfVVNFUicsICdoa2N1OicpICAgICAgICAgICAgICANCiAgICAgICAgICAgICAgICBbU3RyaW5nXSAkTG9jYWw6T0Q0QlBhdGggPSAoR2V0LUl0ZW1Qcm9wZXJ0eSAtUGF0aCAkTG9jYWw6S2V5IC1OYW1lIFVzZXJGb2xkZXIpLlVzZXJGb2xkZXINCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgDQogICAgICAgICAgICAgICAgSWYgKCgtbm90KCRMb2NhbDpPRDRCUGF0aCAtbGlrZSAoJE9TRHJpdmUgKyAnXFVzZXJzXCpcT25lRHJpdmUgLSonKSkpIC1hbmQgKFRlc3QtUGF0aCAkTG9jYWw6T0Q0QlBhdGgpKSB7DQogICAgICAgICAgICAgICAgICAgIExvZ1dyaXRlICgnRmFpbGVkIHRvIGJ1aWxkIE9uZURyaXZlIHBhdGg6ICJ7MH0iLCBvciBpdCBkb2VzIG5vdCBleGlzdC4nIC1mICRMb2NhbDpQYXRoKQ0KICAgICAgICAgICAgICAgICAgICAkSXNCYWNrdXBPRCA9ICRmYWxzZQ0KICAgICAgICAgICAgICAgICAgICAjW1N0cmluZ10gJExvY2FsOlBhdGggPSAoJGVudjpTeXN0ZW1Ecml2ZSArICRlbnY6SE9NRVBBVEggKyAnT25lRHJpdmUgLSAnICsgJ1xCaXRMb2NrZXIgUmVjb3ZlcnlcJyArICRlbnY6Q09NUFVURVJOQU1FICsgJ1wnICkNCiAgICAgICAgICAgICAgICB9IEVsc2UgeyAgICAgICAgICAgICAgICANCiAgICAgICAgICAgICAgICAgICAgW1N0cmluZ10gJExvY2FsOk9ENEJCYWNrdXBQYXRoID0gKCRMb2NhbDpPRDRCUGF0aCArICdcQml0TG9ja2VyIFJlY292ZXJ5XCcgKyAkZW52OkNPTVBVVEVSTkFNRSArICdcJykNCiAgICAgICAgICAgICAgICAgICAgTG9nV3JpdGUgKCdPbmVEcml2ZSBmb3IgQnVzaW5lc3MgcGF0aDogezB9JyAtZiAoJExvY2FsOk9ENEJQYXRoKSkNCiAgICAgICAgICAgICAgICAgICAgTG9nV3JpdGUgKCdSZXN0b3JlIHBhc3N3b3JkIHBhdGg6IHswfScgLWYgKCRMb2NhbDpPRDRCQmFja3VwUGF0aCkpIA0KICAgICAgICAgICAgICAgICAgICAjVGVzdGluZyBpZiBSZWNvdmVyeSBmb2xkZXIgZXhpc3RzIGlmIG5vdCBjcmVhdGUgb25lDQogICAgICAgICAgICAgICAgICAgIExvZ1dyaXRlICgnVGVzdGluZyBpZiBiYWNrdXAgZm9sZGVyIGV4aXN0cywgY3JlYXRlIGl0IGlmIG5vdC4nKQ0KICAgICAgICAgICAgICAgICAgICBpZiAoIShUZXN0LVBhdGggJExvY2FsOlBhdGgpKSB7DQogICAgICAgICAgICAgICAgICAgICAgICAkbnVsbCA9IE5ldy1JdGVtIC1JdGVtVHlwZSBEaXJlY3RvcnkgLUZvcmNlIC1QYXRoICRMb2NhbDpQYXRoDQogICAgICAgICAgICAgICAgICAgICAgICBJZiAoJD8pIHsNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBMb2dXcml0ZSAnU3VjY2VzcyBjcmVhdGluZyBPbmVEcml2ZSBmb3IgQnVzaW5lc3MgZm9sZGVyIGZvciBiYWNrdXAnDQogICAgICAgICAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICAgICAgICAgIH0NCiAgICAgICAgICAgICAgICAgICAgRWxzZSB7DQogICAgICAgICAgICAgICAgICAgICAgICBMb2dXcml0ZSAoJ0JhY2t1cCBmb2xkZXIgYWxyZWFkeSBleGlzdHMnKQ0KICAgICAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICAgICAgDQogICAgICAgICAgICAgICAgICAgICMgQ3JlYXRlIHN0cmluZyBmb3IgQml0TG9ja2VyUmVjb3ZlcnlQYXNzd29yZC50eHQNCiAgICAgICAgICAgICAgICAgICAgW1N0cmluZ10gJExvY2FsOlN0clJlY1Bhc3MgPSAoJ1RoZXJlIGFyZSB7MH0gUmVjb3ZlcnlQYXNzd29yZChzKTonIC1mICgkQ291bnRQcm90ZWN0aW9uS2V5cykpDQogICAgICAgICAgICAgICAgICAgIFt1aW50MTZdICRJbnRUZW1wQ291bnRlciA9IDANCiAgICAgICAgICAgICAgICAgICAgJFNjcmlwdDpBcnJheVByb3RlY3Rpb25QYXNzd29yZHMgfCBGb3JFYWNoLU9iamVjdCB7DQogICAgICAgICAgICAgICAgICAgICAgICAkTG9jYWw6U3RyUmVjUGFzcyArPSAoImByYG4iICsgJ3swfSB8IEtleVByb3RlY3RvcklkICJ7MX0iIHwgUmVjb3ZlcnlQYXNzd29yZCAiezJ9IjogJyAtZiAoKCRJbnRUZW1wQ291bnRlciArPSAxKSwkXy5LZXlQcm90ZWN0b3JJZCwkXy5SZWNvdmVyeVBhc3N3b3JkKSkNCiAgICAgICAgICAgICAgICAgICAgfQ0KDQogICAgICAgICAgICAgICAgICAgICMgT3V0RmlsZSB0aGUgc3RyaW5nDQogICAgICAgICAgICAgICAgICAgIE91dC1GaWxlIC1GaWxlUGF0aCAoJExvY2FsOlBhdGggKyAnQml0bG9ja2VyUmVjb3ZlcnlQYXNzd29yZC50eHQnKSAtRW5jb2RpbmcgdXRmOCAtRm9yY2UgLUlucHV0T2JqZWN0ICgkTG9jYWw6U3RyUmVjUGFzcykNCiAgICAgICAgICAgICAgICAgICAgSWYgKCQ/KSB7DQogICAgICAgICAgICAgICAgICAgICAgICAkSXNCYWNrdXBPRCA9ICR0cnVlDQogICAgICAgICAgICAgICAgICAgIH0NCiAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICB9DQogICAgICAgIH0NCiAgICB9DQogICAgQ2F0Y2ggew0KICAgICAgICBMb2dXcml0ZSAoJ0Vycm9yIHdoaWxlIGJhY2t1cCB0byBPbmVEcml2ZSwgbWFrZSBzdXJlIHRoYXQgeW91IGFyZSBBQUQgam9pbmVkIGFuZCBhcmUgcnVubmluZyB0aGUgY21kbGV0IGFzIGFuIGFkbWluLicpDQogICAgICAgIExvZ1dyaXRlICgnRXJyb3IgbWVzc2FnZTonICsgImByYG4iICsgKCRfKSkNCiAgICB9DQogICAgRmluYWxseSB7DQogICAgICAgIExvZ1dyaXRlICgnRGlkIGJhY2t1cCB0byBPbmVEcml2ZSBzdWNjZWVkPyB7MH0nIC1mICgkSXNCYWNrdXBPRCkpDQogICAgfQ0KICAgIA0KICAgICMjIyMjIyMjIyMjIyMjIyMjDQogICAgIyBBenVyZSBBRCBCYWNrdXANCiAgICAjIyMjIyMjIyMjIyMjIyMjIw0KICAgIExvZ1dyaXRlICgnIyBCYWNrdXAgdG8gQXp1cmUgQUQnKSAgICAgICAgICAgDQogICAgI0NoZWNrIGlmIHdlIGNhbiB1c2UgQmFja3VwVG9BQUQtQml0TG9ja2VyS2V5UHJvdGVjdG9yIGNvbW1hbmRsZXQNCiAgICB0cnkgew0KICAgICAgICBMb2dXcml0ZSAnQ2hlY2sgaWYgd2UgY2FuIHVzZSBCYWNrdXBUb0FBRC1CaXRMb2NrZXJLZXlQcm90ZWN0b3IgY29tbWFuZGxldC4uLicNCiAgICAgICAgJGNtZE5hbWUgPSAnQmFja3VwVG9BQUQtQml0TG9ja2VyS2V5UHJvdGVjdG9yJw0KICAgICAgICBpZiAoR2V0LUNvbW1hbmQgJGNtZE5hbWUgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUpIHsNCiAgICAgICAgICAgICNCYWNrdXBUb0FBRC1CaXRMb2NrZXJLZXlQcm90ZWN0b3IgY29tbWFuZGxldCBleGlzdHMNCiAgICAgICAgICAgIExvZ1dyaXRlICgnezB9IGNvbW1hbmRsZXQgZXhpc3RzIScgLWYgJGNtZE5hbWUpDQogICAgICAgICAgICAkQkxWID0gR2V0LUJpdExvY2tlclZvbHVtZSAtTW91bnRQb2ludCAkT1NEcml2ZQ0KICAgICAgICAgICAgJG51bGwgPSBCYWNrdXBUb0FBRC1CaXRMb2NrZXJLZXlQcm90ZWN0b3IgLU1vdW50UG9pbnQgJE9TRHJpdmUgLUtleVByb3RlY3RvcklkICRCTFYuS2V5UHJvdGVjdG9yWzBdLktleVByb3RlY3RvcklkDQogICAgICAgICAgICBJZiAoJD8pIHsNCiAgICAgICAgICAgICAgICAkSXNCYWNrdXBBQUQgPSAkdHJ1ZQ0KICAgICAgICAgICAgfQ0KICAgICAgICAgICAgTG9nV3JpdGUgKCdTdWNjZXNzPyB7MH0nIC1mICgkSXNCYWNrdXBBQUQpKQ0KICAgICAgICB9IA0KICAgICAgICBlbHNlIHsgDQogICAgICAgICAgICAjIEJhY2t1cFRvQUFELUJpdExvY2tlcktleVByb3RlY3RvciBjb21tYW5kbGV0IG5vdCBhdmFpbGFibGUsIHVzaW5nIG90aGVyIG1lY2hhbmlzbSANCiAgICAgICAgICAgIExvZ1dyaXRlICdCYWNrdXBUb0FBRC1CaXRMb2NrZXJLZXlQcm90ZWN0b3IgY29tbWFuZGxldCBub3QgYXZhaWxhYmxlLCB1c2luZyBvdGhlciBtZWNoYW5pc20uJyANCiAgICAgICAgICAgICMgR2V0IHRoZSBBQUQgTWFjaGluZSBDZXJ0aWZpY2F0ZQ0KICAgICAgICAgICAgJGNlcnQgPSBHZXQtQ2hpbGRJdGVtIENlcnQ6XExvY2FsTWFjaGluZVxNeVwgfCBXaGVyZS1PYmplY3QgeyAkXy5Jc3N1ZXIgLW1hdGNoICdDTj1NUy1Pcmdhbml6YXRpb24tQWNjZXNzJyB9DQoNCiAgICAgICAgICAgICMgT2J0YWluIHRoZSBBQUQgRGV2aWNlIElEIGZyb20gdGhlIGNlcnRpZmljYXRlDQogICAgICAgICAgICAkaWQgPSAkY2VydC5TdWJqZWN0LlJlcGxhY2UoJ0NOPScsJycpDQoNCiAgICAgICAgICAgICMgR2V0IHRoZSB0ZW5hbnQgbmFtZSBmcm9tIHRoZSByZWdpc3RyeQ0KICAgICAgICAgICAgJHRlbmFudCA9IChHZXQtSXRlbVByb3BlcnR5IEhLTE06XFNZU1RFTVxDdXJyZW50Q29udHJvbFNldFxDb250cm9sXENsb3VkRG9tYWluSm9pblxKb2luSW5mb1wkKCRpZCkpLlVzZXJFbWFpbC5TcGxpdCgnQCcpWzFdDQogICAgICAgICAgICBMb2dXcml0ZSAkdGVuYW50DQogICAgICAgICAgICAjIEdlbmVyYXRlIHRoZSBib2R5IHRvIHNlbmQgdG8gQUFEIGNvbnRhaW5pbmcgdGhlIHJlY292ZXJ5IGluZm9ybWF0aW9uDQogICAgICAgICAgICAjIEdldCB0aGUgQml0TG9ja2VyIGtleSBpbmZvcm1hdGlvbiBmcm9tIFdNSQ0KICAgICAgICAgICAgKEdldC1CaXRMb2NrZXJWb2x1bWUgLU1vdW50UG9pbnQgJE9TRHJpdmUpLktleVByb3RlY3Rvcnw/IHskXy5LZXlQcm90ZWN0b3JUeXBlIC1lcSAnUmVjb3ZlcnlQYXNzd29yZCd9fCAlIHsNCiAgICAgICAgICAgICAgICAka2V5ID0gJF8NCiAgICAgICAgICAgICAgICB3cml0ZS12ZXJib3NlICJraWQgOiAkKCRrZXkuS2V5UHJvdGVjdG9ySWQpIGtleTogJCgka2V5LlJlY292ZXJ5UGFzc3dvcmQpIg0KICAgICAgICAgICAgICAgICRib2R5ID0gInsiImtleSIiOiIiJCgka2V5LlJlY292ZXJ5UGFzc3dvcmQpIiIsIiJraWQiIjoiIiQoJGtleS5LZXlQcm90ZWN0b3JJZC5yZXBsYWNlKCd7JywnJykuUmVwbGFjZSgnfScsJycpKSIiLCIidm9sIiI6IiJPU1YiIn0iDQogICAgICAgICAgICAgICAgICAgIA0KICAgICAgICAgICAgICAgICMgQ3JlYXRlIHRoZSBVUkwgdG8gcG9zdCB0aGUgZGF0YSB0byBiYXNlZCBvbiB0aGUgdGVuYW50IGFuZCBkZXZpY2UgaW5mb3JtYXRpb24NCiAgICAgICAgICAgICAgICAkdXJsID0gImh0dHBzOi8vZW50ZXJwcmlzZXJlZ2lzdHJhdGlvbi53aW5kb3dzLm5ldC9tYW5hZ2UvJHRlbmFudC9kZXZpY2UvJCgkaWQpP2FwaS12ZXJzaW9uPTEuMCINCiAgICAgICAgICAgICAgICBMb2dzdHJpbmcgIkNyZWF0aW5nIHVybC4uLiR1cmwiDQogICAgICAgICAgICAgICAgICAgIA0KICAgICAgICAgICAgICAgICMgUG9zdCB0aGUgZGF0YSB0byB0aGUgVVJMIGFuZCBzaWduIGl0IHdpdGggdGhlIEFBRCBNYWNoaW5lIENlcnRpZmljYXRlDQogICAgICAgICAgICAgICAgJHJlcSA9IEludm9rZS1XZWJSZXF1ZXN0IC1VcmkgJHVybCAtQm9keSAkYm9keSAtVXNlQmFzaWNQYXJzaW5nIC1NZXRob2QgUG9zdCAtVXNlRGVmYXVsdENyZWRlbnRpYWxzIC1DZXJ0aWZpY2F0ZSAkY2VydA0KICAgICAgICAgICAgICAgICRyZXEuUmF3Q29udGVudA0KICAgICAgICAgICAgICAgIElmICgkPykgew0KICAgICAgICAgICAgICAgICAgICAkSXNCYWNrdXBBQUQgPSAkdHJ1ZQ0KICAgICAgICAgICAgICAgIH0gICAgDQogICAgICAgICAgICAgICAgTG9nU3RyaW5nICgnUG9zdCB0aGUgZGF0YSB0byB0aGUgVVJMIGFuZCBzaWduIGl0IHdpdGggdGhlIEFBRCBNYWNoaW5lIENlcnRpZmljYXRlLiBTdWNjZXNzPyB7MH0nIC1mICgkSXNCYWNrdXBBQUQpKQ0KICAgICAgICAgICAgfQ0KICAgICAgICB9IA0KICAgIH0NCiAgICBjYXRjaCB7DQogICAgICAgIExvZ1dyaXRlICgnRXJyb3Igd2hpbGUgYmFja3VwIHRvIEF6dXJlIEFELCBtYWtlIHN1cmUgdGhhdCB5b3UgYXJlIEFBRCBqb2luZWQgYW5kIGFyZSBydW5uaW5nIHRoZSBjbWRsZXQgYXMgYW4gYWRtaW4uJykNCiAgICAgICAgTG9nV3JpdGUgKCdFcnJvciBtZXNzYWdlOicgKyAiYHJgbiIgKyAoJF8pKQ0KICAgIH0NCiAgICBGaW5hbGx5IHsNCiAgICAgICAgTG9nV3JpdGUgKCdEaWQgYmFja3VwIHRvIEF6dXJlIEFEIFN1Y2NlZWQ/IHswfScgLWYgKCRJc0JhY2t1cEFBRCkpDQogICAgfQ0KDQp9IA0KZWxzZSB7DQogICAgTG9nV3JpdGUgKCdEcml2ZSBpcyBub3QgZW5jcnlwdGVkIGFuZC9vciBubyBQcm90ZWN0aW9uIFBhc3N3b3JkKHMpIHByZXNlbnQuJykNCiAgICBMb2dXcml0ZSAoJ1dpbGwgc2tpcCBiYWNrdXAsIGZvciBub3cuJykNCn0NCg0KDQojIyMjIyMjIyMjIyMjIyMjIyMjIw0KIyMjIyMjICBHIFUgSSAjIyMjIyMNCiMjIyMjIyMjIyMjIyMjIyMjIyMjDQojcmVnaW9uIEdVSQ0KSWYgKCRJc0VuY3J5cHRlZCAtYW5kICRJc1Byb3RlY3Rpb25QYXNzdyAtYW5kICRHVUkpIHsNCiAgICAjIFNob3cgcmVib290IHByb21wdCB0byB1c2VyDQogICAgTG9nV3JpdGUgIlByb21wdGluZyB1c2VyIHRvIFJlYm9vdCBjb21wdXRlci4iDQogICAgICAgICAgIA0KDQogICAgW3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgg4oCcU3lzdGVtLldpbmRvd3MuRm9ybXPigJ0pDQogICAgW3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgg4oCcTWljcm9zb2Z0LlZpc3VhbEJhc2lj4oCdKQ0KDQogICAgJGZvcm0gPSBOZXctT2JqZWN0IOKAnFN5c3RlbS5XaW5kb3dzLkZvcm1zLkZvcm3igJ07DQogICAgJGZvcm0uV2lkdGggPSA1MDA7DQogICAgJGZvcm0uSGVpZ2h0ID0gMTUwOw0KICAgICRmb3JtLlRleHQgPSAiQml0TG9ja2VyIHJlcXVpcmVzIGEgcmVib290ICEiOw0KICAgICRmb3JtLlN0YXJ0UG9zaXRpb24gPSBbU3lzdGVtLldpbmRvd3MuRm9ybXMuRm9ybVN0YXJ0UG9zaXRpb25dOjpDZW50ZXJTY3JlZW47DQoNCiAgICAkRHJvcERvd25BcnJheSA9IEAoIjQ6SG91cnMiLCAiODpIb3VycyIsICIxMjpIb3VycyIsICIyNDpIb3VycyIpDQogICAgJERETCA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuQ29tYm9Cb3gNCiAgICAkRERMLkxvY2F0aW9uID0gTmV3LU9iamVjdCBTeXN0ZW0uRHJhd2luZy5TaXplKDE0MCwgMTApDQogICAgJERETC5TaXplID0gTmV3LU9iamVjdCBTeXN0ZW0uRHJhd2luZy5TaXplKDEzMCwgMzApDQogICAgRm9yRWFjaCAoJEl0ZW0gaW4gJERyb3BEb3duQXJyYXkpIHsNCiAgICAgICAgJERETC5JdGVtcy5BZGQoJEl0ZW0pIHwgT3V0LU51bGwNCiAgICB9DQogICAgJERETC5TZWxlY3RlZEluZGV4ID0gMA0KDQogICAgJGJ1dHRvbjEgPSBOZXctT2JqZWN0IOKAnFN5c3RlbS5XaW5kb3dzLkZvcm1zLmJ1dHRvbuKAnTsNCiAgICAkYnV0dG9uMS5MZWZ0ID0gNDA7DQogICAgJGJ1dHRvbjEuVG9wID0gODU7DQogICAgJGJ1dHRvbjEuV2lkdGggPSAxMDA7DQogICAgJGJ1dHRvbjEuVGV4dCA9IOKAnFJlYm9vdCBOb3figJ07DQogICAgJGJ1dHRvbjEuQWRkX0NsaWNrKCB7JGdsb2JhbDp4aW5wdXQgPSAiUmVib290IjsgJEZvcm0uQ2xvc2UoKX0pDQoNCiAgICAkYnV0dG9uMiA9IE5ldy1PYmplY3Qg4oCcU3lzdGVtLldpbmRvd3MuRm9ybXMuYnV0dG9u4oCdOw0KICAgICRidXR0b24yLkxlZnQgPSAxNzA7DQogICAgJGJ1dHRvbjIuVG9wID0gODU7DQogICAgJGJ1dHRvbjIuV2lkdGggPSAxMDA7DQogICAgJGJ1dHRvbjIuVGV4dCA9IOKAnFBvc3Rwb25l4oCdOw0KICAgICRidXR0b24yLkFkZF9DbGljayggeyRnbG9iYWw6eGlucHV0ID0gIlBvc3Rwb25lOiIgKyAkRERMLlRleHQ7ICRGb3JtLkNsb3NlKCl9KQ0KDQogICAgJGJ1dHRvbjMgPSBOZXctT2JqZWN0IOKAnFN5c3RlbS5XaW5kb3dzLkZvcm1zLmJ1dHRvbuKAnTsNCiAgICAkYnV0dG9uMy5MZWZ0ID0gMjkwOw0KICAgICRidXR0b24zLlRvcCA9IDg1Ow0KICAgICRidXR0b24zLldpZHRoID0gMTAwOw0KICAgICRidXR0b24zLlRleHQgPSDigJxDYW5jZWzigJ07DQogICAgJGJ1dHRvbjMuQWRkX0NsaWNrKCB7JGdsb2JhbDp4aW5wdXQgPSAiUG9zdHBvbmUyNCI7ICRGb3JtLkNsb3NlKCl9KQ0KDQoNCiAgICAkZm9ybS5LZXlQcmV2aWV3ID0gJFRydWUNCiAgICAkZm9ybS5BZGRfS2V5RG93bigge2lmICgkXy5LZXlDb2RlIC1lcSAiRW50ZXIiKSANCiAgICAgICAgICAgIHskeCA9ICR0ZXh0Qm94MS5UZXh0OyAkZm9ybS5DbG9zZSgpfX0pDQogICAgJGZvcm0uQWRkX0tleURvd24oIHtpZiAoJF8uS2V5Q29kZSAtZXEgIkVzY2FwZSIpIA0KICAgICAgICAgICAgeyRmb3JtLkNsb3NlKCl9fSkNCg0KDQoNCiAgICAkZXZlbnRIYW5kbGVyID0gW1N5c3RlbS5FdmVudEhhbmRsZXJdIHsgDQogICAgICAgICRidXR0b24xLkNsaWNrOw0KICAgICAgICAkRHJvcERvd25BcnJheS5UZXh0Ow0KICAgICAgICAkZm9ybS5DbG9zZSgpOyB9Ow0KDQogICAgIyRidXR0b24uQWRkX0NsaWNrKCRldmVudEhhbmRsZXIpIDsNCiAgICAkZm9ybS5Db250cm9scy5BZGQoJGJ1dHRvbjEpOw0KICAgICRmb3JtLkNvbnRyb2xzLkFkZCgkYnV0dG9uMik7DQogICAgJGZvcm0uQ29udHJvbHMuQWRkKCRidXR0b24zKTsNCiAgICAkZm9ybS5Db250cm9scy5BZGQoJERETCk7DQogICAgJGZvcm0uQ29udHJvbHMuQWRkKCR0ZXh0TGFiZWwxKQ0KICAgICRyZXQgPSAkZm9ybS5TaG93RGlhbG9nKCk7DQoNCiAgICBpZiAoJGdsb2JhbDp4aW5wdXQgLWVxICJSZWJvb3QiKSB7c2h1dGRvd24gLXIgLWYgL3QgNjAwfQ0KICAgIGlmICgkZ2xvYmFsOnhpbnB1dCAtbGlrZSAiUG9zdHBvbmU6KjpIb3VycyIpIHsNCiAgICAgICAgJGh2YWwgPSAoKFtpbnRdJGdsb2JhbDp4aW5wdXQuc3BsaXQoIjoiKVsxXSkgKiA2MCAqIDYwKQ0KICAgICAgICBzaHV0ZG93biAtciAtZiAvdCAkaHZhbA0KICAgIH0NCiAgICBpZiAoJGdsb2JhbDp4aW5wdXQgLWVxICJQb3N0cG9uZTI0Iikge3NodXRkb3duIC1yIC1mIC90IDg2NDAwfQ0KfQ0KI2VuZHJlZ2lvbiBHVUkNCg0KDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMNCiMjIyMgRU5EIFJFU1VMVCAjIyMjDQojIyMjIyMjIyMjIyMjIyMjIyMjIw0KTG9nV3JpdGUgKCcjIyMgRW5kIHJlc3VsdHMnKQ0KTG9nV3JpdGUgKCdTdWNjZXNzIHN0YXR1cyB8IEVuY3J5cHRlZCA6IHswfSB8IFByb3RlY3Rpb24gUGFzc3dvcmRzIHByZXNlbnQgOiB7MX0gfCBCYWNrdXAgdG8gT25lRHJpdmUgOiB7Mn0gfCBCYWNrdXAgdG8gQXp1cmVBRCA6IHszfScgLWYgKCRJc0VuY3J5cHRlZCwkSXNQcm90ZWN0aW9uUGFzc3csJElzQmFja3VwQUFELCRJc0JhY2t1cE9EKSkNCiMgQ2xlYW5pbmcgdXAgaWYgc3VjY2Vzcw0KSWYgKCRJc0VuY3J5cHRlZCAtYW5kICRJc1Byb3RlY3Rpb25QYXNzdyAtYW5kICRJc0JhY2t1cEFBRCAtYW5kICRJc0JhY2t1cE9EKSB7DQogICAgTG9nV3JpdGUgJ1JlbW92aW5nIHRoZSBTY2hlZHVsZWQgdGFzayBhbmQgZmlsZXMuJw0KICAgICMgU2NoZWR1bGVkIFRhc2sNCiAgICBJZiAoR2V0LVNjaGVkdWxlZFRhc2sgLVRhc2tOYW1lICRTY3JpcHQ6U2NoZWR1bGVkVGFza05hbWUgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUpIHsNCiAgICAgICAgJG51bGwgPSBVbnJlZ2lzdGVyLVNjaGVkdWxlZFRhc2sgLVRhc2tOYW1lICRTY3JpcHQ6U2NoZWR1bGVkVGFza05hbWUgLUNvbmZpcm06JGZhbHNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgICAgIExvZ1dyaXRlICgnUmVtb3ZpbmcgdGhlIFNjaGVkdWxlZCB0YXNrICJ7MH0iLiBTdWNjZXNzPyB7MX0nIC1mICgkU2NyaXB0OlNjaGVkdWxlZFRhc2tOYW1lLCQ/KSkNCiAgICB9DQogICAgRWxzZSB7DQogICAgICAgIExvZ1dyaXRlICgnU2NoZWR1bGVkIHRhc2sgInswfSIgZG9lcyBub3QgZXhpc3QuJyAtZiAoJFNjcmlwdDpTY2hlZHVsZWRUYXNrTmFtZSkpDQogICAgfQ0KICAgICMgRmlsZXMNCiAgICAjUmVtb3ZlLUl0ZW0gLVJlY3Vyc2UgLUZvcmNlICgke2VudjpQcm9ncmFtRmlsZXMoeDg2KX0gKyAnXEJpdExvY2tlclRyaWdnZXInKQ0KICAgICNMb2dXcml0ZSAoJyBSZW1vdmluZyB0aGUgZmlsZXMuIFN1Y2Nlc3M/IHswfScgLWYgKCQ/KSkNCn0NCkVsc2Ugew0KICAgIExvZ1dyaXRlICdGYWlsLCBzb21ldGhpbmcgZmFpbGVkIChTZWUgU3VjY2VzcyBTdGF0dXMgYWJvdmUpLicNCn0NCg0KDQoNCiMjIyMjIyMjIyMjIyMjIyMjIyMjDQojIyMjIFMgVCBBIFQgUyAjIyMjIw0KIyMjIyMjIyMjIyMjIyMjIyMjIyMNCkxvZ1dyaXRlICgnIyMjIFNUQVRTJykNCltTdHJpbmddICRQYXRoU3RhdHMgPSAoJHtlbnY6UHJvZ3JhbUZpbGVzKHg4Nil9ICsgJ1xCaXRMb2NrZXJUcmlnZ2VyXHN0YXRzLnR4dCcpDQpbdWludDE2XSAkQ291bnRSdW5zID0gMQ0KSWYgKFRlc3QtUGF0aCAkUGF0aFN0YXRzKSB7DQogICAgJENvdW50UnVucyA9IEdldC1Db250ZW50ICRQYXRoU3RhdHMNCiAgICAkQ291bnRSdW5zICs9IDENCn0NCk91dC1GaWxlIC1GaWxlUGF0aCAkUGF0aFN0YXRzIC1FbmNvZGluZyB1dGY4IC1Gb3JjZSAtSW5wdXRPYmplY3QgKFtzdHJpbmddKCRDb3VudFJ1bnMpKQ0KTG9nV3JpdGUgKCdSdW5zIHNvIGZhcjogezB9JyAtZiAoJENvdW50UnVucykpDQoNCklmICgkQ291bnRSdW5zIC1lcSAzMCkgew0KICAgIExvZ1dyaXRlICgnU2hvdWxkIGhhdmUgYmVlbiBkb25lIGJ5IG5vdy4gU2VuZGluZyBhIHN1cHBvcnQgcmVxdWVzdCB0byB5b3VyIGhlbHBkZWtzJykNCiAgICAjIyMgR2F0aGVyaW5nIGluZm8gZm9yIHRoZSBlbWFpbA0KICAgIFtTdHJpbmddICRMb2NhbDpOYW1lQ29tcHV0ZXIgPSAkZW52OkNPTVBVVEVSTkFNRQ0KICAgICMjIFRlbmFudA0KICAgICRMb2NhbDpJRCA9IChHZXQtQ2hpbGRJdGVtIENlcnQ6XExvY2FsTWFjaGluZVxNeVwgfCBXaGVyZS1PYmplY3QgeyAkXy5Jc3N1ZXIgLW1hdGNoICdDTj1NUy1Pcmdhbml6YXRpb24tQWNjZXNzJyB9KS5TdWJqZWN0LlJlcGxhY2UoJ0NOPScsJycpDQogICAgIyBHZXQgdGhlIHRlbmFudCBuYW1lIGZyb20gdGhlIHJlZ2lzdHJ5DQogICAgW1N0cmluZ10gJExvY2FsOk5hbWVUZW5hbnQgPSAoR2V0LUl0ZW1Qcm9wZXJ0eSBIS0xNOlxTWVNURU1cQ3VycmVudENvbnRyb2xTZXRcQ29udHJvbFxDbG91ZERvbWFpbkpvaW5cSm9pbkluZm9cJCgkTG9jYWw6SUQpKS5Vc2VyRW1haWwuU3BsaXQoJ0AnKVsxXQ0KICAgICMjIEVudmlyb25tZW50IGluZm8NCiAgICBbU3lzdGVtLk1hbmFnZW1lbnQuTWFuYWdlbWVudE9iamVjdF0gJFNjcmlwdDpXTUlJbmZvID0gR2V0LVdtaU9iamVjdCAtQ2xhc3Mgd2luMzJfb3BlcmF0aW5nc3lzdGVtDQogICAgW1N0cmluZ10gJExvY2FsOldpbmRvd3NFZGl0aW9uID0gJFNjcmlwdDpXTUlJbmZvLkNhcHRpb24NCiAgICBbU3RyaW5nXSAkTG9jYWw6V2luZG93c1ZlcnNpb24gPSAkU2NyaXB0OldNSUluZm8uVmVyc2lvbg0KICAgICMjIE1haWwgYWRkcmVzcyhlcykNCiAgICBbU3RyaW5nXSAkTG9jYWw6U3RyVG9FbWFpbEFkZHJlc3MgPSAnT2xhdiBSLiBCaXJrZWxhbmQgPG9sYXZiQGlyb25zdG9laXQuY29tPjsnDQogICAgIyRTdHJFbWFpbEFkZHJlc3MgKz0gJ0lyb25zdG9uZSBTZXJ2aWNlZGVzayA8c2VydmljZWRla3NAaXJvbnN0b25laXQuY29tPicNCiAgICBbU3RyaW5nXSAkTG9jYWw6U3RyRnJvbUVtYWlsQWRkcmVzcyA9ICgnQml0TG9ja2VyVHJpZ2dlckZhaWxAezB9JyAtZiAoJExvY2FsOk5hbWVUZW5hbnQpKQ0KICAgICMjIyBCdWlsZGluZyBlbWFpbCBzdHJpbmcNCiAgICBbU3RyaW5nXSAkTG9jYWw6U3RyU3ViamVjdCA9ICgnQml0TG9ja2VyVHJpZ2dlciBmYWlsZWQgezB9IHRpbWVzIGZvciB0ZW5hbnQgInsxfSIsIGRldmljZTogInsyfSInIC1mICgkQ291bnRSdW5zLlRvU3RyaW5nKCksJExvY2FsOk5hbWVUZW5hbnQsJExvY2FsOk5hbWVDb21wdXRlcikpDQogICAgW1N0cmluZ10gJExvY2FsOlN0ckVtYWlsID0gW1N0cmluZ106OkVtcHR5DQogICAgJExvY2FsOlN0ckVtYWlsICs9ICgkTG9jYWw6U3RyU3ViamVjdCkNCiAgICAkTG9jYWw6U3RyRW1haWwgKz0gKCJgcmBuIikNCiAgICAkTG9jYWw6U3RyRW1haWwgKz0gKCJgcmBuIiArICcjIyBFbnZpcm9ubWVudCBpbmZvJykNCiAgICAkTG9jYWw6U3RyRW1haWwgKz0gKCJgcmBuIiArICgnRGV2aWNlIG5hbWU6ICcgKyAkTG9jYWw6TmFtZUNvbXB1dGVyICsgJywgV2luZG93cyBFZGl0aW9uOiAnICsgJExvY2FsOldpbmRvd3NFZGl0aW9uICsgJyAsIFdpbmRvd3MgVmVyc2lvbicgKyAkTG9jYWw6V2luZG93c1ZlcnNpb24pKQ0KICAgICRMb2NhbDpTdHJFbWFpbCArPSAoImByYG5gcmBuIiArICdUaGVyZSBoYXZlIG5vdyBiZWVuIHswfSBydW5zLCBidXQgQml0TG9ja2VyVHJpZ2dlciBTVElMTCBmYWlscy4nIC1mICgkQ291bnRSdW5zKSkNCiAgICAkTG9jYWw6U3RyRW1haWwgKz0gKCJgcmBuIiArICdTdWNjZXNzIHN0YXR1cyB8IEVuY3J5cHRlZCA6IHswfSB8IFByb3RlY3Rpb24gUGFzc3dvcmRzIHByZXNlbnQgOiB7MX0gfCBCYWNrdXAgdG8gQXp1cmVBRCA6IHsyfSB8IEJhY2t1cCB0byBPbmVEcml2ZSA6IHszfScgLWYgKCRJc0VuY3J5cHRlZCwkSXNQcm90ZWN0aW9uUGFzc3csJElzQmFja3VwQUFELCRJc0JhY2t1cE9EKSkNCiAgICAjIyMgU2VuZCBlbWFpbA0KICAgICNTZW5kLU1haWxNZXNzYWdlIC1UbyAkTG9jYWw6U3RyVG9FbWFpbEFkZHJlc3MgLVNtdHBTZXJ2ZXIgIC1Gcm9tICRMb2NhbDpTdHJGcm9tRW1haWxBZGRyZXNzIC1TdWJqZWN0ICRMb2NhbDpTdHJTdWJqZWN0IC1Cb2R5ICRMb2NhbDpTdHJFbWFpbA0KfQ0KDQoNCg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMNCiMjIyMgIEQgTyBOIEUgICMjIyMjDQojIyMjIyMjIyMjIyMjIyMjIyMjIw0KTG9nV3JpdGUgKCdBbGwgZG9uZSwgZXhpdGluZyBzY3JpcHQuLi4nKQ==')
#endregion FilePS1

# Enable-BitLockerTrigger.VBS
#region FileVBS
[String] $Local:NameVBS = 'Enable_BitLocker.vbs'
[String] $Local:FileVBS = ('U2V0IG9ialNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXc2NyaXB0LlNoZWxsIikgIA0KU2V0IGFyZ3MgPSBXc2NyaXB0LkFyZ3VtZW50cyAgDQpGb3IgRWFjaCBhcmcgSW4gYXJncyAgDQogICAgRGltIFBTUnVuDQogICAgUFNSdW4gPSAicG93ZXJzaGVsbC5leGUgLVdpbmRvd1N0eWxlIGhpZGRlbiAtRXhlY3V0aW9uUG9saWN5IGJ5cGFzcyAtTm9uSW50ZXJhY3RpdmUgLUZpbGUgIiIiICYgYXJnICYgIiIiIg0KICAgIG9ialNoZWxsLlJ1bihQU1J1biksMA0KTmV4dA==')
#endregion FileVBS
    
# Enable-BitLockerTrigger.XML
#region FileXML
[String] $Local:NameXML = 'Enable_BitLocker.xml'
[String] $Local:FileXML = ('PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTE2Ij8+DQo8VGFzayB2ZXJzaW9uPSIxLjQiIHhtbG5zPSJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dpbmRvd3MvMjAwNC8wMi9taXQvdGFzayI+DQogIDxSZWdpc3RyYXRpb25JbmZvPg0KICAgIDxEYXRlPjIwMTgtMDEtMDFUMTQ6MDA6MDA8L0RhdGU+DQogICAgPEF1dGhvcj5Jcm9uc3RvbmU8L0F1dGhvcj4NCiAgICA8VVJJPlxCaXRsb2NrZXJUcmlnZ2VyPC9VUkk+DQogIDwvUmVnaXN0cmF0aW9uSW5mbz4NCiAgPFRyaWdnZXJzPg0KICAgIDxUaW1lVHJpZ2dlcj4NCiAgICAgIDxSZXBldGl0aW9uPg0KICAgICAgICA8SW50ZXJ2YWw+UFQxNU08L0ludGVydmFsPg0KICAgICAgICA8U3RvcEF0RHVyYXRpb25FbmQ+ZmFsc2U8L1N0b3BBdER1cmF0aW9uRW5kPg0KICAgICAgPC9SZXBldGl0aW9uPg0KICAgICAgPFN0YXJ0Qm91bmRhcnk+MjAxOC0wMS0wMVQxNDowMDowMDwvU3RhcnRCb3VuZGFyeT4NCiAgICAgIDxFbmFibGVkPnRydWU8L0VuYWJsZWQ+DQogICAgPC9UaW1lVHJpZ2dlcj4NCiAgPC9UcmlnZ2Vycz4NCiAgPFByaW5jaXBhbHM+DQogICAgPFByaW5jaXBhbCBpZD0iQXV0aG9yIj4NCiAgICAgIDxHcm91cElkPlMtMS01LTMyLTU0NTwvR3JvdXBJZD4NCiAgICAgIDxSdW5MZXZlbD5IaWdoZXN0QXZhaWxhYmxlPC9SdW5MZXZlbD4NCiAgICA8L1ByaW5jaXBhbD4NCiAgPC9QcmluY2lwYWxzPg0KICA8U2V0dGluZ3M+DQogICAgPE11bHRpcGxlSW5zdGFuY2VzUG9saWN5Pklnbm9yZU5ldzwvTXVsdGlwbGVJbnN0YW5jZXNQb2xpY3k+DQogICAgPERpc2FsbG93U3RhcnRJZk9uQmF0dGVyaWVzPmZhbHNlPC9EaXNhbGxvd1N0YXJ0SWZPbkJhdHRlcmllcz4NCiAgICA8U3RvcElmR29pbmdPbkJhdHRlcmllcz5mYWxzZTwvU3RvcElmR29pbmdPbkJhdHRlcmllcz4NCiAgICA8QWxsb3dIYXJkVGVybWluYXRlPnRydWU8L0FsbG93SGFyZFRlcm1pbmF0ZT4NCiAgICA8U3RhcnRXaGVuQXZhaWxhYmxlPnRydWU8L1N0YXJ0V2hlbkF2YWlsYWJsZT4NCiAgICA8UnVuT25seUlmTmV0d29ya0F2YWlsYWJsZT5mYWxzZTwvUnVuT25seUlmTmV0d29ya0F2YWlsYWJsZT4NCiAgICA8SWRsZVNldHRpbmdzPg0KICAgICAgPFN0b3BPbklkbGVFbmQ+dHJ1ZTwvU3RvcE9uSWRsZUVuZD4NCiAgICAgIDxSZXN0YXJ0T25JZGxlPmZhbHNlPC9SZXN0YXJ0T25JZGxlPg0KICAgIDwvSWRsZVNldHRpbmdzPg0KICAgIDxBbGxvd1N0YXJ0T25EZW1hbmQ+dHJ1ZTwvQWxsb3dTdGFydE9uRGVtYW5kPg0KICAgIDxFbmFibGVkPnRydWU8L0VuYWJsZWQ+DQogICAgPEhpZGRlbj5mYWxzZTwvSGlkZGVuPg0KICAgIDxSdW5Pbmx5SWZJZGxlPmZhbHNlPC9SdW5Pbmx5SWZJZGxlPg0KICAgIDxEaXNhbGxvd1N0YXJ0T25SZW1vdGVBcHBTZXNzaW9uPmZhbHNlPC9EaXNhbGxvd1N0YXJ0T25SZW1vdGVBcHBTZXNzaW9uPg0KICAgIDxVc2VVbmlmaWVkU2NoZWR1bGluZ0VuZ2luZT50cnVlPC9Vc2VVbmlmaWVkU2NoZWR1bGluZ0VuZ2luZT4NCiAgICA8V2FrZVRvUnVuPmZhbHNlPC9XYWtlVG9SdW4+DQogICAgPEV4ZWN1dGlvblRpbWVMaW1pdD5QVDFIPC9FeGVjdXRpb25UaW1lTGltaXQ+DQogICAgPFByaW9yaXR5Pjc8L1ByaW9yaXR5Pg0KICA8L1NldHRpbmdzPg0KICA8QWN0aW9ucyBDb250ZXh0PSJBdXRob3IiPg0KICAgIDxFeGVjPg0KICAgICAgPENvbW1hbmQ+d3NjcmlwdC5leGU8L0NvbW1hbmQ+DQogICAgICA8QXJndW1lbnRzPiJDOlxQcm9ncmFtIEZpbGVzICh4ODYpXEJpdExvY2tlclRyaWdnZXJcRW5hYmxlX0JpdExvY2tlci52YnMiICJDOlxQcm9ncmFtIEZpbGVzICh4ODYpXEJpdExvY2tlclRyaWdnZXJcRW5hYmxlX0JpdExvY2tlci5wczEiPC9Bcmd1bWVudHM+DQogICAgPC9FeGVjPg0KICA8L0FjdGlvbnM+DQo8L1Rhc2s+')
#endregion FileXML
#enregion Files
#endregion Variables



#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In
        )
        If ($DebugConsole) {
            Write-Output -InputObject $In
        }
        If ($DebugWinTemp) {
            $Global:DebugStr += ($In + "`r`n")
        }
    }
    #endregion Write-DebugIfOn


    #region Check-CreateDir
    Function Check-CreateDir {
        Param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $Dir
        )
        Write-DebugIfOn -In ('Check-CreateDir -Dir ' + $Dir)
        If (!(Test-Path $Dir)) {
                Write-DebugIfOn -In '   Reg dir does not exist, trying to create'
                If(!($ReadOnly)) {
                    $null = New-Item -ItemType Directory -Force -Path $Dir 2>&1
                    If (!($?)) {
                        Write-DebugIfOn -In '      ERROR: Dir could not be created'
                    }
                    Else {
                        Write-DebugIfOn -In '      SUCCESS: Dir was created'
                    }
                }
                Else {Write-DebugIfOn -In '      ReadOnly mode'}
            } 
        Else {
            Write-DebugIfOn -In '   Reg dir does already exist'
        } 
    }
    #endregion Check-CreateDir


    #region FileOut-FromBase64
    Function FileOut-FromBase64 {
        Param(
            [Parameter(Mandatory=$true)]
            [String] $InstallDir, $FileName, $File, $Encoding
        )
        Write-DebugIfOn -In ('FileOut-FromBase64 -FilePath ' + $InstallDir + ' -FileName ' + $FileName + ' -File ' + ($File.Substring(0,10) + '...'))
        $Local:FilePath = $InstallDir + $FileName

        If (Test-Path $InstallDir) {
            Write-DebugIfOn -In ('   Path exists, trying to write the file (File alrady exists? {0})' -f (Test-Path $Local:FilePath))
            If (-not($ReadOnly)) {
                Out-File -FilePath $Local:FilePath -Encoding $Encoding -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($File)))
                Write-DebugIfOn -In ('      Success? {0}' -f ($?))
                Write-DebugIfOn -In ('         Does file actually exist? {0}' -f (Test-Path $Local:FilePath -ErrorAction SilentlyContinue))
            }
        }
        Else {
            Write-DebugIfOn -In ('   ERROR: Path does not exist')
        }
    }
    #enregion FileOut-FromBase64
#enregion Functions



#region Initialize
[String] $Script:CompName = $env:COMPUTERNAME
[System.Management.ManagementObject] $Script:WMIInfo = Get-WmiObject -Class win32_operatingsystem
[String] $Script:WindowsEdition = $Script:WMIInfo.Caption
[String] $Script:WindowsVersion = $Script:WMIInfo.Version
If ($DebugWinTemp -or $DebugConsole) {   
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = ' + $DebugConsole + ' | DebugWinTemp = ' + $DebugWinTemp + ' ' + ' | ReadOnly = ' + $ReadOnly)
    Write-DebugIfOn -In ('Host (' + $Script:CompName + ') runs: ' + $Script:WindowsEdition + ' v' + $Script:WindowsVersion)
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n`r`n" + '### ' + $WhatToConfig)

    # 1. Create dir
    [String] $Local:InstallDir = (${env:ProgramFiles(x86)} + '\BitLockerTrigger\')
    Check-CreateDir -Dir $InstallDir
    
    # 2. Import files
    FileOut-FromBase64 -InstallDir $Local:InstallDir -FileName $Local:NamePS1 -File $Local:FilePS1 -Encoding utf8
    FileOut-FromBase64 -InstallDir $Local:InstallDir -FileName $Local:NameVBS -File $Local:FileVBS -Encoding default
    FileOut-FromBase64 -InstallDir $Local:InstallDir -FileName $Local:NameXML -File $Local:FileXML -Encoding utf8

    # 3. Run VBS to create schedule
    Write-DebugIfOn -In ('Register-ScheduledTask -Xml (Get-Content (' + $Local:InstallDir + $Local:NameXML + ') | Out-String) -TaskName "BitLockerTrigger" -Force')
    $null = Register-ScheduledTask -Xml (Get-Content ($Local:InstallDir + $Local:NameXML) | Out-String) -TaskName 'BitLockerTrigger' -Force
    Write-DebugIfOn -In ('   Success? {0}' -f ($?))

    # 4. Reset stats and log
    Write-DebugIfOn -In ('Reset stats and log')
    [String[]] $Local:RemItems = @(($Local:InstallDir + 'stats.txt'),($env:windir + '\Temp\TriggerBitLocker.log'))
    $Local:RemItems | ForEach-Object { 
        If (Test-Path $_) {
            Remove-Item -Path ($_) -Force
            Write-DebugIfOn -In (' Removing "{0}". Success? .' -f ($_, $?))
        }
        Write-DebugIfOn -In (' "{0}" does not exist' -f ($_))
    }
#endregion Main



#region Debug
If ($DebugWinTemp) {
    If ([String]::IsNullOrEmpty($DebugStr)) {
        $DebugStr = 'Everything failed'
    }

    # Write Output
    $DebugPath = 'C:\Windows\Temp\'
    $CurDate = Get-Date -Uformat '%y%m%d'
    $CurTime = Get-Date -Format 'HHmmss'
    $DebugFileName = ('Debug Powershell ' + $WhatToConfig + ' ' + $CurDate + $CurTime + '.txt')

    $DebugStr | Out-File -FilePath ($DebugPath + $DebugFileName) -Encoding 'utf8'
    If (!($?)) {
        $DebugStr | Out-File -FilePath ($env:TEMP + '\' + $DebugFileName) -Encoding 'utf8'
    }
}
#endregion Debug
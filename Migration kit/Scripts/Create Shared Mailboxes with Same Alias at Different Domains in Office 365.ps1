# Create Shared Mailboxes with Same Alias at Different Domains in Office 365
# For example:
# shared_mailbox@domain1.com
# shared_mailbox@domain2.com
#


# Create a shared mailbox with a different alias.
New-Mailbox -Name "Test Shared Mailbox 2" -Alias test_shared2 -Shared -PrimarySMTPAddress test_shared@cogmotivereports.com

Name Alias ServerName ProhibitSendQuota
---- ----- ---------- -----------------
Test Shared Mailbox 2 test_shared2

# You can now see the mailbox and the UPN it has been assigned:
get-mailbox test_shared2 | select userprincipalname

UserPrincipalName
-----------------
test_shared2@cogmotive.onmicrosoft.com

# So how do we set the correct login name? With the Set-Mailbox command like this:
set-mailbox test_shared2 -MicrosoftOnlineServicesID test_shared@cogmotivereports.com



# And viola, we have the correct UPN.
get-mailbox test_shared2 | select userprincipalname

UserPrincipalName
-----------------
test_shared@cogmotivereports.com
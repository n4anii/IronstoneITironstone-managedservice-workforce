#Variables

#Path to CSV file
#Required headers: Firstname,LastName,upn,MobileNumber,Password
$CsvFilePath = '..\import\masterdata.csv'
#This is a secret, so don't share it :)
$SmsAPIEndpoint = 'https://istpeuwsendsinchsms.azurewebsites.net/api/Send-SinchSMS?code=fGN6puQeQuZjF3agVnXi6TIFY/kMRzs1J0Fm/jtI0liylBDUaSAWoQ=='
#Mobile number REgex
$MobileNumberRegex = '^([+]46)(7[0236])(\d{4})(\d{3})$|^([+]47)?\d{8}$'



#Message
$MessageTemplate = @("Hello ##Firstname##, 

The Office 365 migration of your user is now completed.

Your new username is: 
##UPN##

Your new password is: 
##PASSWORD##

Best Regards - Ironstone

")

#ErrorAction
$ErrorActionPreference = 'stop'

#No need to change below here

if (Test-Path $CsvFilePath) {

    [array]$Recipients = Get-Content $CsvFilePath | ConvertFrom-Csv

    $TotalNumberOfRecipients = $Recipients.Count
    Write-Output ('Total number of recipients [{0}].' -f $TotalNumberOfRecipients)

}
else {
    Write-Error ('Unable to find file [{0}]' -f $CsvFilePath)
}

#Loop through all the recipients

$RecipientCount = 1

Foreach ($Recipient in $Recipients) {

    Write-Output ('Working on user {0}/{1}. Name: {2}, {3} ' -f $RecipientCount, $TotalNumberOfRecipients, $Recipient.firstname, $Recipient.LastName)
    $RecipientCount++
    $RecipientMessage = $MessageTemplate

    #Verify mobile number
    if ($Recipient.MobileNumber -notmatch $MobileNumberRegex) {
        Write-Warning 'Mobile number is not in a valid format. Format must match: Norway: +4712131415 Sweden: +46121314151. Moving to next object.'
        Continue
    }

    #Verify Firstname
    if ([string]::IsNullOrEmpty($Recipient.firstname)) {
        Write-Warning 'Firstname is empty or missing. Moving to next object.'
        Continue
    }
    else {
        $RecipientMessage = $RecipientMessage -replace '##FIRSTNAME##', $Recipient.firstname

    }
	
    #Verify UPN
    if ([string]::IsNullOrEmpty($Recipient.destinationUPN)) {
        Write-Warning 'UPN is empty or missing. Moving to next object.'
        Continue
    }
    else {
        $RecipientMessage = $RecipientMessage -replace '##UPN##', $Recipient.destinationUPN
    }

    #Verify lastname
    if ([string]::IsNullOrEmpty($Recipient.lastName)) {
        Write-Warning 'LastName is empty or missing. Moving to next object.'
        Continue
    }
    else {
        $RecipientMessage = $RecipientMessage -replace '##LastName##', $Recipient.lastName
    }

    #Verify password
    if ([string]::IsNullOrEmpty($Recipient.Password)) {
        Write-Warning 'Password is empty or missing. Moving to next object.'
        Continue
    }
    else {
        $RecipientMessage = $RecipientMessage -replace '##Password##', $Recipient.Password
    }

    #Create SMS Body
    $SMSBody = @{
        'Recipient' = $Recipient.MobileNumber
        'Message'   = $RecipientMessage
        'Sender'    = 'Ironstone'
    }

    Try {
        #Send SMS
        $Null = Invoke-RestMethod -body (ConvertTo-JSON $SMSBody) -Uri $SmsAPIEndpoint -Method post -ContentType 'application/json; charset=utf-8' -ErrorAction 'Stop'
    }
    catch {

        Write-Error 'Something went wrong while sending SMS... :/'
    }

}
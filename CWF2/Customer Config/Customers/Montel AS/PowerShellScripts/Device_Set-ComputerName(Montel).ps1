#Requires -Version 5.1 -PSEdition Desktop -RunAsAdministrator
<#
    .SYNOPSIS
        Sets computer name to "$ComputerNameBase-<serial_number>". Will fallback to MAC address of physical ethernet NIC if S/N is not found.

    .EXAMPLE
        # Test from PowerShell ISE
        & $psISE.'CurrentFile'.'FullPath' -WriteChanges $false
#>




# Input parameters
[OutputType($null)]
Param (
    [Parameter(Mandatory = $false)]
    [bool] $WriteChanges = $true
)




# Customer Variables
$ComputerNameBase = [string] 'MON-'




# PowerShell Preferences
$ConfirmPreference     = 'None'
$DebugPreference       = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'




# Check Customer Variables
$ComputerNameBase = $ComputerNameBase.Trim().Replace(' ','')
if ([string]::IsNullOrEmpty($ComputerNameBase)) {
    Throw 'ERROR: $ComputerNameBase cannot be empty.'
}




# Assets
## ComputerName Wmi Object
$ComputerNameWmiObject = Get-WmiObject -Class 'Win32_ComputerSystem' -ErrorAction 'Stop'
$Success = [bool] $false




# Get current ComputerName
## Write information
Write-Output -InputObject ('# Get current ComputerName.')


## Get current computer name
### Get
$ComputerNameOld = [string] $ComputerNameWmiObject.'Name'.Trim()

### Failproof
if ([string]::IsNullOrEmpty($ComputerNameOld)){
    Throw 'ERROR: Did not manage to retrieve current ComputerName.'
}


## Write information
Write-Output -InputObject ('Old computer name: "{0}".' -f $ComputerNameOld)




# Get serial number
## Write information
Write-Output -InputObject ('{0}# Get serial number.' -f [System.Environment]::NewLine)


## Validation function
function Validate-SerialNumber {
    [OutputType([bool])]
    Param (
        [Parameter(Mandatory)]
        [string] $SN
    )
    -not [string]::IsNullOrEmpty($SN) -and
    -not [string]::IsNullOrEmpty($SN.Trim().Replace(' ','')) -and
    $([string[]]('default','filled','number','o?e?m','oem','serial','string','system')).ForEach{
        $SN -like ('*{0}*'-f$_)
    } -notcontains $true
}


## Get
### Preferred method
$ComputerSerialNumber = [string]$(
    Try {
        (Get-WmiObject -Class 'Win32_ComputerSystemProduct').'IdentifyingNumber'.Trim()
    }
    Catch {
        ''
    }
)

### Alternative method 1
if (-not(Validate-SerialNumber -SN $ComputerSerialNumber)) {
    $ComputerSerialNumber = [string]$(
        Try {
            (Get-WmiObject -Class 'Win32_bios').'SerialNumber'.Trim()
        }
        Catch {
            ''
        }
    )
}

### Alternative method 2
if (-not(Validate-SerialNumber -SN $ComputerSerialNumber)) {
    $ComputerSerialNumber = [string]$(
        Try {
            (Get-WmiObject -Class 'Win32_baseboard').'SerialNumber'.Trim()
        }
        Catch {
            ''
        }
    )
}

### Alternative method 3 - MAC address of physical ethernet port
if (-not(Validate-SerialNumber -SN $ComputerSerialNumber)) {
    $ComputerSerialNumber = [string]$(
        Try {
            Get-NetAdapter -Physical | `
                Where-Object -Property 'PhysicalMediaType' -Like '*802.3*' | `
                Sort-Object -Property 'ifIndex' | `
                Select-Object -First 1 -ExpandProperty 'MacAddress'
        }
        Catch {
            ''
        }
    )
}

### Failproof
if (-not(Validate-SerialNumber -SN $ComputerSerialNumber)) {
    Throw 'ERROR: Did not manage to retrieve current serial number.'
}


## Cleanup
$ComputerSerialNumber = [string] $ComputerSerialNumber.Replace(' ','').Replace(':','').Replace('.','').Replace('/','').Replace('-','').ToUpper()


## Write information
Write-Output -InputObject ('Serial number: {0}' -f $ComputerSerialNumber)




# Create new ComputerName
## Write information
Write-Output -InputObject ('{0}# Create new ComputerName.' -f [System.Environment]::NewLine)


## Create new computer name
### Create
$ComputerNameNew = [string] '{0}{1}' -f $ComputerNameBase, $ComputerSerialNumber

### Failproof
if ($ComputerNameNew.'Length' -gt 15) {            
    Write-Output -InputObject ('New computername "{0}" was to long with {1}ch, max 15ch allowed. Will shorten it.' -f $ComputerNameNew,$ComputerNameNew.'Length'.ToString())
    $ComputerNameNew = $ComputerNameNew.Substring(0,15)
    Write-Output -InputObject ('{0}Shortened name to "{1}", {2}ch.' -f "`t",$ComputerNameNew,$ComputerNameNew.'Length'.ToString())
}


## Make sure we successfully created new ComputerName by checking that it's at least as long as the name base
if ($ComputerNameNew.'Length' -le $ComputerNameBase.'Length'){
    Throw 'ERROR: Did not manage to create new ComputerName'
}


## Write information
Write-Output -InputObject ('New computer name: "{0}".' -f $ComputerNameNew)




# Set ComputerName
## Write information
Write-Output -InputObject ('{0}# Set new ComputerName.' -f [System.Environment]::NewLine)


## If ComputerNameNew is the same as ComputerNameOld = Don't change anything
if ($ComputerNameOld -eq $ComputerNameNew) {
    # Set success to $true
    $Success = [bool] $true
    
    # Write information
    Write-Output -InputObject ('ComputerName is already "{0}". Did not change anything.' -f ($ComputerNameNew))
}


## If ComputerNameNew is not the same as ComputerNameOld = Change ComputerName
else {
    if ($WriteChanges) {
        # Set ComputerName and check if success in doing so based on return value
        $Success = [bool](($ComputerNameWmiObject).Rename($ComputerNameNew).'ReturnValue' -eq 0)

        # Write information
        Write-Output -InputObject ('Successfully changed ComputerName from "{0}" to "{1}"? {2}.' -f $ComputerNameOld,$ComputerNameNew,$Success.ToString())
    }
    else {
        # Set success to $true
        $Success = [bool] $true
        
        # Write information
        Write-Output -InputObject ('$WriteChanges is $false.')
    }
}




# Exit
Write-Output -InputObject ('{0}# Exit.' -f [System.Environment]::NewLine)
if ($Success) {
    Write-Output -InputObject 'Success.'
    Exit 0
}
else {
    Write-Error -Message 'Failed.' -ErrorAction 'Continue'
    Exit 1
}

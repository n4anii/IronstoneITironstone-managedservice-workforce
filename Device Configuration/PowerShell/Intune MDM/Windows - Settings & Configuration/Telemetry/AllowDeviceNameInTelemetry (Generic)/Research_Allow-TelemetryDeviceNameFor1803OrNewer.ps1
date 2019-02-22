<#
    Registry
#>

# Assets
$Path  = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection')
$Name  = [string]$('AllowDeviceNameInTelemetry')
$Value = [byte]$(1)
$Type  = [string]$('DWord')

# Create Dir if not exist
if (-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory' -Force -ErrorAction 'Stop'}

# Set Value
$null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction 'Stop'



<#
    Policy


    Name:             System/AllowDeviceNameInDiagnosticData
    OMA-URI:          ./Device/Vendor/MSFT/Policy/Config/System/AllowDeviceNameInDiagnosticData
    Value Type:       Integer
    Value:            1
    Documentation:    https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system#system-allowdevicenameindiagnosticdata



    1809 DataCollection.admx
     
    <policy name="AllowDeviceNameInDiagnosticData" class="Machine" displayName="$(string.AllowDeviceNameInDiagnosticData)" explainText="$(string.AllowDeviceNameInDiagnosticData_Explain)" key="Software\Policies\Microsoft\Windows\DataCollection" valueName="AllowDeviceNameInTelemetry">
      <parentCategory ref="windows:DataCollectionAndPreviewBuilds" />
      <supportedOn ref="windows:SUPPORTED_Windows_10_0_RS4" />
      <enabledValue>
        <decimal value="1" />
      </enabledValue>
      <disabledValue>
        <decimal value="0" />
      </disabledValue>
    </policy>



    1803 DataCollection.admx

    <policy name="AllowDeviceNameInDiagnosticData" class="Machine" displayName="$(string.AllowDeviceNameInDiagnosticData)" explainText="$(string.AllowDeviceNameInDiagnosticData_Explain)" key="Software\Policies\Microsoft\Windows\DataCollection" valueName="AllowDeviceNameInTelemetry">
      <parentCategory ref="windows:DataCollectionAndPreviewBuilds" />
      <supportedOn ref="windows:SUPPORTED_Windows_10_0_RS4" />
      <enabledValue>
        <decimal value="1" />
      </enabledValue>
      <disabledValue>
        <decimal value="0" />
      </disabledValue>
    </policy>
#>
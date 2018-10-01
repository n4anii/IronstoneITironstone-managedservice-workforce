# IronAudioInputDeviceMaxer

## Pseudocode 
### Device_Install-RecordingDeviceVolumeMax.ps1

Using Ironstone Intune MDM PowerShell Template:
1. Installs/ Updates PowerShell PackageProvider NuGet.
	* Continue of success
2. Installs/ Updates PowerShell Modules "PowerShellGet" and "AudioDeviceCmdlets".
	* Continue if success
3. Installs "Set-RecordingDeviceVolumeMax.ps1" and creates scheduled task.
	* Create Install dir.
	* Create Log dir.
	* Export BASE64 encoded "Set-RecordingDeviceVolumeMax.ps1" to file.
	* Create scheduled task "Run-RecordingDeviceVolumeMax"
4. Runs "Set-RecordingDeviceVolumeMax.ps1" if successfully installed.


### Set-RecordingDeviceVolumeMax.ps1

1. Start-Transcript
2. Imports module "AudioDeviceCmdlets" , exits if fails
3. Set each recording device volume to max / 100% by:
	* Remember current default recording device
	* Loop through every recording device
		* Set as default
		* Set volume to 100%
	* Revert back to default recording device from first step
4. Delete log if success
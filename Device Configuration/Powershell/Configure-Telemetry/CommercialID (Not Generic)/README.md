# Device_Set-CommercialID
This script is not generic: You have to add a specific CommercialID to the script before deploying it to the customer.
## What is CommercialID
CommercialID is a unique ID which ensures that telemetry data reaches the correct OMS workspace.
## Prerequisites
You'll need a OMS workspace with following solutions deployed to it:
* CompatibilityAssessment, aka "Upgrade Readiness"
* DeviceHealthProd, aka "Device Health"
  * Make sure to activate Windows Telemetry
* WaasUpdateInsights, aka "Update Compliance"

## Where to get CommercialID
Go into the OMS Workspace. Then, go to Settings -> Connected Sources -> Windows Telemetry


## CommercialIDs - Ironstone
### Ironstone Global
* 3e874c1f-1ac7-422a-b5d9-95c87a3af965
* (OLD) 0214110f-01c5-431f-899b-8bb6e6ed65e9

### Irontest
* 8648296d-733e-4666-8f7f-8a6ab1d93522

## CommercialIDs - Customers
### Backe
* 9c16257a-ee3b-4aec-9427-9a2f48077769

### Holta
* 8df10bfc-5316-4529-ad94-47f3f426868c

### Metier
* b51417b6-2ddf-4125-89bb-2d5a9864f466

<#

POLICY CSP - POWER
    !!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!  Plugged In = AC !!!!
    !!!!  On Battery = DC !!!!
    !!!!  Never idle = 0  !!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!  Time = Seconds (minutes * 60)
    
    #############################
    ##### CONVERSION TABLE  #####
    #############################

    OMA-URI                                                                               OMA Value Id ?                 GPO Name                       REG Dir                                 INTUNE PROFILE?
    ./Device/Vendor/MSFT/Policy/Config/Power/AllowStandbyWhenSleepingOnBattery                                           AllowStandbyStatesDC_2         abfc2519-3608-4c2a-94ea-171b0ed546ab    
    ./Device/Vendor/MSFT/Policy/Config/Power/AllowStandbyWhenSleepingPluggedIn                                           AllowStandbyStatesAC_2         abfc2519-3608-4c2a-94ea-171b0ed546ab    
    ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutOnBattery                   EnterVideoDCPowerDownTimeOut   VideoPowerDownTimeOutDC_2      3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e
    ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutPluggedIn                   EnterVideoACPowerDownTimeOut   VideoPowerDownTimeOutAC_2      3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e
    ./Device/Vendor/MSFT/Policy/Config/Power/HibernateTimeoutOnBattery                    EnterDCHibernateTimeOut        DCHibernateTimeOut_2           9D7815A6-7EE4-497E-8888-515A05F02364          
    ./Device/Vendor/MSFT/Policy/Config/Power/HibernateTimeoutPluggedIn                    EnterACHibernateTimeOut        ACHibernateTimeOut_2           9D7815A6-7EE4-497E-8888-515A05F02364
    ./Device/Vendor/MSFT/Policy/Config/Power/RequirePasswordWhenComputerWakesOnBattery                                   DCPromptForPasswordOnResume_2  0e796bdb-100d-47d6-a2d5-f7d2daa51f51    Device Restrictions  
    ./Device/Vendor/MSFT/Policy/Config/Power/RequirePasswordWhenComputerWakesPluggedIn                                   ACPromptForPasswordOnResume_2  0e796bdb-100d-47d6-a2d5-f7d2daa51f51    Device Restrictions
    ./Device/Vendor/MSFT/Policy/Config/Power/StandbyTimeoutOnBattery                      EnterDCStandbyTimeOut          DCStandbyTimeOut_2             29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA
    ./Device/Vendor/MSFT/Policy/Config/Power/StandbyTimeoutPluggedIn                      EnterACStandbyTimeOut          ACStandbyTimeOut_2             29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA



    ###############################
    ##### CUSTOMERS SETTINGS  #####
    ###############################
      
    METIER
    ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutOnBattery                   <enabled/><data id="EnterVideoDCPowerDownTimeOut" value="900" />
    ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutPluggedIn                   <enabled/><data id="EnterVideoACPowerDownTimeOut" value="1800" />
    ./Device/Vendor/MSFT/Policy/Config/Power/HibernateTimeoutOnBattery                    <enabled/><data id="EnterDCHibernateTimeOut" value="1800" />
    ./Device/Vendor/MSFT/Policy/Config/Power/HibernateTimeoutPluggedIn                    <enabled/><data id="EnterACHibernateTimeOut" value="3600" />


    BACKE
    ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutOnBattery                   <enabled/><data id="EnterVideoDCPowerDownTimeOut" value="900" />
    ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutPluggedIn                   <enabled/><data id="EnterVideoACPowerDownTimeOut" value="1800" />
    ./Device/Vendor/MSFT/Policy/Config/Power/HibernateTimeoutOnBattery                    <enabled/><data id="EnterDCHibernateTimeOut" value="1800" />
    ./Device/Vendor/MSFT/Policy/Config/Power/HibernateTimeoutPluggedIn                    <enabled/><data id="EnterACHibernateTimeOut" value="3600" />
    ./Device/Vendor/MSFT/Policy/Config/Power/StandbyTimeoutOnBattery                      <enabled/><data id="EnterDCStandbyTimeOut" value="0" />
    ./Device/Vendor/MSFT/Policy/Config/Power/StandbyTimeoutPluggedIn                      <enabled/><data id="EnterACStandbyTimeOut" value="0" />

#>


### Folders
# All power settings reside in this folder
[string] $Dir = 'HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\'

# Theres a subfolder per stuff to config
[string] $SubDir_AllowStandbyWhenSleepingPluggedIn = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'
[string] $SubDir_DisplayOffTimeout                 = '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e'
[string] $SubDir_HibernateTimeout                  = '9D7815A6-7EE4-497E-8888-515A05F02364'
[string] $SubDir_RequirePasswordWhenComputerWakes  = '0e796bdb-100d-47d6-a2d5-f7d2daa51f51'
[string] $SubDir_StandbyTimeout                    = '29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA'


### Values
# These two are found in each subfolder. DWord, 0 = Never/ Infinite
[string] $OnBattery_DWord = 'DCSettingIndex'
[string] $PluggedIn_DWord = 'ACSettingIndex'
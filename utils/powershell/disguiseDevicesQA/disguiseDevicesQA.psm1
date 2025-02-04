# Implement your module commands in this script.
$d3ModelConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3ModelConfigImporter"
$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
Import-Module $d3ModelConfigPath -Force
Import-Module $d3OSQAUtilsPath -Force

function Test-GraphicsCardControlPannel{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$pathToOSValidationTemplate
    )
    # Importing the required modules
    $path = Format-disguiseModulePathForImport -RepoName "disguisedsec" -ModuleName "d3HardwareValidation"
    Import-Module $path -Force
    $path = Format-disguiseModulePathForImport -RepoName "disguisedPower" -ModuleName "disUtils"
    Import-Module $path -Force

    $nw = $null

    try{
        $hw = Assert-Hardware
    }catch{
        write-error("Cannot gather hardware via [Assert-Hardware]:")
        write-error($_)
    }
    
    if($hw.gpu.Manufacturer -eq "NVIDIA"){
        write-Host("GPU Identified as NVIDIA")
        $process = $null
        Get-AppxPackage 'NVIDIACorp.NVIDIAControlPanel' | % { 
            Copy-Item -LiteralPath $_.InstallLocation -Destination $Env:USERPROFILE\Desktop -Recurse -Force  | Out-Null
            Start-Process "$Env:USERPROFILE\Desktop\NVIDIACorp.NVIDIAControlPanel_*\nvcplui.exe"  | Out-Null
        }
        
        $process = Get-Process | Where-Object {$_.ProcessName -eq "nvcplui"} 
        start-sleep -Seconds 2

        if($process){
            $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
            $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "NvidiaControlPannel_$($timestamp).bmp"
            Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore | Out-Null
            Stop-Process -Name $process.Name | Out-Null
            Wait-Process -Name $process.Name | Out-Null
        }

        $returnMessage = ""
        try{
            $command = {Remove-Item "$Env:USERPROFILE\Desktop\NVIDIACorp.NVIDIAControlPanel_*" -Force -Recurse -WarningAction Continue}
            Invoke-Command -ScriptBlock $command | Out-Null
        }catch{
            Write-Warning("Warning: Failed to delete [$($Env:USERPROFILE)\Desktop\NVIDIACorp.NVIDIAControlPanel_*]")
            $returnMessage += "Note: [Desktop\NVIDIACorp.NVIDIAControlPanel] could not be removed. Please remove manually. "
        }

        $nvidiaDriverTemplate = (Import-OSValidationTemplate -PathToTemplateFile $pathToOSValidationTemplate).PackageVersions | Where-Object {$_.sharedPackageHandle.ToUpper() -match ("NVIDIA_Driver").ToUpper()} 

        $testValue = "PASSED"
        if(-not(Compare-Versions -Version1 $hw.gpu.DriverVersion -Version2 $nvidiaDriverTemplate.publicPackageVersion -equal)){
            $returnMessage += "Nvidia Driver version detected as: [$([Version]$hw.gpu.DriverVersion)]. This is different to the required version: [$([Version]$nvidiaDriverTemplate.publicPackageVersion)] as found in choco package [Nvidia Driver and Software]'s [publicPackageVersion]. "
            $testValue = "FAILED"
        }else{
            $returnMessage += "Nvidia Driver version detected as: [$([Version]$hw.gpu.DriverVersion)]. Choco package [Nvidia Driver and Software]'s [publicPackageVersion]: [$([Version]$nvidiaDriverTemplate.publicPackageVersion)]"
        }

        if(-not $process){
            $returnMessage += "Nvidia Control Pannel not Installed. "
            $testValue = "FAILED"
        }

        return Format-ResultsOutput -Result $testValue -Message "$($returnMessage)"  -pathToImage $pathToImageStore
    }elseif(-not $hw){
        # An error occured when calling AssertHardware, so we cannot carry out the test
        return Format-ResultsOutput -Result "BLOCKED" -Message "Cannot poll GPU as d3HardwareValidation has not been imported correctly."
    }
    else{
        # AMD STUFF - Not implemented yet.
        # Write-Error "GPU Detected as AMD (or at least not NVIDIA). This functionality hasn't been implemented yet. Implement it?"
        return Format-ResultsOutput -Result "BLOCKED" -Message "GPU Detected as AMD (or at least not NVIDIA). This functionality hasn't been implemented yet."
    }
}



<# How it works:
1. Import the machine config 
2. See if it needs to test this model of capture cards
    a. if it doesnt return "WON'T TEST"
3. See if there are specific capture cards installed in device manager
    a. if not return "FAILED"
4. See if the required program is installed. This is gathered from the config.yaml
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $homeURL = $testConfig.Windows_settings.chrome_home_url
5. gather evidence and save
6. return "PASSED"
#>
Function Test-CaptureCard{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$CaptureCardManufacturer,
        [Parameter(Mandatory=$true)]
        [String]$pathToOSValidationTemplate
    )
    # Inital data manipulation
    $CaptureCardManufacturer = $CaptureCardManufacturer.ToUpper()


    # Gathering the model config
    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject

    # If we dont need to test it we return this
    if(-not ($modelConfig.usesCaptureCards) -or ($modelConfig.AllowedCaptureCardTypes -notcontains $CaptureCardManufacturer)){
        return Format-ResultsOutput -Result "WON'T TEST" -Message "Model config file indicates this machine does not use capture cards."
    }

    # Now we check in device manager
    $path = Format-disguiseModulePathForImport -RepoName "disguisedPower" -ModuleName "d3CaptureCards"
    Import-Module $path
    $path = Format-disguiseModulePathForImport -RepoName "disguisedPower" -ModuleName "disUtils"
    Import-Module $path

    $captureCards = Get-CaptureCards

    # Check it returned 
    if(-not $captureCards){
        return Format-ResultsOutput -Result "FAILED" -Message "No [$($CaptureCardManufacturer)] devices in device manager (gathered via Get-CaptureCards)"
    }

    # Pull the required app from the config yaml
    $testConfig = Get-ConfigYAMLAsPSObject
    $dotIndexExtension = "$($CaptureCardManufacturer)_apps"
    $captureApps = $testConfig.devices_settings.$dotIndexExtension  #<--

    $returnString = ""
    $testValue = "PASSED"
    # loop through all the apps we need to test
    $pathToAppsArray = @()
    foreach($app in $captureApps){
        # Instantiate the process to ensure it is clear at the start of each loop
        $process = $null
        start-process "$($app).exe"
        # We want to check if the user has put in a path to the exe, or just the exe name
        if((test-path "$($app).exe") -and ($app -match "\\")){
            # If it is a path, we need to strip out the final exe name
            $app = $app.substring($app.LastIndexOf("\")+1,$app.length-$app.LastIndexOf("\")-1)
        }
        $process = Get-Process | Where-Object {$_.ProcessName -eq $app} 
        start-sleep -Seconds 2
        # if the app has started
        if($process){
            $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
            $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "$($app)_$($timestamp).bmp"
            $pathToAppsArray += $pathToImageStore
            Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore | Out-Null
            Stop-Process -Name $process.Name | Out-Null
            Wait-Process -Name $process.Name | Out-Null
            
        }else{
            $returnString += "$($app) - FAILED: could not start app. "
            $testValue = "FAILED"
        }
    }

    # Now we need to verify the driver version 
    $captureDriverTemplate = (Import-OSValidationTemplate -PathToTemplateFile $pathToOSValidationTemplate).PackageVersions | Where-Object {$_.sharedPackageHandle.ToUpper() -match ("$($CaptureCardManufacturer)_Driver").ToUpper()} 

    $captureCardDriverModified = $captureCards.DriverVersion -replace 'v', ' '

    if(-not(Compare-Versions -Version1 $captureCardDriverModified -Version2 $captureDriverTemplate.publicPackageVersion -equal)){
        $returnString += "Capture card [$($captureCards.Model)]'s driver version detected as: [$([Version]$captureCardDriverModified)]. This is different to the required version: [$([Version]$captureDriverTemplate.publicPackageVersion)] as found in choco package [$($captureDriverTemplate.sharedPackageHandle)]'s [publicPackageVersion]. "
        $testValue = "FAILED"
    }else{
        $returnString += "Capture card [$($captureCards.Model)]'s version detected as: [$([Version]$captureCardDriverModified)]. Choco package [$($CaptureCardManufacturer)_Driver]'s [publicPackageVersion]: [$([Version]$captureDriverTemplate.publicPackageVersion)] "
    }
    
    return Format-ResultsOutput -Result "$testValue" -Message "$($returnString)" -pathToImageArr $pathToAppsArray
}

Function Test-AudioCard{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$pathToOSValidationTemplate
    )
    # Make sure the test is required
    if(-not (Import-ModelConfig -ReturnAsPowershellObject).usesHammerfallAudio){
        return Format-ResultsOutput -Result "WON'T TEST" -Message "Machine's config file indicates it does not use an audio card."
    }

    # Import the required modules
    $path = Format-disguiseModulePathForImport -RepoName "disguisedPower" -ModuleName "disguiseAudio"
    Import-Module $path -Force
    $path = Format-disguiseModulePathForImport -RepoName "disguisedPower" -ModuleName "disUtils"
    Import-Module $path

    # get the cards
    $audioCard = Get-DisguiseAudioCards
    # if theyre not an array, convert to one just in case we implement multiple card machines
    if($audioCard.GetType().BaseType -notmatch "Array"){
        $audioCard = @($audioCard)
    }

    # Get the chocolatey template for RME Audio
    $audioTemplate = (Import-OSValidationTemplate -PathToTemplateFile $pathToOSValidationTemplate).PackageVersions | Where-Object {$_.sharedPackageHandle.ToUpper() -match ("$($audioCard[0].Manufacturer)").ToUpper()} 
    if(-not $audioTemplate){
        Write-Error "Cannot find chocolatey package where the sharedPackageHandle matches with [$($audioCard[0].Manufacturer)]. The model specific config indicates it needs an audio card. Please check chocolatey packages to ensure it is there. Marking test as failed."
        $returnString = "Cannot find chocolatey package where the sharedPackageHandle matches with [$($audioCard[0].Manufacturer)]. The model specific config indicates it needs an audio card. Please check chocolatey packages to ensure it is there. Marking test as failed."
        $testValue = "FAILED"
        return Format-ResultsOutput -Result "$testValue" -Message "$($returnString)"
    }

    if(-not $audioTemplate.osValidationPackageVersion){
        $returnString = "Chocolatey package [$($audioTemplate.sharedPackageHandle)]'s [osValidationPackageVersion] cannot be found. This indicates it is not filled in on OSBuilder. The function cannot be completed without this. Please enter into OSBuilder or complete test manually `n`nActual Driver Version: $($card.DriverVersion)"
        write-host $returnString
        $testValue = "FAILED"
        return Format-ResultsOutput -Result "$testValue" -Message "$($returnString)"
    }

    $returnString = ""
    $testValue = "PASSED"

    foreach($card in $audioCard){
        Write-Host "Actual Driver Version: $($card.DriverVersion)"
        Write-Host "Required Driver Version: $($audioTemplate.osValidationPackageVersion)"
        if(-not(Compare-Versions -Version1 $card.DriverVersion -Version2 $audioTemplate.osValidationPackageVersion -equal)){
            $returnString += "Audio card [$($card.Name)]'s driver version detected as: [$([Version]$card.DriverVersion)]. This is different to the required version: [$([Version]$audioTemplate.osValidationPackageVersion)] as found in choco package [$($card.Manufacturer)]'s [publicPackageVersion]. "
            $testValue = "FAILED"
            write-host $returnString
        }else{
            $returnString += "Audio card [$($card.Name)]'s version detected as: [$([Version]$card.DriverVersion)]. Choco package's required version is [$($card.Manufacturer)_Driver]'s [publicPackageVersion]: [$([Version]$audioTemplate.osValidationPackageVersion)] "
        }
    }
    return Format-ResultsOutput -Result "$testValue" -Message "$($returnString)"
}

Function Test-DeviceManagerDriverVersions {
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$pathToOSValidationTemplate
    )

    # Dot-Source the ps1 file into a powershell object variable
    $OSValidationTemplatePSObject = ( . $pathToOSValidationTemplate )
    if( -not $OSValidationTemplatePSObject ) {
        return Format-ResultsOutput -Result "FAILED" -Message "ERROR: Could not load the Powershell OS Validation Template file [$( $pathToOSValidationTemplate )]. Either the file must be missing or it contains invalid powershell code."
    }

    # Get Config YAML as PS Object
    $configYAMLPSObject = Get-ConfigYAMLAsPSObject

    $testrailFeedbacktext = "----------------------------------------------------------------------------------"

    # Check for '01-Drivers' choco packages with missing Hardware IDs and add a warning to the test feedback string
    [string[]]$packageHandlesToIgnore = $configYAMLPSObject.driver_choco_package_handle_automated_device_manager_version_test_blocklist
    $driverPackagesWithMissingHardwareIDs = $OSValidationTemplatePSObject.PackageVersions | Where-Object {
                                                $_.category -like '*Driver*' -and
                                                -not ( [string]($_.chocoPackageHandle  ) -in [string[]]$packageHandlesToIgnore ) -and
                                                -not ( [string]($_.sharedPackageHandle ) -in [string[]]$packageHandlesToIgnore ) -and
                                                -not ( $_.HardwareComponentHardwareIDs )
                                            }

    #Add a warning to the feedback if some of the chocolatey packages dont have any hardware components associated with any HardwareIDs
    if( $driverPackagesWithMissingHardwareIDs ) {
        $testrailFeedbacktext += "`n`n** TEST BLOCKED **`n`nTHE FOLLOWING [01-Drivers] CHOCO PACKAGES DO NOT HAVE HARDWARE IDs ASSOCIATED WITH THEM FOR THIS OS.`nPlease either:`n - Add this machine's Hardware ID(s) to the relevant Hardware Components in OSBuilder`n - Or add either the Package Handle or Shared External Handle to the blocklist in the OSValidation Config File [OSValidation\config\config.yaml]`n`n"
        $testrailFeedbacktext += ( $driverPackagesWithMissingHardwareIDs | 
                                   Select-Object @{Name='Choco Package Name'; Expression='friendlyName'},
                                                 @{Name='Package Handle'; Expression='chocoPackageHandle'}, 
                                                 @{Name='Shared External Handle'; Expression='sharedPackageHandle'}, 
                                                 @{Name='Expected Version'; Expression='osValidationPackageVersion'} |
                                    Format-Table | Out-String 
                                 ).Trim()
        $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"
    }

    # Now fetch all choco packages with HardwareIDs attached, that arent in the blocklist
    $allPackagesWithHardwareIDs = $OSValidationTemplatePSObject.PackageVersions | Where-Object {
        -not ( [string]($_.chocoPackageHandle  ) -in [string[]]$packageHandlesToIgnore ) -and
        -not ( [string]($_.sharedPackageHandle ) -in [string[]]$packageHandlesToIgnore ) -and
        ( [String[]]( $_.HardwareComponentHardwareIDs ).Length -gt 0 )
    }

    # Get a list of all devices in Device Manager
    [CimInstance[]]$deviceManagerDevicePSObjects = Get-PNPDevice

    # Loop through all non-blocklisted choco packages with HardwareIDs attached, so that we can search for them in device manager
    $imageArray = [string[]]@()
    foreach( $packageObject in [PSCustomObject[]]$allPackagesWithHardwareIDs ) {

        #Get Sanitised list of Hardware IDs for this Package and add the number of possible hardwareids to the package object in case we want to report on it later
        [string[]]$thisPackagesPossibleHardwareIDs = $packageObject.HardwareComponentHardwareIDs | Where-Object { [bool]( ([string]$_).Trim() ) } | Select-Object -Unique #Remove Blanks and De-Duplicate the list just in case
        $packageObject | Add-Member -Type NoteProperty -Name 'noOfPossibleHardwareIDs' -Value $thisPackagesPossibleHardwareIDs.Length
        
        #Get list of PNPDevices whose InstanceIDs begin with at least one of the hardwareIDs
        $matchingPNPDevices = [CimInstance[]]@()
        foreach( $hardwareID in [string[]]$thisPackagesPossibleHardwareIDs ) {
            [CimInstance[]]$matchingPNPDevices += [CimInstance[]]( $deviceManagerDevicePSObjects | Where-Object { $_.HardwareId -like "$( $hardwareID )*"  } )
        }
        # Now Deduplicate the list of matching devices
        [CimInstance[]]$matchingPNPDevices = [CimInstance[]]$matchingPNPDevices | Sort-Object  -Unique

        # add the number of found devices to the package object in case we want to report on it later (also the device name if only one matched)
        # DEBUG: Write-Host "Matching Devices: $($matchingPNPDevices.Length)"
        $packageObject | Add-Member -Type NoteProperty -Name 'noOfFoundDevices' -Value $matchingPNPDevices.Length
        $matchedDeviceDescription = "None"
        if( $matchingPNPDevices.Length -eq 1 ) {
            $matchedDeviceDescription = $matchingPNPDevices[0].FriendlyName
        }
        if( $matchingPNPDevices.Length -gt 1 ) {
            $matchedDeviceDescription = "MULTIPLE DEVICES"
        }
        $packageObject | Add-Member -Type NoteProperty -Name 'foundDeviceName' -Value $matchedDeviceDescription
        $packageObject | Add-Member -Type NoteProperty -Name 'allFoundDeviceNames' -Value "[$( ( [string[]]$matchingPNPDevices.FriendlyName ) -join '], [' )]"
        
        #Now look through all the matching devices for ones with drivers, and check if the driver has a matching version
        [CimInstance[]]$devicesWithMatchingDriverVersions = [CimInstance[]]@()
        [string[]]$allDriverVersions = @()
        foreach( $device in $matchingPNPDevices ) {
            [string[]]$thisDevicesDriverVersions += [string[]]( ( Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceID -eq $Device.InstanceId } ).DriverVersion )
            [string[]]$allDriverVersions += [string[]]$thisDevicesDriverVersions
            if( [string]$packageObject.osValidationPackageVersion -in [string[]]$thisDevicesDriverVersions ) {
                [CimInstance[]]$devicesWithMatchingDriverVersions += [CimInstance]$device
            }
        }
        # Now Deduplicate the list of matching devices
        [string[]]$allDriverVersions = [string[]]$allDriverVersions | Sort-Object  -Unique        
        
        # Add the number of found Driver Versions to the package object in case we want to report on it later (also the device name if only one matched)
        # DEBUG: Write-Host "Found Driver Versions: $($allDriverVersions.Length)"
        # DEBUG: Write-Host "All Driver Versions for these Devices: [$( $allDriverVersions -join '], [' )]"
        $packageObject | Add-Member -Type NoteProperty -Name 'noOfFoundDriverVersions' -Value $allDriverVersions.Length
        $matchedDriverVersion = "None"
        if( ([string[]]$allDriverVersions).Length -eq 1 ) {
            $matchedDriverVersion = ([string[]]$allDriverVersions)[0]
        }
        if( ([string[]]$allDriverVersions).Length -gt 1 ) {
            $matchedDriverVersion = "MULTIPLE VERSIONS"
        }
        $packageObject | Add-Member -Type NoteProperty -Name 'foundDriverVersion' -Value $matchedDriverVersion
        $packageObject | Add-Member -Type NoteProperty -Name 'allFoundDriverVersions' -Value "[$( $allDriverVersions -join '], [' )]"

        # Is the correct driver version installed? ie Is at least one Driver Version for at least one matching Device exactly the same as osValidationPackageVersion fromt he OSValidationTemplate.ps1 choco package object
        $finalReuslt = if( [string]$packageObject.osValidationPackageVersion -in [string[]]$allDriverVersions ) { 'PASS' } else { 'FAIL' }
        if( $matchingPNPDevices.Length -eq 0 ) {
            #if its a fail because we couldnt find any devices matching the HardwareIds the set this record to BLOCKED instead of pass or fail because it means the user needs to add a hardware id to OS Builder
            $finalReuslt = 'BLOCKED'
        }

        $packageObject | Add-Member -Type NoteProperty -Name 'result' -Value $finalReuslt

        #Take device manager device properties screenshot(s) for the found device if it's a PASS
        if( $finalReuslt -eq 'PASS' ) {
            foreach( $device in [CimInstance[]]$devicesWithMatchingDriverVersions ) {
                [string[]]$imageArray += [string]( Get-DeviceManagerDevicePropertiesScreenShotsAsSingleImage -DeviceHardwareId $device.InstanceID -DeviceNameFileNameInsert $device.FriendlyName ).Trim()
            }
        }
    }

    #Now that we have completed searching for all matching devices and driver versions, we can calculate the final result
    $overallResult = 'PASSED'
    if( [string[]]$allPackagesWithHardwareIDs.result -contains 'FAIL' ) {
        $overallResult = 'FAILED'
    }
    elseif( $driverPackagesWithMissingHardwareIDs -or ( [string[]]$allPackagesWithHardwareIDs.result -contains 'BLOCKED' ) ) {
        $overallResult = 'BLOCKED'
    }

    #Add the overall results table to the testrail resposne text
    $testrailFeedbacktext += "`n`nFINAL RESULTS TABLE:`n`n"
    $testrailFeedbacktext += ( $allPackagesWithHardwareIDs | 
                               Select-Object @{Name='Result'; Expression='result'},
                                             @{Name='Choco Package Name'; Expression='friendlyName'},
                                             @{Name='Found Device on this Machine'; Expression='foundDeviceName'}, 
                                             @{Name='Expected Version'; Expression='osValidationPackageVersion'},
                                             @{Name='Found Version'; Expression='foundDriverVersion'} |
                               Format-Table * | Out-String -Width 1024
                             ).Trim()
    $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"

    #if some of the tests came back blocked then the user needs to add some hardware ids to OSBuilder
    [PSCustomObject[]]$blockedTests = ( $allPackagesWithHardwareIDs | Where-Object { $_.result -eq 'BLOCKED' } )
    if( $blockedTests ) {
        #Add the overall results table to the testrail resposne text
        $testrailFeedbacktext += "`n`nNO DEVICES COULD BE FOUND ON YOUR SYSTEM MATCHING THE FOLLOWING PACKAGES:`nPlease add the HardwareID of the Appropriate Device on this machine to the appropriate Hardware Component in OSBuilder then try again.`n`n"
        foreach( $blockedTest in $blockedTests ) {
            $testrailFeedbacktext += "Choco Package         : $( $blockedTest.friendlyName )`n"
            $hardwareIDPrefix =      "Possible Hardware IDs : "
            $blockedTest.HardwareComponentHardwareIDs | Foreach-Object {
                $testrailFeedbacktext += "$( $hardwareIDPrefix )[$( $_ )]`n"
                $hardwareIDPrefix =  "                        "
            }
            $testrailFeedbacktext += "`n"
        }
        $testrailFeedbacktext += "----------------------------------------------------------------------------------"
    }

    #Add the overall results table to the testrail resposne text
    if( $allPackagesWithHardwareIDs | Where-Object { $_.result -eq 'FAIL' } ) {
        $testrailFeedbacktext += "`n`nTHE FOLLOWING TABLE LISTS A DETAILED BREAKDOWN OF EACH TEST THAT FAILED:`n`n"
        $testrailFeedbacktext += ( $allPackagesWithHardwareIDs | Where-Object { $_.result -eq 'FAIL' } | 
                                Select-Object @{Name='Package Category'; Expression='category'},
                                                @{Name='Package Name'; Expression='friendlyName'},
                                                @{Name='Package Handle'; Expression='chocoPackageHandle'},
                                                @{Name='Shared External Handle'; Expression='sharedPackageHandle'},
                                                @{Name='Version Choco Handle'; Expression='chocoPackageVersion'},
                                                @{Name='Version Public Name'; Expression='publicPackageVersion'},
                                                @{Name='Version Expected in Device Namager'; Expression='osValidationPackageVersion'},
                                                @{Name='Possible HardwareIDs'; Expression='HardwareComponentHardwareIDs'},
                                                @{Name='# of Found Devices'; Expression='noOfFoundDevices'},
                                                @{Name='Found Device Name'; Expression='foundDeviceName'}, 
                                                @{Name='All Found Device Names'; Expression='allFoundDeviceNames'}, 
                                                @{Name='# of Found Versions'; Expression='noOfFoundDriverVersions'},
                                                @{Name='Found Version'; Expression='foundDeviceName'}, 
                                                @{Name='All Found Versions'; Expression='allFoundDriverVersions'}, 
                                                @{Name='Result'; Expression='result'} |
                                Format-List * | Out-String 
                                ).Trim()
        $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"
    }
    #dust for debugging, doent get printed during normal execution
    Write-Verbose $testrailFeedbacktext

    return Format-ResultsOutput -Result $overallResult -Message $testrailFeedbacktext -pathToImageArr $imageArray
}

Function Test-ProblemDevices {
    param(        
    )
    $ProblemPNPDevices = Get-PnpDevice | Where-Object  { ( $_.Status -eq "ERROR") -or #this is the same check as ConfigManagerErrorCode but we're just being super cautious here
                                                      ( $_.Status -eq "DEGRADED") -or
                                                      ( ( [int]($_.ConfigManagerErrorCode) -ne 0 ) -and ( [int]($_.ConfigManagerErrorCode) -ne 45 ) ) #0 = working, 45 = virtual device (not physical component) both of which are allowed statuses
                                                    } 

    $problemDevices = [PSCustomObject[]]@()
    $allowedDevices = [PSCustomObject[]]@()
    $allowedDeviceAndWarning =  @()
    $index = 0
    foreach($allowedDevice in ( Get-ConfigYAMLAsPSObject ).devices_settings.allowed_warning_on_device){
        $allowedDeviceAndWarning += [PSCustomObject]@{
            Name = $allowedDevice[0]
            AllowedCode = $allowedDevice[1]
        }
    }
    

    # Loop through all the devices that are error or degraded status
    foreach($device in $ProblemPNPDevices){

        #Is there a full match by name and status in the config file
        [PSCustomObject[]]$fullyMatchingWhitelistEntries = [PSCustomObject[]]( $allowedDeviceAndWarning | Where-Object { ( $device.FriendlyName -eq $_.Name ) -and ( $device.Status -eq $deviceAndWarning.AllowedCode ) } )
        if( $fullyMatchingWhitelistEntries.Length ) {
            $allowedDevices += [PSCustomObject]@{
                Name = $device.FriendlyName
                DeviceClass = $device.Class
                Status = $device.Status
                Note = ""
            }
        }
        else{
            [PSCustomObject[]]$partiallyMatchingWhitelistEntries = [PSCustomObject[]]( $allowedDeviceAndWarning | Where-Object { ( $device.FriendlyName -eq $_.Name ) } )
            if( $partiallyMatchingWhitelistEntries.Length ) {
                $problemDevices += [PSCustomObject]@{
                    Name = $device.FriendlyName
                    DeviceClass = $device.Class
                    Status = $device.Status
                    Note = "In the [config.yaml] Config file, We allow a status of [$( $fullyMatchingWhitelistEntries.Status -join ']/[' )] for device [$($device.FriendlyName)], however its actual status is $( $device.Status )"
                }
            }
            else{
                #An unauthorised problem device - not in the whitelist at all
                $problemDevices += [PSCustomObject]@{
                    Name = $device.FriendlyName
                    DeviceClass = $device.Class
                    Status = $device.Status
                    Note = "[$( $device.FriendlyName )] (which has a Status of [$( $device.Status )]) does not appear in the list of allowed problem devices in the [config.yaml] Config file"
                }
            }
        }

        $index++
    }

    $overallPass = if($problemDevices){"FAILED"}else{"PASSED"}
    $message = @"
---------------------------------------------------------------------
                     Device Manager Inspection
---------------------------------------------------------------------
Test Result:                            REPLACEMENT1
Number of Problem Devices:              REPLACEMENT2

------------------------------------------------
Disallowed Problem Devices: 
------------------------------------------------

"@
    $message = $message -replace "REPLACEMENT1", $overallPass
    $problemDevicesTally = "$( $allowedDevices.Length + $allowedDevices.Length ) ($($problemDevices.Length) Disallowed / $($allowedDevices.Length) Allowed)"
    $message = $message -replace "REPLACEMENT2", $problemDevicesTally

    if($problemDevices){
        $message += ( $problemDevices | Format-List * | Out-String ).Trim()
    }else{
        $message += " - No devices reporting as [ERROR] or [DEGRADED]"
    }


    # Creating the allowed device table
    $message += @"


------------------------------------------------
Allowed Devices and Status (in Allowlist):
------------------------------------------------

"@
    if($allowedDevices){
        $message += ( $allowedDevices | Format-Table | Out-String ).Trim()
    }else{
        $Message += " - No devices found that match the allow-list"
    }
    

    # Creating the config value table for easy readin
    $message += @"


------------------------------------------------
Allow-List to be Checked Against:
------------------------------------------------
"@
    $message += $allowedDeviceAndWarning | Format-Table | Out-String


    #Finally, export a full list of devices to upload as an attachment as evidence
    #get temp filename and path
    $OSValidationConfig = Import-OSValidatonConfig
    $TempImageStoreRootDir = $OSValidationConfig.pathToOSValidationTempImageStore
    $filenameSuffixTimestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
    [string]$deviceHealthfileToUploadPath = Join-Path $TempImageStoreRootDir "ALL_DEVICES_HEALTH__$($filenameSuffixTimestamp).txt"
    #generate query and stip answer out to file
    $allPNPDevices = [PSCustomObject]( Get-PNPDevice )
    foreach( $device in $allPNPDevices ) {
        $stateOfDevice = if( $device.Status -eq "Unknown" -and [int]( $device.ConfigManagerErrorCode -eq 45 ) ) { "Virtual" } else { $device.Status }
        $device | Add-Member -MemberType NoteProperty -Name "State" -Value $stateOfDevice
    }
    $allPNPDevices |
        Sort-Object -Property @{Expression = "Class"; Descending = $false}, @{Expression = "Name"; Descending = $false} |
        Select-Object Class, Name, State |
        Out-File -FilePath $deviceHealthfileToUploadPath

    [string[]]$allFilesToUpload = [string[]]@( $deviceHealthfileToUploadPath )

    #Return results and path to attchment
    return $message
    return Format-ResultsOutput -Result $overallPass -Message $message -pathToImageArr $allFilesToUpload
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

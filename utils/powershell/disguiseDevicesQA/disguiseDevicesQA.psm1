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
    $testConfig = Import-Yaml -configYamlPath ".\config\config.yaml"
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



# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

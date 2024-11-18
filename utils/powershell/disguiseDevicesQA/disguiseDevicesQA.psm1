# Implement your module commands in this script.
$d3ModelConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3ModelConfigImporter"
$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
Import-Module $d3ModelConfigPath -Force
Import-Module $d3OSQAUtilsPath -Force

function Test-GraphicsCardControlPannel{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    $path = Format-disguiseModulePathForImport -RepoName "disguisedsec" -ModuleName "d3HardwareValidation"
    Import-Module $path
    $hw = Assert-Hardware
    if($hw.gpu.Manufacturer -eq "NVIDIA"){
        $process = $null

        Get-AppxPackage 'NVIDIACorp.NVIDIAControlPanel' | % { 
            Copy-Item -LiteralPath $_.InstallLocation -Destination $Env:USERPROFILE\Desktop -Recurse -Force  | Out-Null
            Start-Process "$Env:USERPROFILE\Desktop\NVIDIACorp.NVIDIAControlPanel_*\nvcplui.exe"  | Out-Null
        }
        
        $process = Get-Process | Where-Object {$_.ProcessName -eq "nvcplui"} 
        start-sleep -Seconds 2

        if($process){
            $path = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Devices\" -ChildPath "NvidiaControlPannel.bmp"
            Get-PrintScreenandRetryIfFailed -PathAndFileName $path | Out-Null
            Stop-Process -Name $process.Name | Out-Null
            Wait-Process -Name $process.Name | Out-Null
        }

        $command = {Remove-Item "$Env:USERPROFILE\Desktop\NVIDIACorp.NVIDIAControlPanel_*" -Force -Recurse -WarningAction Continue}
        Invoke-Command -ScriptBlock $command | Out-Null

        if($process){
            return "PASSED"
        }else{
            return "FAILED"
        }
    }
    else{
        # AMD STUFF
        Write-Error "GPU Detected as AMD (or atleast not NVIDIA). This hasn't been implemented yet. Implement it?"
        return "UNTESTED"
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
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName,
        [Parameter(Mandatory=$true)]
        [String]$CaptureCardManufacturer
    )
    # Inital data manipulation
    $CaptureCardManufacturer = $CaptureCardManufacturer.ToUpper()


    # Gathering the model config
    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject

    # If we dont need to test it we return this
    if(-not ($modelConfig.usesCaptureCards) -or ($modelConfig.AllowedCaptureCardTypes -notcontains $CaptureCardManufacturer)){
        return "WON'T TEST"
    }
    # Only machines containing MATROX in their model configs should be passed into this section
    # Now we check in device manager
    $path = Format-disguiseModulePathForImport -RepoName "disguisedPower" -ModuleName "d3CaptureCards"
    Import-Module $path
    $captureCards = Get-CaptureCards
    # Check it returned 
    if(-not $captureCards){
        return "FAILED - No [$($CaptureCardManufacturer)] devices in device manager (gathered via Get-CaptureCards)"
    }

    # Pull the required app from the config yaml
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $dotIndexExtension = "$($CaptureCardManufacturer)_apps"
    $captureApps = $testConfig.devices_settings.$dotIndexExtension  #<--

    $returnString = ""
    # loop through all the apps we need to test
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
            $path = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Devices\" -ChildPath "$($app).bmp"
            Get-PrintScreenandRetryIfFailed -PathAndFileName $path | Out-Null
            Stop-Process -Name $process.Name | Out-Null
            Wait-Process -Name $process.Name | Out-Null
            $returnString += "$($app) - REQUIRE MORE INFO: Please manually check driver version."
        }else{
            $returnString += "$($app) - FAILED: could not start app. "
        }
    }

    # 
    
    return $returnString
}

function Read-PublicVersionTable{
    param(        
        [Parameter(Mandatory=$false)]
        [String]$PathToPublicVersionTable = "..\..\..\config\PublicVersionTable.ps1"
    )
    if(-not (Test-Path $PathToPublicVersionTable)){
        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); 
        $PathToPublicVersionTable = [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the path to the Version Table OS Validation Config generated via OSBuilder (OS Build -> Select OS Build -> Public Version Table -> Export OS Validation Config. Then copy and paste into a text file and save):', 'Path to Exported OS Validation Config')
    }
    
    $contents = . $PathToPublicVersionTable
    return $contents
}



# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

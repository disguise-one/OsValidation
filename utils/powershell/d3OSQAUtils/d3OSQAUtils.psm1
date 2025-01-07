# Implement your module commands in this script.
try{
    Import-Module powershell-yaml -ErrorAction Stop
}catch{
    Install-Module powershell-yaml
    Import-Module powershell-yaml
}


function Get-PrintScreenandRetryIfFailed{
    param(
        [Parameter(Mandatory=$true)]
        [String]$PathAndFileName,
        [Parameter(Mandatory=$false)]
        [int]$retries = 20
    )

    for($i = 0; $i -le $retries; $i++){
        # Write-Host "Capturing Evidence"
        $isImageSavedSuccessully = Get-PrintScreen -PathAndFileName $PathAndFileName
        if($isImageSavedSuccessully){
            return $true
        }
        # Write-Host "Capture Evidence Failed, retrying..."
    }

    return $false
}

function Get-PrintScreen{
    param(
        [Parameter(Mandatory=$true)]
        [String]$PathAndFileName
    )

    # First check the path exists, we need to strip the file location off, so we only have the directory path
    $PathDirectory = $PathAndFileName.Substring(0,$PathAndFileName.LastIndexOf('\')+1)
    if(-not(Test-Path -Path $PathDirectory)){
        # If it doesnt we make it, 
        New-Item -Path $PathDirectory -ItemType "directory"
    }

    <#
        As we cannot use more sophisticated methods to grab the screen contents (due to antivirus saying we cant), 
        we are spoofing a keyboard call of print screen, using the inbuilt microsoft function
    #>

    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("^{PRTSC}")

    # Now the image is in the buffer, we need to save it
    start-sleep -Milliseconds 500
    # Attempt to read from the buffer. If it fails just exit out of the function and try again
    try{
        $imageFullObject = Get-Clipboard -Format image
    }catch{
        return $false
    }


    #Save the bitmap
    try{
        $imageFullObject.Save($PathAndFileName)
        return $true
    }catch {
        # Write-Host "Get-PrintScreen: Error:"
        # Write-Host $_
        return $false
    }
}

function Format-ResultsOutput{
    param(
        [Parameter(Mandatory=$true)]
        [String]$Result,
        [Parameter(Mandatory=$true)]
        [String]$Message,
        [Parameter(Mandatory=$false)]
        [String]$pathToImage = "",
        [Parameter(Mandatory=$false)]
        [String[]]$pathToImageArr,
        [Parameter(Mandatory=$false)]
        [Switch]$ReturnAsPowershellObject
    )

    if($pathToImage){
        $pathToImageArr = @($pathToImage)
    }

    $resultsObject = [PSCustomObject]@{
        OverallResult = $Result
        Message = $Message
        PathToImage = $pathToImageArr
    }
    


    if($ReturnAsPowershellObject){
        return $resultsObject
    }else{
        return $resultsObject | ConvertTo-Json -Compress
    }
}

#Function to tell if we're on windows 10 or windows 11
function Get-WindowsVersionInfo {
    [version]$OSVersion = [Environment]::OSVersion.Version

    return @{
        MicrosoftVersioningMajorNumber = $OSVersion.Major
        MicrosoftVersioningMinorNumber = $OSVersion.Minor
        MicrosoftVersioninBuildNumber = $OSVersion.Build
        WindowsVersion = if( $OSVersion.Major -eq 10 -and $OSVersion.Build -ge 22000 ) { 11 } else { $OSVersion.Major } 
    }
}

function Get-ConfigYAMLAsPSObject {
    $configYAMLPath = Join-Path $PSScriptRoot "..\..\..\config\config.yaml"
    $testConfig = Get-Content -Path $configYAMLPath | ConvertFrom-Yaml
    return $testConfig
}

function Import-OSValidatonConfig{
    $OSOalidationConfigJSONPath = Join-Path $PSScriptRoot "..\..\..\config\OSvalidationConfig.json"
    $config = Get-Content -Path $OSOalidationConfigJSONPath | ConvertFrom-Json
    return $config
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

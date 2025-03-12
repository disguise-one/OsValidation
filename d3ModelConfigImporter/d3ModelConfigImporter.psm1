$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
Import-Module $d3OSQAUtilsPath -Force

# This module is made to aid with importing disguisePower model configs into python
# Additionally there will be a function to import any module from sec or power, given a switch

#We will use this function to achieve this. The function will take in the path to 
function Import-ModelConfig{
    param(
        [Parameter(Mandatory=$false)]
        [String]$PathToConfigFileFromOSValidationRoot = "..\disguisedpower\disguiseConfig",        
        [Parameter(Mandatory=$false)]
        [Switch]$ReturnAsPowershellObject
    )

    # We modify the path as it is being executed inside the d3ModelCOnfigImporter file
    # $modifiedPath = Join-Path -Path $Global:DisguiseConfig.pathToDisguisePowerAndSecParentDir -ChildPath $PathToConfigFileFromOSValidationRoot
    #$modifiedPath = $PathToConfigFileFromOSValidationRoot
    $modifiedPath = Join-Path -Path $Global:OSValidationConfig.disguisedPowerPath -ChildPath "\disguiseConfig"

    #Import all the config files, via already established methods -> see disguisePower config for info on this
    try{
        Import-Module $modifiedPath -Force
    }catch{
        return "Error: Path [$($modifiedPath)] not found"
    }

    #Cast the config file to a PSCustomObject -> String in json format
    # Want to remove all the extra postboot scripts, as they are converted to powershell code which is inside the string. Unnessesary
    $configObject = [PSCustomObject]$Global:DisguiseConfig.getHardwarePlatformConfig()
    $configObject = $configObject | Select-Object -Property * -ExcludeProperty PostbootExtrasScriptBlock | Select-Object -Property * -ExcludeProperty Post_Reboot_Script_Block
    $configString = $configObject | ConvertTo-Json 

    if($ReturnAsPowershellObject){
        return $configObject
    }else{
        return $configString
    }
}

function Import-OSValidationTemplate{
    param(
        [Parameter(Mandatory=$false)]
        [String]$PathToTemplateFile = "C:\Windows\Temp\OSValidationTemplate.ps1"
    )

    $PathToTemplateFile = if($PathToTemplateFile -match '\\'){$PathToTemplateFile -replace '\\', '\'}

    $object = . $PathToTemplateFile
    return $object

}

# This should be called from anythin INSIDE the powershell folder
function Format-disguiseModulePathForImport{
    param(
        [Parameter(Mandatory=$true)]
        [String]$RepoName,        
        [Parameter(Mandatory=$true)]
        [String]$ModuleName
    )

    # first create the repo path
    $RepoPath = Join-Path -path $Global:DisguiseConfig.pathToDisguisePowerAndSecParentDir -ChildPath $RepoName
    if(-not(Test-Path $RepoPath)){
        Write-Error "The Repo [$($RepoName)] cannot be found at relative path [$($RepoPath)] please check it exists and ensure you are calling this function from inside a script located in [utils\powershell] or any of it's subdirectories"
        return $false
    }

    # Now create the module path
    $modulePath = Join-Path -path $RepoPath -ChildPath $ModuleName
    if(-not(Test-Path $modulePath)){
        Write-Error "The Module [$($ModuleName)] cannot be found at relative path [$($modulePath)] please check it exists and ensure you are calling this function from inside a script located in [utils\powershell] or any of it's subdirectories"
        return $false
    }
    
    return $modulePath
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

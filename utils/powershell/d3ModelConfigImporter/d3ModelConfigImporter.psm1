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
    # $modifiedPath = Join-Path -Path "..\..\..\" -ChildPath $PathToConfigFileFromOSValidationRoot
    $modifiedPath = $PathToConfigFileFromOSValidationRoot

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

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

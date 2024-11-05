param(
    [Parameter(Mandatory=$false)]
    [string]$KeyName,
    [Parameter(Mandatory=$false)]
    [switch]$EnforceReturnValueAsArray
)

# Import the required module
Import-Module \\d3deploy2\Deploymentshare\disguisedpower\disguiseConfig -Force

# Determine whether to fetch specific or all configuration data
$returnValue = if ($KeyName) {
    $Global:DisguiseConfig.getHardwarePlatformConfig().($KeyName)
} else {
    $Global:DisguiseConfig.getHardwarePlatformConfig()
}

# Process and return the fetched data
if ($returnValue -or $returnValue -is [array]) {
    # If EnforceReturnValueAsArray is specified and returnValue is not an array or is empty
    if ($EnforceReturnValueAsArray -and ($returnValue -isnot [array] -or $returnValue.Count -le 0)) {
        $returnValue = @($returnValue)  # Convert returnValue to an array
    }

    # Convert returnValue to JSON and return
    return , $returnValue | ConvertTo-Json
} else {
    # Return a message if the key is not found (or if there's no data)
    $message = if ($KeyName) { "Key Value [$KeyName] could not be found" } else { "No configuration data found" }
    return $message | ConvertTo-Json
}

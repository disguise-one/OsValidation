param(
    [Parameter(Mandatory=$true)]
    [string]$KeyName,
    [Parameter(Mandatory=$false)]
    [switch]$EnforceReturnValueAsArray
)

Import-Module \\d3deploy2\Deploymentshare\disguisedpower\disguiseConfig -Force

if( $Global:DisguiseConfig.getHardwarePlatformConfig().($KeyName) -or $Global:DisguiseConfig.getHardwarePlatformConfig().($KeyName) -is [array] ) {
    $returnValue = $Global:DisguiseConfig.getHardwarePlatformConfig().($KeyName) 
    if( $EnforceReturnValueAsArray -and ( $returnValue.Length -eq 1 ) ) {
        #Write-Host "Converting to array"
        $tempArray = @()
        $tempArray += $returnValue
        Remove-TypeData System.Array
        return , $tempArray | ConvertTo-Json
    }
    if( $EnforceReturnValueAsArray -and ( $returnValue.Length -le 0 ) ) {
        #Write-Host "Converting to array"
        $tempArray = @()
        Remove-TypeData System.Array
        return , $tempArray | ConvertTo-Json
    }
    return  $returnValue | ConvertTo-Json
}
else {
    return "Key Value [$KeyName] could not be found"
}

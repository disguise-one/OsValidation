# Implement your module commands in this script.

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

# Moved to disguisepower/disUtils

# function Compare-Versions{
#     param(
#         [Parameter(Mandatory=$true)]
#         [Version]$Version1,
#         [Parameter(Mandatory=$true)]
#         [Version]$Version2,
#         [Parameter(Mandatory=$false)]
#         [Switch]$equal,
#         [Parameter(Mandatory=$false)]
#         [Switch]$greaterThan,
#         [Parameter(Mandatory=$false)]
#         [Switch]$lessThan
#     )
#     # Check there is at least one switch parameter
#     if((-not $equal) -and (-not $greaterThan) -and (-not $lessThan)){
#         Write-Error "At least one of the oporator switches MUST be passed in"
#         return $null
#     }

#     # Cannot have both greaterThan AND lessThan
#     if($greaterThan -and $lessThan){
#         Write-error "Cannot use both -greaterThan and -lessThan. Pick one, and try again."
#         return $null
#     }
    
#     # Find version1's maximum digit
#     if($Version1.Major -ne -1){
#         if($version1.Minor  -ne -1){
#             if($Version1.Build  -ne -1){
#                 if($Version1.Revision  -ne -1){
#                     $version1MaxIndex = 3
#                 }else{
#                     $version1MaxIndex = 2
#                 }
#             }else{
#                 $version1MaxIndex = 1
#             }
#         }else{
#             $version1MaxIndex = 0
#         }
#     }

#     # Find version2's maximum digit
#     if($Version2.Major -ne -1){
#         if($Version2.Minor  -ne -1){
#             if($Version2.Build  -ne -1){
#                 if($Version2.Revision  -ne -1){
#                     $version2MaxIndex = 3
#                 }else{
#                     $version2MaxIndex = 2
#                 }
#             }else{
#                 $version2MaxIndex = 1
#             }
#         }else{
#             $version2MaxIndex = 0
#         }
#     }

#     # Convert to a string
#     [string]$version1String = $version1
#     [string]$version2String = $Version2

#     # If version1's max index is greater than version 2, we need to pad version 2 to that index with 0's
#     if($version1MaxIndex -gt $version2MaxIndex){
#         # we start the loop at version 2's max index + 1
#         for($index = $version2MaxIndex + 1; $index -lt $version1MaxIndex; $index++){
#             $version2String += ".0"
#         }
#     # if version 2's index is greater than version 1 we pack version 1
#     }else{
#         for($index = $version1MaxIndex + 1; $index -lt $version2MaxIndex; $index++){
#             $version1String += ".0"
#         }
#     }
#     #if they have the same we do nothing

#     # Then we convert back
#     [Version]$Version1 = $version1String
#     [Version]$Version2 = $version2String

#     # Now they should be padded with 0's so we can now compare them
#     #First do the combined operators
#     if($equal -and $greaterThan){
#         if($Version1 -ge $Version2){
#             return $true
#         }else{
#             return $false
#         }
#     }
#     elseif($equal -and $lessThan){
#         if($Version1 -le $Version2){
#             return $true
#         }else{
#             return $false
#         }
#     }
#     # Now we do the individual ones
#     elseif($equal){
#         if($Version1 -eq $Version2){
#             return $true
#         }else{
#             return $false
#         }
#     }
#     elseif($greaterThan){
#         if($Version1 -gt $Version2){
#             return $true
#         }else{
#             return $false
#         }
#     }
#     elseif($lessThan){
#         if($Version1 -lt $Version2){
#             return $true
#         }else{
#             return $false
#         }
#     }else{
#         return $null
#     }

# }



# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

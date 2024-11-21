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

# This should be called from anythin INSIDE the powershell folder
function Format-disguiseModulePathForImport{
    param(
        [Parameter(Mandatory=$true)]
        [String]$RepoName,        
        [Parameter(Mandatory=$true)]
        [String]$ModuleName
    )

    # first create the repo path
    $RepoPath = Join-Path -path "..\..\..\.." -ChildPath $RepoName
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

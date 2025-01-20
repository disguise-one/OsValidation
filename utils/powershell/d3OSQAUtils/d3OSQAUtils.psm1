# Implement your module commands in this script.
#try{
    $PowerShellYAMLModuleRoot = Join-Path $PSScriptRoot ".." | join-Path -ChildPath "powershell-yaml"
    Import-Module $PowerShellYAMLModuleRoot -Force -ErrorAction Stop
#}catch{
    #Install-Module powershell-yaml
    #Import-Module powershell-yaml
#}
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

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

function Get-ScreenCaptureOfCurrentWindowAndReturnBitmapFilePath
{
    param(
        [Parameter(Mandatory=$true)]
        [String]$BitmapFilePath
    )

    begin {
        Add-Type -AssemblyName System.Drawing
        # $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
    }
    process {
        [Windows.Forms.Sendkeys]::SendWait("%{PrtSc}")

        $noOfRetriesRemaining = 10
        [System.Drawing.Bitmap]$bitmap = $null
        while( $noOfRetriesRemaining -and ( -not $bitmap ) ) {
            Start-Sleep -Milliseconds 500
            [System.Drawing.Bitmap]$bitmap = [Windows.Forms.Clipboard]::GetImage()
            $noOfRetriesRemaining -= 1
        }

        if( $bitmap ) {
            $bitmap.Save( $BitmapFilePath )
            return $BitmapFilePath
            #.Save($BitmapFilePath, $jpegCodec, $ep)
        }
        return $null
    }
}

function Get-DeviceManagerDevicePropertiesScreenShotsAsSingleImage {
    param(
        [Parameter(Mandatory=$true)]
        [String]$DeviceHardwareId,
        [Parameter(Mandatory=$true)]
        [String]$DeviceNameFileNameInsert 
    )

    #Sanitise -DeviceNameFileNameInsert by replacing invalid file chars with _ and then truncating at 25 characters
    $DeviceNameFileNameInsert = $DeviceNameFileNameInsert.Replace( ' ', '_' )
    $DeviceNameFileNameInsert = $DeviceNameFileNameInsert.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $DeviceNameFileNameInsert = $DeviceNameFileNameInsert.subString(0, [System.Math]::Min(25, $DeviceNameFileNameInsert.Length)) 


    #Import OS Validation Config File and get the path to the OS Validation Temp Image Store
    $OSValidationConfig = Import-OSValidatonConfig
    $TempImageStoreRootDir = $OSValidationConfig.pathToOSValidationTempImageStore
    $filenameSuffixTimestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"

    #Get list of existing rundll32 processes
    [int[]]$existingRunDLL32ProcessIDs = [int[]]( ( Get-Process | Where {$_.Name -like "rundll32"} ).Id )
    # open device manager device properties screen for specified device
    & rundll32.exe devmgr.dll,DeviceProperties_RunDLL /MachineName "" /DeviceId "$($DeviceHardwareId)"
    #Get list of new rundll32 processes
    [int[]]$newRunDLL32ProcessIDs = [int[]]( ( Get-Process | Where {$_.Name -like "rundll32"} ).Id )
    #Find newly created process
    [int]$newProcessId = $newRunDLL32ProcessIDs | Where-Object { -not( $_ -in $existingRunDLL32ProcessIDs ) }
    Write-Host "newProcessId = $newProcessId"
    #make sure window is activated
    if( $newProcessId ) {
        $null = (New-Object -ComObject WScript.Shell).AppActivate($newProcessId)
        Start-Sleep -Milliseconds 500
    }

    #create an array of paths to screenshot part filenames to be joined together
    [string[]]$TempImageFilePaths = [string[]]@()
    $imagePartNumber = 0
    while( $imagePartNumber -lt 4 ) {
        $imagePartFullFileNameAndPath = Join-Path $TempImageStoreRootDir "TEMP_$($imagePartNumber)_$($DeviceNameFileNameInsert)_$($filenameSuffixTimestamp).bmp"

        Get-ScreenCaptureOfCurrentWindowAndReturnBitmapFilePath -BitmapFilePath $imagePartFullFileNameAndPath | Out-Null
        if( Test-Path $imagePartFullFileNameAndPath ) {
            [string[]]$TempImageFilePaths += [string]$imagePartFullFileNameAndPath
            Write-Verbose "Captured: [$($imagePartFullFileNameAndPath)]"
        }else {
            Write-Warning "Screen Capture Failed For Part: [$($imagePartFullFileNameAndPath)]"
        }

        #now re-hilight the window and flick through to next tab ctrl+Tab
        if( $newProcessId ) {
            $null = (New-Object -ComObject WScript.Shell).AppActivate($newProcessId)
            Start-Sleep -Milliseconds 500
            [Windows.Forms.Sendkeys]::SendWait("^{TAB}")
            Start-Sleep -Milliseconds 500
        }
        
        $imagePartNumber += 1
    }

    #now close the device manager peoprerties window
    Get-Process -id $newProcessId | Stop-Process | Out-Null

    #COnvert the file part filename and path array to an array of bitmap objects in RAM
    $bitmapPSObjectArray = Convert-BitmapFileArrayToBitmapObjectArray -BitmapFilePathArray $TempImageFilePaths
    $finalJPEGNameAndPath = Join-Path $TempImageStoreRootDir "$($DeviceNameFileNameInsert)__$($filenameSuffixTimestamp).jpg"
    Join-BitmapObjectArrayToSingleBitmap -BitmapPSObjectArray $bitmapPSObjectArray -FinalFilePath $finalJPEGNameAndPath | Out-Null

    #finally delete the temp images as they are no longer needed
    foreach( $tempImageObject in $bitmapPSObjectArray ) {
        ([System.Drawing.Bitmap]$tempImageObject).Dispose() | Out-Null #free up ram and remove lock on file so it can be deleted
    }
    foreach( $tempImagePath in $TempImageFilePaths ) {
        Remove-Item $tempImagePath -Force | Out-Null
    }
    #TO DO

    return $finalJPEGNameAndPath
}

function Convert-BitmapFileArrayToBitmapObjectArray {
    Param (
        [Parameter(Mandatory=$true)]
        [string[]]$BitmapFilePathArray
    )

    begin {
        Add-Type -AssemblyName System.Drawing
    }
 
    process {
        [System.Drawing.Bitmap[]]$BitmapPSObjectArray = @()
        foreach( $BitmapFilePath in $BitmapFilePathArray )
        {
            [System.Drawing.Bitmap]$BitmapImageObject = New-Object -TypeName System.Drawing.Bitmap -ArgumentList @( [string]$BitmapFilePath )
            [System.Drawing.Bitmap[]]$BitmapPSObjectArray += [System.Drawing.Bitmap]$BitmapImageObject
        }
        return $BitmapPSObjectArray
    }
}

function Join-BitmapObjectArrayToSingleBitmap {
    Param (
        [Parameter(Mandatory=$true)]
        [System.Drawing.Bitmap[]]$BitmapPSObjectArray,
        [Parameter(Mandatory=$true)]
        [string]$FinalFilePath
    )

    begin {
        Add-Type -AssemblyName System.Drawing
        $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
    }
 
    process {

        $horizontal=$true
        [int]$totalHeight = 0
        [int]$totalWidth = 0

        foreach( $componentBitmap in [System.Drawing.Bitmap[]]$BitmapPSObjectArray ) {
            if( $horizontal ) {
                $totalHeight = if( $componentBitmap.Height -gt $totalHeight ) { $componentBitmap.Height } else { $totalHeight }
                $totalWidth += $componentBitmap.Width
            }
            else {
                $totalHeight += $componentBitmap.Height
                $totalWidth = if( $componentBitmap.Width -gt $totalWidth ) { $componentBitmap.Width } else { $totalWidth }
            }
        }

        Write-Host "TotalWidth: $totalWidth"
        Write-Host "TotalHeight: $totalHeight"

        #Call Bitmap's Constructor Method
        [System.Drawing.Bitmap]$finalBitmapImage = New-Object -TypeName System.Drawing.Bitmap -ArgumentList @( $totalWidth, $totalHeight )

        #Create a Manipulatable Graphics object of size of final bitmap
        [System.Drawing.Graphics]$graphicsPSObject = [System.Drawing.Graphics]::FromImage($finalBitmapImage)

        #Give it a black background
        $graphicsPSObject.Clear([System.Drawing.Color]::Black);

        # go through each image and draw it on the final image
        [int]$offset = 0

        foreach( $componentBitmap in [System.Drawing.Bitmap[]]$BitmapPSObjectArray ) {
            #create rectangle object to define the paste area
            if( $horizontal ) {
                [System.Drawing.Rectangle]$pasteAreaRectangle = New-Object -TypeName System.Drawing.Rectangle -ArgumentList @( $offset, 0, $componentBitmap.Width, $componentBitmap.Height )
                $offset += $componentBitmap.Width
            }
            else {
                [System.Drawing.Rectangle]$pasteAreaRectangle = New-Object -TypeName System.Drawing.Rectangle -ArgumentList @( 0, $offset, $componentBitmap.Width, $componentBitmap.Height )
                $offset += $componentBitmap.Height
            }

            #paste the component bmp into paste area of master bmp
            $graphicsPSObject.DrawImage( $componentBitmap, $pasteAreaRectangle )
        }

        #Save as jpg
        $ep = New-Object Drawing.Imaging.EncoderParameters
        $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]100)
        $finalBitmapImage.Save($FinalFilePath, $jpegCodec, $ep)

        return $filename
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
        [Switch]$ReturnAsPowershellObject,
        [Parameter(Mandatory=$false)]
        [Switch]$FormatMessageWithMonoSpaceFont
    )

    if($pathToImage){
        $pathToImageArr = @($pathToImage)
    }

    if( $Message -and $FormatMessageWithMonoSpaceFont ) {
        #Prefix all lines of output with 4 spaces to create a code block - See this Testrail article for how this works
        #https://support.testrail.com/hc/en-us/articles/7770931349780-Editor-formatting-reference#code-and-preformatted-text-0-1
        $Message = "    " + ( ( $Message -split "`n" ) -join "`n    " )
        $Message = $Message.replace( "`n    `n", "`n     `n" ) #replace 4 spaces with 5 spaces to force empty lines to slow as empty lines so line spacing doesnt get all squashed
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

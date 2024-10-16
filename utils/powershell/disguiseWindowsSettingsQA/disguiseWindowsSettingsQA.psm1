# Implement your module commands in this script.

# If the below module doesnt work, run Install-Module powershell-yaml on ps command line
try{
    Import-Module powershell-yaml -ErrorAction Stop
}catch{
    Install-Module powershell-yaml
    Import-Module powershell-yaml
}

Import-Module "..\d3ModelConfigImporter" -Force

$computerName = $env:computername -replace "-.*"

function Get-AndTestWindowsAppMenuContents{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    #Set up the array to store the app names we want to check
    # psr - stepps recorder
    # charmap - character map
    # mstsc - remote desktop
    # MOVE TO CONFIG FILES
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $appCheckingNamesArray = $testConfig.Windows_settings.windows_allowed_apps
    $appTestingPresenceArray = @()

    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject
    # may be not the best method of doing it as this is hardcoded locations, which may break the script, however we shouldnt put them in the disguise power config
    if($modelConfig.AllowedCaptureCardTypes -Contains "DELTACAST"){
        $appCheckingNamesArray += "C:\Program Files\Deltacast\dCARE\bin\dCARE"
        $appCheckingNamesArray += "C:\Program Files\Deltacast\dSCOPE\bin\dSCOPE"
    }

    #We loop through the checking names array
    foreach($appName in $appCheckingNamesArray){
        #open the job via a start job command so we can tell if it has executed or not
        $appJob = start-job -Name "OSQAWindowsAppsTesting" -ScriptBlock {
            $sbAppName = $($using:appName) + ".exe"
            Start-Process $sbAppName
        }

        #Wait for app to open
        start-sleep -Seconds 1

        # Gather evidence - Sometimes the copy buffer messes up, so we retry until there is a success
        $imagePath = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Windows_settings\" -ChildPath "$($appName).bmp"

        Get-PrintScreenandRetryIfFailed -PathAndFileName $imagePath | Out-Null

        # Check the state and add to the array. Kill the app
        $appTestingPresenceArray += if ($null -eq (Get-Process | Where-Object {$_.ProcessName -eq $appName})){$false}else{$true}
        Get-Process | Where-Object {$_.ProcessName -eq $appName} | Stop-Process

    }

    #return the array
    return $appTestingPresenceArray
}

function Get-StartMenuEvidence{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    <#
        As we cannot use more sophisticated methods to grab the screen contents (due to antivirus saying we cant), 
        we are spoofing a keyboard call of print screen, using the inbuilt microsoft function
    #>
    
    $wShell = New-Object -ComObject "wscript.shell"
    $wShell.SendKeys("^{ESC}")
    start-sleep -Milliseconds 200

    $imagePath = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Windows_settings\" -ChildPath "Startmenu.bmp"

    do{
        $success = Get-PrintScreenandRetryIfFailed -PathAndFileName $imagePath
    }
    while($success -eq $false)

    $wShell.SendKeys("{ESC}")
}

function Get-WindowsLicensingAndEvidence{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )

    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class SFW {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@


    # Write-Host "Gathering Windows License..."
    try{
        $activated = if((Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object -ExpandProperty LicenseStatus) -eq 1){$true} else {$false} 
        # Write-Host "Windows Status: [$($activated)]"
    }catch{
        # Write-Error "Cannot automatically verify if windows is activated. Please check manually"
        $activated =  $false
    }

    # Call this in a start-job so the script can continue outside of the popup
    $LicenseJob = start-job -Name "OSQAWindowsLicense" -ScriptBlock {slmgr /dli }

    $path = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Windows_settings\" -ChildPath "WindowsLicense.bmp"
    Start-sleep -Milliseconds 600

    $process = Get-Process | Where-Object {$_.ProcessName -eq "wscript"}

    # try{
    #     [Program]::SetForegroundWindow($process.MainWindowHandle)
    # }catch [TypeNotFound]{
    #     $a = 0
    # }
    
    Start-sleep -Milliseconds 200

    $success = Get-PrintScreenandRetryIfFailed -PathAndFileName $path

    $process | Stop-Process | Out-Null

    return $activated

}

function Test-ChromeHistory{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )

    # Get the history
    $history = Get-ChromeHistory

    # Test if it exists
    # See if it isnt a disguise website
    $nonDisguiseWebsite = $false
    foreach($site in $history.data){
        if($site -notmatch "disguise"){
            $nonDisguiseWebsite = $true
        }
    }

    # Gather evidence
    Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" | Out-Null

    start-sleep -Milliseconds 500
    # Button pressing -> not the best way to get to history but oh well. there may be an argument that we can use (https://peter.sh/experiments/chromium-command-line-switches/)
    # but I cannot find one to open into history
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("^h")

    start-sleep -Milliseconds 300

    $path = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Windows_settings\" -ChildPath "GoogleChromeHistory.bmp"
    $evidenceSuccess = Get-PrintScreenandRetryIfFailed -PathAndFileName $path

    Get-Process | Where-Object {$_.ProcessName -eq "chrome"} | Stop-Process
    return -not $nonDisguiseWebsite

}

function Get-ChromeHistory {
    $Path = "$Env:SystemDrive\Users\$Env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\History"
    if (-not (Test-Path -Path $Path)) {
        Write-Verbose "[!] Could not find Chrome History for username: $UserName"
    }
    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
    $Value = Get-Content -Path $path | Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
    $Value | ForEach-Object {
        $Key = $_
        if ($Key -match $Search){
            New-Object -TypeName PSObject -Property @{
                User = $env:UserName
                Browser = 'Chrome'
                DataType = 'History'
                Data = $_
            }
        }
    } 
}

function Test-ChromeBookmarks{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )

    # Getting the chrome bookmarks and converting from JSON
    $Path = "$Env:SystemDrive\Users\$Env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    if (-not (Test-Path -Path $Path)) {
        Write-Verbose "[!] Could not find Chrome Bookmarks for username: $UserName"
    }
    $Value = Get-Content -Path $path -Raw | ConvertFrom-Json

    # Getting the required bookmarks from the config yaml
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $requiredBookmarkURLs = $testConfig.Windows_settings.chrome_bookmark_urls | Sort-Object -Descending
    $actualBookmarks = $Value.roots.bookmark_bar.children.url | Sort-Object -Descending

    # Setting up the missing bookmarks STRING
    $missingBookmarks = ""

    # Loop through each actual bookmarks, and seeing if it doesnt appear in the required bookmarks
    foreach($bookmark in $actualBookmarks){
        if(-not ($bookmark -in $requiredBookmarkURLs)){
            if(-not $missingBookmarks){
                $missingBookmarks = "Missing Bookmarks: $($bookmark)"
            }else{
                $missingBookmarks += ", $($bookmark)"
            }
        }
    }

    # Check if the missing bookmarks are filled
    if($missingBookmarks){
        return $missingBookmarks
    }else{
        return $true
    }
}

function Test-ChromeHomepage {
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )

    # Getting the chrome homepage and converting from JSON
    $Path = "$Env:SystemDrive\Users\$Env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Secure Preferences"
    if (-not (Test-Path -Path $Path)) {
        Write-Verbose "[!] Could not find Chrome Bookmarks for username: $UserName"
    }
    $Value = Get-Content -Path $path -Raw | ConvertFrom-Json
    $actualHomeURL = $Value.session.startup_urls

    # Getting the homepage URL
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $homeURL = $testConfig.Windows_settings.chrome_home_url

    if($actualHomeURL -eq $homeURL){
        return $true
    }else{
        return "Incorrect homepage URL: [$($actualHomeURL)]"
    }

}

# Not quite working -> maybe not a needed test as it is very easy to do by hand
function Test-CtlAltDelBackgroundColor{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion
    )
    
    # This checks the registry containing what should be the info, however -> it isnt always correct
    $colour = Get-ItemProperty -Path "HKCU:\\Control Panel\\Colors" -Name "Background" | Select-Object -ExpandProperty Background

    # So lets do some cool image processing
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{^}{%}{DEL}")

}

function Test-MachineName{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    # Need to browse to disguisePower to get the CM serial no functions in CMINFO
    $disguisedPowerPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\disguisedpower\CodeMeter'
    try {
        Import-Module $disguisedPowerPath -Force
    }
    catch {
        # Cannot test it if we cannot import the module, so we return the untested code
        return "UNTESTED"
    }

    # Pull the evidence
    $path = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Windows_settings\" -ChildPath "MachineName.bmp"

    start-process powershell '$MachineNameSB = HOSTNAME.EXE;Write-Host "=====Operating System QA Process=====";Write-Host "Machine Name: [$($MachineNameSB)]";start-sleep -seconds 2'
    start-sleep -seconds 1
    $evidenceSuccess = Get-PrintScreenandRetryIfFailed -PathAndFileName $path

    

    # pull the host name
    $machineName = HOSTNAME.EXE
    $machineName = $machineName -split '-'

    if($machineName[0] -ne $userInputMachineName){
        Write-Verbose "Machine name is not the same: Actual [$($machineName[0])], Required [$($userInputMachineName)]"
        return "FAILED"
    }

    $CMINFO = Get-CMinfo
    if($machineName[1] -ne $CMINFO.d3serial){
        Write-Verbose "Machine serial is not the same: Actual [$($machineName[1])], Required [$($CMINFO.d3serial)]"
        return "FAILED"
    }

    # Return the success code if it has reached the end
    return "PASSED"

}


function Test-WindowsUpdateEnabled{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    # 1 if update is not enabled
    $updateStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" | Select-Object -ExpandProperty NoAutoUpdate

    if($updateStatus -eq 1){
        return "PASSED"
    }else{
        return "FAILED"
    }

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


# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

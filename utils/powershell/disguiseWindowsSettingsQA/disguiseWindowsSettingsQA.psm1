# Implement your module commands in this script.

# If the below module doesnt work, run Install-Module powershell-yaml on ps command line
try{
    Import-Module powershell-yaml -ErrorAction Stop
}catch{
    Install-Module powershell-yaml
    Import-Module powershell-yaml
}

$d3ModelConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3ModelConfigImporter"
$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
Import-Module $d3ModelConfigPath -Force
Import-Module $d3OSQAUtilsPath -Force

$computerName = $env:computername -replace "-.*"

function Get-AndTestWindowsTaskbarContents{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    $TaskbarPinnedContents = Get-ChildItem -Path "$env:APPDATA\\Microsoft\\Internet Explorer\\Quick Launch\\User Pinned\\TaskBar" | Select-Object -ExpandProperty Name
    # Using a traditional for loop as i need to index through the array and change values
    for($i = 0; $i -lt $TaskbarPinnedContents.length; $i++){
        # Removing the duplicates that sometimes get put in in the form of 'File Explorer.lnk', 'File Explorer (2).lnk' -> We dont want this to fail the test
        if($TaskbarPinnedContents[$i] -match " \(2\)"){
            $TaskbarPinnedContents[$i] = $TaskbarPinnedContents[$i] -replace " \(2\)", ""
        }
        $TaskbarPinnedContents[$i] = $TaskbarPinnedContents[$i] -replace ".lnk", ""
    }
    
    # Take out the reformatted dupliactes
    $TaskbarPinnedContents = $TaskbarPinnedContents | select -Unique

    # Get the config file
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $allowedTaskBarApps = $testConfig.Windows_settings.taskbar_apps

    $MissingApps = @()
    foreach($TestApp in $allowedTaskBarApps){
        if($TaskbarPinnedContents -notcontains $TestApp){
            $MissingApps += $TestApp
        }
    }

    if($MissingApps.count -gt 0){
        return $MissingApps
    }else{
        return $true
    }
}


function Get-AndTestWindowsStartMenuContents{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    # It depends on if the machien is windows 10 or 11, on windows 10 it will be an xml. On windows 11 its a JSON file
    # Get the start layout - it has to be exported as an xml file - annoying, but oh well. We can do some handling
    # Check it doesnt exist
    $LayoutPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\temp"
    if(-not (Test-Path $LayoutPath)){
        # Strip off the name of the directory being made
        $LayoutPath = $LayoutPath.Substring(0,$LayoutPath.LastIndexOf("\temp"))
        # Make the directory
        New-Item -path $LayoutPath -Name "temp" -ItemType "directory" | Out-Null
    }

    # If the XML exists we want to delete it and overwrite it
    $winodwsVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
    if($winodwsVersion -match "11"){
        $LayoutPath = Join-Path -Path $LayoutPath -ChildPath "\StartMenuLayout.json"
    }elseif($winodwsVersion -match "10"){
        $LayoutPath = Join-Path -Path $LayoutPath -ChildPath "\StartMenuLayout.xml"
    }
    
    if(Test-Path -path $LayoutPath){
        Remove-item -path $LayoutPath -Force | Out-Null
    }

    # Export the layout
    try{
        Export-StartLayout -Path $LayoutPath
    }catch{
        Remove-item -path $LayoutPath -Force
        Export-StartLayout -Path $LayoutPath
    }

    # Read the content
    # [xml]$LayoutContent = Get-Content -Path $LayoutPath
    $LayoutContent = Get-Content -Path $LayoutPath
    # Oh wait, the format of the MICROSOFT provided XML is incompatable with the MICROSOFT powershell's XML parser. Nice!
    # So we're going to have to just parse the text using a regex
    if($winodwsVersion -match "11"){
        $StartMenuApps = [regex]::Matches($LayoutContent, "\\\\(\w|\s)*.lnk").Value.Replace("\\","").Replace(".lnk","")
    }elseif($winodwsVersion -match "10"){
        $StartMenuApps = [regex]::Matches($LayoutContent, "\\(\w|\s)*.lnk").Value.Replace("\\","").Replace(".lnk","")
    }
    

    # Check if default apps are in there
    # Get the contents of the config file
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $defaultStartMenuApps = $testConfig.Windows_settings.start_menu_apps_default

    $missingApps = @()

    foreach($TestApp in $defaultStartMenuApps){
        if(-not ($StartMenuApps -match $TestApp)){
            $missingApps += $TestApp
        }
    }


    Get-StartMenuEvidence -OSVersion $OSVersion -userInputMachineName $userInputMachineName
    # We return blocked as there are still some manual checks the operator needs to do -> machine specific apps such as dcare are
    # not checked for

    if($missingApps){
        return $missingApps
    }else{
        return "BLOCKED"
    }

}

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

    #We loop through the checking names array
    foreach($appName in $appCheckingNamesArray){
        #open the job via a start job command so we can tell if it has executed or not
        $appJob = start-job -Name "OSQAWindowsAppsTesting" -ScriptBlock {
            $sbAppName = $($using:appName) + ".exe"
            Start-Process $sbAppName
        }

        #Wait for app to open
        start-sleep -Seconds 2

        # Gather evidence - Sometimes the copy buffer messes up, so we retry until there is a success
        $imagePath = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Windows_settings\" -ChildPath "$($appName).bmp"

        Get-PrintScreenandRetryIfFailed -PathAndFileName $imagePath | Out-Null

        # Check the state and add to the array. Kill the app
        # If the app is not present we add it to the list of apps
        $appTestingPresenceArray += if (-not(Get-Process | Where-Object {$_.ProcessName -eq $appName})){$appName}
        Get-Process | Where-Object {$_.ProcessName -eq $appName} | Stop-Process

    }

    #return the array
    if($appTestingPresenceArray){
        return $appTestingPresenceArray
    }else{
        return "BLOCKED"    #We return blocked as there are some manual checks needed
    }
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
        if(($site -notmatch "disguise") -or ($site -notmatch "codemeter")){
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
        Write-Verbose "[!] Could not find Chrome Bookmarks for user: $Env:USERNAME"
    }
    $Value = Get-Content -Path $path -Raw | ConvertFrom-Json

    # Getting the required bookmarks from the config yaml
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $requiredBookmarkURLs = $testConfig.Windows_settings.chrome_bookmark_urls | Sort-Object -Descending
    $actualBookmarks = $Value.roots.bookmark_bar.children.url | Sort-Object -Descending

    # Setting up the missing bookmarks STRING
    $missingBookmarks = ""
    $requiredBookmarkList = ""

    # Loop through each actual bookmarks, and seeing if it doesnt appear in the required bookmarks
    for($index = 0; $index -lt $actualBookmarks.length; $index++){
        if(-not($actualBookmarks[$index] -in $requiredBookmarkURLs)){
            if(-not $missingBookmarks){
                $missingBookmarks = "Missing Bookmarks: $($actualBookmarks[$index])"
            }else{
                $missingBookmarks += ", $($actualBookmarks[$index])"
            }

            if(-not $requiredBookmarkList){
                $requiredBookmarkList = "Required Bookmarks: $($requiredBookmarkURLs[$index])"
            }else{
                $requiredBookmarkList += ", $($requiredBookmarkURLs[$index])"
            }
        }
    }

    # Check if the missing bookmarks are filled
    if($missingBookmarks){
        return "$($missingBookmarks). $($requiredBookmarkList)"
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
    # I thought it needed to be the computer name, however for some reason it needs to be empty to return. This works, as if you run the script on your
    # laptop, you will return a 'True' in the ServiceEnabled field
    $cn = $null
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Update.AutoUpdate') | Out-Null
    $WindowsUpdateSettings = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.AutoUpdate",$cn))

    if($WindowsUpdateSettings.ServiceEnabled){
        return "FAILED"
    }else{
        return "PASSED"
    }

}


function Get-VFCOverlay{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject

    if($modelConfig.usesVFCCards){
        $testStatus = "FAILED"
        Get-PnpDevice | Where-Object {$_.FriendlyName -match "VFC"} | ForEach-Object{ $testStatus = "PASSED" }
    }else{
        $testStatus = "WON'T TEST"
    }

    return $testStatus
}

function Test-WindowsFirewallDisabled{
    param(
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )

    $FirewallSettings = Get-NetFirewallProfile
    $WrongFirewallProfiles = @()
    foreach($FirewallProfile in $FirewallSettings){
        if($FirewallProfile.Enabled){
            $WrongFirewallProfiles += $FirewallProfile.Name
        }
    }

    if($WrongFirewallProfiles){
        return "Firewall Profiles Configured Incorrectly: $($WrongFirewallProfiles)"
    }else{
        return "PASSED"
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

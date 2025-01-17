
$d3ModelConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3ModelConfigImporter"
$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
Import-Module $d3ModelConfigPath -Force
Import-Module $d3OSQAUtilsPath -Force

$computerName = $env:computername -replace "-.*"

<#
.Description
This is a testing function that will get the windows taskbar contents
Gathers it via a file location ($env:APPDATA\\Microsoft\\Internet Explorer\\Quick Launch\\User Pinned\\TaskBar) and tests against the allowed taskbar contents in
config yaml
It tests if they appear there and returns any missing apps

#>
function Get-AndTestWindowsTaskbarContents{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
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
        return Format-ResultsOutput -Result "FAILED" -Message "Missing Apps: $($MissingApps)"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "No Missing Apps"
    }
}

<#
.Description
This tests the windows start menu contents
It gathers the XML (or JSON if it is on windows 10), and then parses the apps out of the layout using a regex
It then checks if the apps are contained in the approved apps list in the config.yaml file. 
These are the default apps though, so model specific checks need to take place
#>

function Get-AndTestWindowsStartMenuContents{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    # It depends on if the machien is windows 10 or 11, on windows 10 it will be an xml. On windows 11 its a JSON file
    # Get the start layout - it has to be exported as an xml file - annoying, but oh well. We can do some handling
    # Check it doesnt exist
    $LayoutPath = $env:TEMP 
    if(-not (Test-Path $LayoutPath)){
        # Strip off the name of the directory being made
        $LayoutParentPath = $LayoutPath.Substring(0,$LayoutPath.LastIndexOf("\Temp"))
        # Make the directory
        New-Item -path $LayoutParentPath -Name "Temp" -ItemType "directory" | Out-Null
    }

    #Get windows version and set $LayoutPath to json / xml file accordingly

    $windowsVersionInfoObject = Get-WindowsVersionInfo
    if( $windowsVersionInfoObject.WindowsVersion -eq 11 ){
        $LayoutPath = Join-Path -Path $LayoutPath -ChildPath "\StartMenuLayout.json"
    }elseif( $windowsVersionInfoObject.WindowsVersion -eq 10 ){
        $LayoutPath = Join-Path -Path $LayoutPath -ChildPath "\StartMenuLayout.xml"
    }
    else {
        throw "Unsupported Windows Version: $($windowsVersionInfoObject.WindowsVersion)"
    }
    
    # If the previous XML exists from the last test run we want to delete it before we overwrite it
    if(Test-Path -path $LayoutPath){
        Remove-item -path $LayoutPath -Force | Out-Null
    }

    # Export the layout
    try{
        Export-StartLayout -Path $LayoutPath
    }catch{
        Remove-item -Path $LayoutPath -Force
        Export-StartLayout -Path $LayoutPath
    }

    # Read the content
    # [xml]$LayoutContent = Get-Content -Path $LayoutPath
    $LayoutContent = Get-Content -Path $LayoutPath
    # Oh wait, the format of the MICROSOFT provided XML is incompatable with the MICROSOFT powershell's XML parser. Nice!
    # So we're going to have to just parse the text using a regex
    if(  $windowsVersionInfoObject.WindowsVersion -eq 11 ){
        $StartMenuApps = [regex]::Matches($LayoutContent, "\\\\(\w|\s)*.lnk").Value.Replace("\\","").Replace(".lnk","")
    }elseif(  $windowsVersionInfoObject.WindowsVersion -eq 10  ){
        $StartMenuApps = [regex]::Matches($LayoutContent, "\\(\w|\s)*.lnk").Value.Replace("\\","").Replace(".lnk","")
    }
    else {
        throw "Unsupported Windows Version: $($windowsVersionInfoObject.WindowsVersion)"
    }

    # Check if default apps are in there
    # Get the contents of the config file
    $testConfig = Get-ConfigYAMLAsPSObject
    $defaultStartMenuApps = $testConfig.Windows_settings.start_menu_apps_default.( "win$($windowsVersionInfoObject.WindowsVersion)" )

    #SEE IF WE NEED TO ADD ANY MODEL SPECIFIC APPS TO THE LIST
    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject
    foreach( $captureCardType in [string[]]$modelConfig.AllowedCaptureCardTypes ) {
        if( $testConfig.Windows_settings.start_menu_apps_default.( $captureCardType ) ) {
            [string[]]$defaultStartMenuApps += [string[]]$testConfig.Windows_settings.start_menu_apps_default.( $captureCardType )
        }
    }

    #Now See which ones are missing
    $missingApps = @()
    foreach($TestApp in $defaultStartMenuApps){
        if(-not ($StartMenuApps -match $TestApp)){
            $missingApps += $TestApp
        }
    }

    $pathToImageStore = Get-StartMenuEvidence -TestRunTitle $TestRunTitle
    # We return blocked as there are still some manual checks the operator needs to do -> machine specific apps such as dcare are
    # not checked for

    $successFeedbackVerb = if( $windowsVersionInfoObject.WindowsVersion -eq 10 ) { 'Found' } else { 'Pinned' }
    if($missingApps){
        return Format-ResultsOutput -Result "FAILED" -Message "Missing Apps not $( $successFeedbackVerb ) in Windows $( $windowsVersionInfoObject.WindowsVersion ) Start menu: [$($missingApps -join ', ')]"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "All Default Apps $( $successFeedbackVerb ) in Windows $( $windowsVersionInfoObject.WindowsVersion ) Start menu: [$( $defaultStartMenuApps -join ', ' )]" -pathToImageArr $pathToImageStore
    }
}


<#
.Description
This is a testing function that will test the windows installed apps (paint, remote desktop connect etc...). It gathers the list stored in the config.yaml
and then tries to open each one. If it cannot it returns the name of that one.

#>
function Get-AndTestWindowsAppMenuContents{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
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
    $imageArray = @()
    foreach($appName in $appCheckingNamesArray){
        #open the job via a start job command so we can tell if it has executed or not
        $appJob = start-job -Name "OSQAWindowsAppsTesting" -ScriptBlock {
            $sbAppName = $($using:appName) + ".exe"
            Start-Process $sbAppName
        }

        #Wait for app to open
        start-sleep -Seconds 2

        # Gather evidence - Sometimes the copy buffer messes up, so we retry until there is a success
        $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
        $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "$($appName)_$($timestamp).bmp"
        $imageArray += $pathToImageStore


        Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore | Out-Null

        # Check the state and add to the array. Kill the app
        # If the app is not present we add it to the list of apps
        $appTestingPresenceArray += if (-not(Get-Process | Where-Object {$_.ProcessName -eq $appName})){$appName}
        Get-Process | Where-Object {$_.ProcessName -eq $appName} | Stop-Process

    }

    #return the array
    if($appTestingPresenceArray){
        return Format-ResultsOutput -Result "FAILED" -Message "Missing Windows App Menu Apps: $($appTestingPresenceArray)" -pathToImageArr $imageArray
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "No Missing Windows App Menu Apps" -pathToImageArr $imageArray
    }
}

<#
.Description
This gathers the evidence of the startmenu so it can be uploaded. It sends a windows button keypress, and then takes a screenshot of it. It saves it as a .bmp file

#>

function Get-StartMenuEvidence{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    <#
        As we cannot use more sophisticated methods to grab the screen contents (due to antivirus saying we cant), 
        we are spoofing a keyboard call of print screen, using the inbuilt microsoft function
    #>
    
    $wShell = New-Object -ComObject "wscript.shell"
    $wShell.SendKeys("^{ESC}")
    start-sleep -Milliseconds 200

    $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
    $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "Startmenu_$($timestamp).bmp"

    do{
        $success = Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore
    }
    while($success -eq $false)

    $wShell.SendKeys("{ESC}")
    return $pathToImageStore
}

<#
.Description
A function to gather if windows is licensed on this machine. There are many ways of doing this but we use slmgr /dli and check programatically via a Cim-Instance

#>

function Get-WindowsLicensingAndEvidence{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
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

    $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
    $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "WindowsLicense_$($timestamp).bmp"

    Start-sleep -Milliseconds 600

    $process = Get-Process | Where-Object {$_.ProcessName -eq "wscript"}

    # try{
    #     [Program]::SetForegroundWindow($process.MainWindowHandle)
    # }catch [TypeNotFound]{
    #     $a = 0
    # }
    
    Start-sleep -Milliseconds 200

    $success = Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore

    $process | Stop-Process | Out-Null

    if($activated){
        return Format-ResultsOutput -Result "PASSED" -Message "Windows partial product key is present" -pathToImage $pathToImageStore
    }else{
        return Format-ResultsOutput -Result "FAILED" -Message "Windows partial product key is not present"
    }

}

<#
.Description
This function checks that chrome history is clear using Get-Chromehistory, and if it isnt clear, returns false. It also opens chrome and takes a screenshot of the history to ensure 
it is clear

#>


function Test-ChromeHistory{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )

    # Get the history
    $history = Get-ChromeHistory

    # Test if it exists
    # See if it isnt a disguise website
    $whitelistedHistoryPages = (Get-ConfigYAMLAsPSObject).Windows_settings.chrome_allowed_history
    $nonWhiteListedPages = @()
    foreach($site in $history.data){
        foreach($whitelistedSite in $whitelistedHistoryPages){
            if($site -notmatch $whitelistedSite){
                $nonWhiteListedPages += $site
            }
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

    $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
    $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "GoogleChromeHistory_$($timestamp).bmp"
    $evidenceSuccess = Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore

    Get-Process | Where-Object {$_.ProcessName -eq "chrome"} | Stop-Process
    if($nonWhiteListedPages){
        return Format-ResultsOutput -Result "FAILED" -Message "Non-Whitelisted website(s) found: [$($nonWhiteListedPages). If you believe this is in error, please update config found at [OSValidation/config/config.yaml]"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "Only whitelisted websites present" -pathToImage $pathToImageStore
    }

}

<#
.Description
This is a function that gathers chrome browsing history by going to the history file, and using a regex to locate all urls that are stored
it returns the complete url history

#>

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


<#
.Description
This function gathers the chrome bookmarks via the chrome app data, and converts it from JSON. 
It gathers the required bookmarks from the config.yaml, and checks if the actual bookmarks are in it, or if there are too many bookmarks
Then parses the 
#>
function Test-ChromeBookmarks{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )

    # Getting the chrome bookmarks and converting from JSON
    $Path = "$Env:SystemDrive\Users\$Env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Could not find Chrome Bookmarks for user: [$($Env:USERNAME)]"
        return Format-ResultsOutput -Result "BLOCKED" -Message "Could not find Chrome Bookmarks for user: [$($Env:USERNAME)]. Looking in path [$($Path)]"
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
        return Format-ResultsOutput -Result "FAILED" -Message "Missing chrome bookmarks: [$($missingBookmarks). Required Bookmarks: [$($requiredBookmarkList)]. If you believe this is in error, please update config found at [OSValidation/config/config.yaml]"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "Only whitelisted bookmarks present"
    }
}

<#
.Description
Test-ChromeHomepage gahers the homepage from the chrome secure preferences file inside app data, and checks if it is the homepage 
listed in the config.yaml
#>
function Test-ChromeHomepage {
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )

    # Getting the chrome homepage and converting from JSON
    $Path = "$Env:SystemDrive\Users\$Env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Secure Preferences"
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Could not find Chrome Homepage for user: [$($Env:USERNAME)]"
        return Format-ResultsOutput -Result "BLOCKED" -Message "Could not find Chrome Homepage for user: [$($Env:USERNAME)]. Looking in path [$($Path)]"
    }
    $Value = Get-Content -Path $path -Raw | ConvertFrom-Json
    $actualHomeURL = $Value.session.startup_urls

    # Getting the homepage URL
    $testConfig = Get-Content -Path "config\config.yaml" | ConvertFrom-Yaml
    $homeURL = $testConfig.Windows_settings.chrome_home_url

    if($actualHomeURL -eq $homeURL){
        return Format-ResultsOutput -Result "PASSED" -Message "Chrome homepage is correct. homepage URL is: [$($actualHomeURL)]"
    }else{
        return Format-ResultsOutput -Result "FAILED" -Message "Missing chrome homepage: [$($homeURL). Actual homepage is: [$($actualHomeURL)]. If you believe this is in error, please update config found at [OSValidation/config/config.yaml]"
    }

}

# Not quite working -> maybe not a needed test as it is very easy to do by hand. 
function Test-CtlAltDelBackgroundColor{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    
    # This checks the registry containing what should be the info, however -> it isnt always correct
    $colour = Get-ItemProperty -Path "HKCU:\\Control Panel\\Colors" -Name "Background" | Select-Object -ExpandProperty Background

    # So lets do some cool image processing
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{^}{%}{DEL}")

}

<#
.Description
Test-WindowsUpdateEnabled uses a load with partial name, to gather the windows update settings. If it returns an empty field in ServiceEnabled
it is disabled
#>
function Test-WindowsUpdateEnabled{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    # I thought it needed to be the computer name, however for some reason it needs to be empty to return. This works, as if you run the script on your
    # laptop, you will return a 'True' in the ServiceEnabled field
    $cn = $null
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Update.AutoUpdate') | Out-Null
    $WindowsUpdateSettings = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.AutoUpdate",$cn))

    if($WindowsUpdateSettings.ServiceEnabled){
        return Format-ResultsOutput -Result "FAILED" -Message "Windows updates are detected as enabled: [$($WindowsUpdateSettings.ServiceEnabled)]"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "Windows updates are being detected as disabled: [$($WindowsUpdateSettings.ServiceEnabled)]"
    }

}

<#
.Description
Get-VFCOverlay checks if there is a VFC card in the device manager. It only checks if the machine's model config uses VFC cards
#>
function Get-VFCOverlay{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject

    if($modelConfig.usesVFCCards){
        $testStatus = "FAILED"
        Get-PnpDevice | Where-Object {$_.FriendlyName -match "VFC"} | ForEach-Object{ $testStatus = "PASSED" }
    }else{
        $testStatus = "WON'T TEST"
    }

    if($testStatus -eq "PASSED"){
        return Format-ResultsOutput -Result "PASSED" -Message "VFC Cards have been detected on the machine in the device overlay"
    }elseif ($testStatus -eq "FAILED"){
        return Format-ResultsOutput -Result "FAILED" -Message "No VFC Cards have been detected on the machine in device overlay, and this machine's config file indicates it uses VFC cards. If there are working VFC cards in the machine, this is a failure."
    }else{
        return Format-ResultsOutput -Result "WON'T TEST" -Message "This machine's config file indicates that it does not use VFC cards."
    }
}


<#
.Description
Test-WindowsFirewallDisabled uses an inbuilt powershell function to gather the network firewall profile.  It checks if it is disabled
and if it is enabled it passes back which one is configured incorrectly
#>
function Test-WindowsFirewallDisabled{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )

    $FirewallSettings = Get-NetFirewallProfile
    $WrongFirewallProfiles = @()
    foreach($FirewallProfile in $FirewallSettings){
        if($FirewallProfile.Enabled){
            $WrongFirewallProfiles += $FirewallProfile.Name
        }
    }

    if($WrongFirewallProfiles){
        return Format-ResultsOutput -Result "FAILED" -Message "Firewall Profiles Configured Incorrectly: $($WrongFirewallProfiles)"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "Firewall Profiles Configured Correctly"
    }

}

function Test-NotificationsDisabled{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    $notifications = -1
    try{
        $notifications = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoToastApplicationNotification"
    }catch{
        $failed = $true
    }

    if($notifications -eq 1){
        return Format-ResultsOutput -Result "PASSED" -Message "Notifications disabled according to registry [HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications] containing value [$($notifications)]."
    }elseif($notifications -ne 1){
        return Format-ResultsOutput -Result "FAILED" -Message "Notifications not disabled according to registry [HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications], showing value [$($notifications)]."
    }elseif($failed){
        return Format-ResultsOutput -Result "FAILED" -Message "Notifications not disabled as registry [HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications] cannot be accessed, indicating it isn't there."
    }else{
        return Format-ResultsOutput -Result "BLOCKED" -Message "Something strange went on. You should never have hit this message. Please check what is in [HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications] and check [OsValidation\utils\disguiseWindowsSettingsQA.ps1]'s function [Test-NotificationsDisabled] is behaving."
    }
}


Function Test-InstalledAppAndFeatureVersions {
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$pathToOSValidationTemplate
    )

    # Dot-Source the ps1 file into a powershell object variable
    $OSValidationTemplatePSObject = ( . $pathToOSValidationTemplate )
    if( -not $OSValidationTemplatePSObject ) {
        Format-ResultsOutput -Result "FAILED" -Message "ERROR: Could not load the Powershell OS Validation Template file [$( $pathToOSValidationTemplate )]. Either the file must be missing or it contains invalid powershell code."
    }

    # Get Config YAML as PS Object
    $configYAMLPSObject = Get-ConfigYAMLAsPSObject

    $testrailFeedbacktext = "----------------------------------------------------------------------------------"

    # Check for '01-Drivers' choco packages with missing Hardware IDs and add a warning to the test feedback string
    [string[]]$packageHandlesToIgnore = $configYAMLPSObject.driver_choco_package_handle_automated_installed_apps_and_features_version_test_blocklist
    $driverPackagesWithMissingInstalledAppOrFeatureName = $OSValidationTemplatePSObject.PackageVersions | Where-Object {
                                                $_.category -like '*Software*' -and
                                                -not ( [string]($_.chocoPackageHandle  ) -in [string[]]$packageHandlesToIgnore ) -and
                                                -not ( [string]($_.sharedPackageHandle ) -in [string[]]$packageHandlesToIgnore ) -and
                                                -not ( $_.installedAppOrFeatureName )
                                            }

    #Add a warning to the feedback if some of the chocolatey packages dont have any hardware components associated with any HardwareIDs
    if( $driverPackagesWithMissingInstalledAppOrFeatureName ) {
        $testrailFeedbacktext += "`n`n** TEST BLOCKED **`n`nTHE FOLLOWING [02-Software] CHOCO PACKAGES DO NOT HAVE AN [Installed App/Fearure Name] SET.`nPlease either:`n - Add the Installed App/Feature Name(s) to the relevant Choco Package Records in OSBuilder`n - Or add either the Package Handle or Shared External Handle to the blocklist in the OSValidation Config File [OSValidation\config\config.yaml]`n`n"
        $testrailFeedbacktext += ( $driverPackagesWithMissingInstalledAppOrFeatureName | 
                                   Select-Object @{Name='Choco Package Name'; Expression='friendlyName'},
                                                 @{Name='Package Handle'; Expression='chocoPackageHandle'}, 
                                                 @{Name='Shared External Handle'; Expression='sharedPackageHandle'}, 
                                                 @{Name='Expected Version'; Expression='osValidationPackageVersion'} |
                                    Format-Table | Out-String 
                                 ).Trim()
        $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"
    }

    # Now fetch all choco packages with HardwareIDs attached, that arent in the blocklist
    $allPackagesWithInstalledAppOrFeatureNameSet = $OSValidationTemplatePSObject.PackageVersions | Where-Object {
        -not ( [string]($_.chocoPackageHandle  ) -in [string[]]$packageHandlesToIgnore ) -and
        -not ( [string]($_.sharedPackageHandle ) -in [string[]]$packageHandlesToIgnore ) -and
        ( $_.installedAppOrFeatureName )
    }

    # Get a list of all Installed Apps in windows Settings --> Installed Apps
    [PSObject[]]$installedAppsPSObjects = Get-WMIObject Win32_InstalledWin32Program

    # Loop through all non-blocklisted choco packages with HardwareIDs attached, so that we can search for them in device manager
    foreach( $packageObject in [PSCustomObject[]]$allPackagesWithInstalledAppOrFeatureNameSet ) {
        
        #Get list of PNPDevices whose InstanceIDs begin with at least one of the hardwareIDs
        $matchingInstalledApps = [PSObject[]]( $installedAppsPSObjects | Where-Object {  $_.Name -like $packageObject.installedAppOrFeatureName } )

        # add the number of found devices to the package object in case we want to report on it later (also the device name if only one matched)
        # DEBUG: Write-Host "Matching Devices: $($matchingPNPDevices.Length)"
        $packageObject | Add-Member -Type NoteProperty -Name 'noOfFoundInstalledApps' -Value $matchingInstalledApps.Length
        $matchedInstalledAppName = "None"
        if( $matchingInstalledApps.Length -eq 1 ) {
            $matchedInstalledAppName = $matchingInstalledApps[0].Name
        }
        if( $matchingInstalledApps.Length -gt 1 ) {
            $matchedInstalledAppName = "MULTIPLE DEVICES"
        }
        $packageObject | Add-Member -Type NoteProperty -Name 'foundInstalledAppName' -Value $matchedInstalledAppName
        $packageObject | Add-Member -Type NoteProperty -Name 'allFoundInstalledAppNames' -Value "[$( ( [string[]]$matchingInstalledApps.Name ) -join '], [' )]"
        
        #DELETEME: #Now look through all the matching devices for ones with drivers, where the driver has a matching version
        #DELETEME: $allDriverVersions = ( ( $matchingInstalledApps | Get-CimAssociatedInstance -ResultClassName Win32_SystemDriver -ErrorAction SilentlyContinue ).PathName | Get-Item -ErrorAction SilentlyContinue ).VersionInfo.ProductVersion
        # Now Get a list of all versions from matching results, and a deduplicated list too
        [string[]]$foundAppVersions = [string[]]( $matchingInstalledApps.Version )
        [string[]]$foundAppVersions_Unique = [string[]]$foundAppVersions | Select-Object -Unique
        
        # Add the number of found Driver Versions to the package object in case we want to report on it later (also the device name if only one matched)
        # DEBUG: Write-Host "Found Driver Versions: $($allDriverVersions.Length)"
        # DEBUG: Write-Host "All Driver Versions for these Devices: [$( $allDriverVersions -join '], [' )]"
        $packageObject | Add-Member -Type NoteProperty -Name 'noOfFoundAppVersions' -Value $foundAppVersions_Unique.Length
        $matchedAppVersion = "None"
        if( ([string[]]$foundAppVersions_Unique).Length -eq 1 ) {
            $matchedAppVersion = ([string[]]$foundAppVersions_Unique)[0]
        }
        if( ([string[]]$foundAppVersions_Unique).Length -gt 1 ) {
            $matchedAppVersion = "MULTIPLE VERSIONS"
        }
        $packageObject | Add-Member -Type NoteProperty -Name 'foundAppVersion' -Value $matchedAppVersion
        $packageObject | Add-Member -Type NoteProperty -Name 'allFoundAppVersions' -Value "[$( $foundAppVersions_Unique -join '], [' )]"

        # Is the correct app version installed? ie Is at least one App Version for at least one matching App exactly the same as osValidationPackageVersion fromt he OSValidationTemplate.ps1 choco package object
        $finalReuslt = if( [string]$packageObject.osValidationPackageVersion -eq $matchedAppVersion ) { 'PASS' } else { 'FAIL' }
        #DELETEME: if( $matchingInstalledApps.Length -eq 0 ) {
        #DELETEME:     #if its a fail because we couldnt find any devices matching the HardwareIds the set this record to BLOCKED instead of pass or fail because it means the user needs to add a hardware id to OS Builder
        #DELETEME:     $finalReuslt = 'BLOCKED'
        #DELETEME: }
        $packageObject | Add-Member -Type NoteProperty -Name 'result' -Value $finalReuslt
    }

    #Now that we have completed searching for all matching devices and driver versions, we can calculate the final result
    $overallResult = 'PASSED'
    if( [string[]]$allPackagesWithInstalledAppOrFeatureNameSet.result -contains 'FAIL' ) {
        $overallResult = 'FAILED'
    }
    elseif( $driverPackagesWithMissingInstalledAppOrFeatureName.Length -or ( [string[]]$allPackagesWithInstalledAppOrFeatureNameSet.result -contains 'BLOCKED' ) ) {
        $overallResult = 'BLOCKED'
    }

    #Add the overall results table to the testrail resposne text
    $testrailFeedbacktext += "`n`nFINAL RESULTS TABLE:`n`n"
    $testrailFeedbacktext += ( $allPackagesWithInstalledAppOrFeatureNameSet | 
                               Select-Object @{Name='Choco Package Name'; Expression='friendlyName'},
                                             @{Name='Found App Name'; Expression='foundInstalledAppName'}, 
                                             @{Name='Expected App Version'; Expression='osValidationPackageVersion'},
                                             @{Name='Found App Version'; Expression='foundAppVersion'}, 
                                             @{Name='Result'; Expression='result'} |
                               Format-Table | Out-String 
                             ).Trim()
    $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"

    #if some of the tests came back blocked then the user needs to add some hardware ids to OSBuilder
    [PSCustomObject[]]$noAppFoundResults = ( $allPackagesWithInstalledAppOrFeatureNameSet | Where-Object { $_.noOfFoundInstalledApps -eq 0 } )
    if( $noAppFoundResults ) {
        #Add the overall results table to the testrail resposne text
        $testrailFeedbacktext += "`n`nNO APPS COULD BE FOUND ON YOUR SYSTEM MATCHING THE FOLLOWING PACKAGES:`nif the App is istalled uder a different name then Please edit the [Installed App or Feature name] of the Appropriate Choco Package records in OSBuilder then try again.`n`n"
        $testrailFeedbacktext += ( $noAppFoundResults | 
                                   Select-Object @{Name='Choco Package Name'; Expression='friendlyName'},
                                                 @{Name='Installed App or Feature name'; Expression='installedAppOrFeatureName'} |
                                   Format-List | Out-String 
                                 ).Trim()
        $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"
    }

    #Add the overall results table to the testrail resposne text
    $testrailFeedbacktext += "`n`nTHE FOLLOWING TABLE LISTS A DETAILED BREAKDOWN OF EACH TEST WHERE AN APP WAS FOUND BUT THE VERSION CHECK FAILED:`n`n"
    $testrailFeedbacktext += ( $allPackagesWithInstalledAppOrFeatureNameSet | Where-Object { $_.noOfFoundInstalledApps -ge 1 } | 
                               Select-Object @{Name='Package Category'; Expression='category'},
                                             @{Name='Package Name'; Expression='friendlyName'},
                                             @{Name='Package Handle'; Expression='chocoPackageHandle'},
                                             @{Name='Shared External Handle'; Expression='sharedPackageHandle'},
                                             @{Name='Version Choco Handle'; Expression='chocoPackageVersion'},
                                             @{Name='Version Public Name'; Expression='publicPackageVersion'},
                                             @{Name='App Version Expected in Windows Settings'; Expression='osValidationPackageVersion'},
                                             @{Name='# of Found Devices'; Expression='noOfFoundInstalledApps'},
                                             @{Name='Found App Name'; Expression='foundInstalledAppName'}, 
                                             @{Name='All Found App Names'; Expression='allFoundInstalledAppNames'}, 
                                             @{Name='# of Found Versions'; Expression='noOfFoundAppVersions'},
                                             @{Name='Found Version Name'; Expression='foundAppVersion'}, 
                                             @{Name='All Found Version Names'; Expression='allFoundAppVersions'}, 
                                             @{Name='Result'; Expression='result'} |
                               Format-List * | Out-String 
                             ).Trim()
    $testrailFeedbacktext += "`n`n----------------------------------------------------------------------------------"

    #dust for debugging, doent get printed during normal execution
    Write-Verbose $testrailFeedbacktext

    Format-ResultsOutput -Result $overallResult -Message $testrailFeedbacktext
}



# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

$d3ModelConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3ModelConfigImporter"
$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
Import-Module $d3ModelConfigPath -Force
Import-Module $d3OSQAUtilsPath -Force

function Test-ProjectsRegPath{
    param(
    )
    # Test the d3 projects file
    try{
        $d3projectsFolder = Get-ItemProperty -Path "HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite" -Name "d3 Projects Folder"
        if($d3projectsFolder."d3 Projects Folder" -eq "D:\d3 Projects"){
            $d3Message = "Registry entry [d3 Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite] contains [$($d3projectsFolder."d3 Projects Folder")]"
            $d3testResult = "PASSED"
        }else{
            $d3Message = "Registry entry [d3 Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite] contains [$($d3projectsFolder."d3 Projects Folder")]. This is incorrect and must contain [D:\d3 Projects]"
            $d3testResult = "FAILED"
            Write-Host "$($d3testResult). $($d3Message)"
        }
    }catch{
        $d3Message = "Cannot find registry entry [d3 Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite]. "
        $d3testResult = "FAILED"
        Write-Host "$($d3testResult). $($d3Message)"
    }
    

    # Test the Renderstream projects file THIS TEST IS UNFINISHED
    try{
        $RenderstreamprojectsFolder = Get-ItemProperty -Path "HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite" -Name "Renderstream Projects Folder"
        if($RenderstreamprojectsFolder."Renderstream Projects Folder" -eq "D:\RenderStream Projects"){
            $RenderstreamMessage = "Registry entry [Renderstream Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite] contains [$($RenderstreamprojectsFolder."Renderstream Projects Folder")]"
            $RenderstreamtestResult = "PASSED"
        }else{
            $RenderstreamMessage = "Registry entry [Renderstream Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite] contains [$($RenderstreamprojectsFolder."Renderstream Projects Folder")]. This is incorrect and must contain [D:\RenderStream Projects]"
            $RenderstreamtestResult = "FAILED"
            Write-Host "$($RenderstreamtestResult). $($RenderstreamMessage)"
        }
    }catch{
        $RenderstreamMessage = "Cannot find registry entry [Renderstream Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite]. "
        $RenderstreamtestResult = "FAILED"
        Write-Host "$($RenderstreamtestResult). $($RenderstreamMessage)"
    }


    # Do the final checks
    if(($RenderstreamtestResult -eq "PASSED") -and ($d3testResult -eq "PASSED")){
        $overallResult = "PASSED"
    }else{
        $overallResult = "FAILED"
    }

    $returnString = "D3 Projects Folder: $($d3testResult): $($d3Message) `n`n Renderstream Projects Folder: $($RenderstreamtestResult): $($RenderstreamMessage)"

    return Format-ResultsOutput -Result "$overallResult" -Message "$($returnString)"
}

function Test-RemoteReImageLogs {
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestType,
        [Parameter(Mandatory=$true)]
        [String]$AfterInternalRestore
    )

    $AfterInternalRestore_bool = [bool]( $AfterInternalRestore -eq 'True' )
    if( $AfterInternalRestore_bool ) {
        return Format-ResultsOutput -Result "WON'T TEST" -Message "No Remote Logs are expected after an Internal Restore, PASSED by Default!"
    }
    else {
        if( $TestType -eq "USB" ) {
            $USBName = 'REDISGUISE'
            #Find USB Drive called REDISGUISE
            $USBVolumeObject = Get-CimInstance Win32_Volume -Filter "DriveType='2'" | Where-Object { $_.Label -eq $USBName }
            #We want Redisguises to work from External SSDs as well as External USB Drives now as External SSD UBS Sticks are becoming more and more popular
            if( -not $USBVolumeObject ) {
                #This is the powershell to get all USB SSD DRIVES, then check through all their Partitions for Mounted Drive Letters then Check through each of them for the Volume Label 'REDISGUISE', then add the 'label' field to these volume objects so they match the spec below
                $USBVolumeObject = ( Get-PhysicalDisk | Where-Object { $_.BusType -eq 'USB' } | Get-Disk | Get-Partition | Where-Object { $_.DriveLetter } | Select-Object DriveLetter | Get-Volume | Where-Object { $_.FileSystemLabel -eq $USBName } | Foreach-Object { $_ | Add-Member -MemberType NoteProperty -Name 'Label' -Value $_.FileSystemLabel -PassThru } )
            }
            if( -not $USBVolumeObject ) {
                return Format-ResultsOutput -Result "FAILED" -Message "No USB Drive called [REDISGUISE] Could be found, please plug in your USB and try again!"
            }
            elseif( ([string[]]$USBVolumeObject.DriveLetter).Length -gt 1 ) {
                return Format-ResultsOutput -Result "FAILED" -Message "A total of $( ([string[]]$USBVolumeObject.DriveLetter).Length ) USB Drives called [REDISGUISE] Could be found, please unplug the extra USB(s) and try again!"
            }
            else {
                $USBDriveRootPath = "$( $USBVolumeObject.DriveLetter )".Trim( '\' ).Trim( '/' ).Trim( ':' )
                $USBDriveRootPath = $USBDriveRootPath + ":\"
                return Test-ReImageLogs -LoggingDirectory $USBDriveRootPath
            }
        }
        elseif( $TestType -eq "R20" ) {
            return Format-ResultsOutput -Result "BLOCKED" -Message "This Test has not been implemented yet as we are currently unable to ascertain the path to the Director Machine's [DeploymentShare\Logs] Directory. Please conduct this test manually."
        }
        else {
            return Format-ResultsOutput -Result "FAILED" -Message "ERROR: Unknown Test Type: [$( $TestType )]"
        }
    }
}

function Test-ReImageLogs {
    param(
        [Parameter(Mandatory=$false)]
        [String]$LoggingDirectory="C:\Windows\Logs"
    )
    # needs to be both postboot and upgrade/deploy logs found
    $postbootRegex = "^PS(\d+)_POSTBOOT_.*\.txt$"
    $upgradeRegex = "^PS(\d+|_UnknownSerial)_UPGRADE_.*\.txt$"
    $deployRegex = "^PS(\d+|_UnknownSerial)_DEPLOY_.*\.txt$"

    $codeMeterPath = Format-disguiseModulePathForImport -RepoName "disguisedpower" -moduleName "CodeMeter"

    try {
        Import-Module $codeMeterPath -Force
    }catch{
        Write-Error "Cannot import codemeter module, will search using a wider regex."
    }

    if($CMINFO.d3serial){
        $postbootRegex = $postbootRegex -replace "\d+", $CMINFO.d3serial
        $upgradeRegex = $upgradeRegex -replace "\d+", $CMINFO.d3serial
        $deployRegex = $deployRegex -replace "\d+", $CMINFO.d3serial
    }

    #find all UPGRADE/DEPLOY/POSTBOOT Logs
    $logDirectoryContents = Get-ChildItem -Path $LoggingDirectory
    $postbootLogFileNames = $logDirectoryContents | Where-Object { $_.Name -match $postbootRegex }
    $upgradeLogFileNames = $logDirectoryContents | Where-Object { $_.Name -match $upgradeRegex }
    $deployLogFileNames = $logDirectoryContents | Where-Object { $_.Name -match $deployRegex }

    [string[]]$pathToLogFileStore_Array = [string[]]@()

    if($postbootLogFileNames){
        $noOfPostbootLogsFound = ([string[]]$postbootLogFileNames.Name).Length
        if( $noOfPostbootLogsFound -eq 1 ) {
            $postbootTest = "PASSED"
            $postbootMessage = "Postboot log found [$($postbootLogFileNames.FullName)]"
            [string[]]$pathToLogFileStore_Array += [string]($postbootLogFileNames.FullName)
        }
        else {
            $postbootTest = "BLOCKED"
            $postbootMessage = "A TOTAL OF $($noOfPostbootLogsFound) POSTBOOT logs were found [$( $postbootLogFileNames.Name -join '], [' )] - ONLY 1 EXPECTED"
        }
    }else{
        $postbootTest = "FAILED"
        $postbootMessage = "Cannot find any files matching the regex [$($postbootRegex)] in directory [$($LoggingDirectory)]. This indicates no POSTBOOT logs have been made. Please check manually to verify"
    }

    if($upgradeLogFileNames){
        $noOfUpgradeLogsFound = ([string[]]$upgradeLogFileNames.Name).Length
        if( $noOfUpgradeLogsFound -eq 1 ) {
            $reimageTest = "PASSED"
            $reimageMessage = "Upgrade Log File found [$($upgradeLogFileNames.FullName)]"
            [string[]]$pathToLogFileStore_Array += [string]($upgradeLogFileNames.FullName)
        }
        else {
            $reimageTest = "BLOCKED"
            $reimageMessage = "A TOTAL OF $($noOfUpgradeLogsFound) UPGRADE logs were found [$( $upgradeLogFileNames.Name -join '], [' )] - ONLY 1 EXPECTED"
        }
    }
    elseif($deployLogFileNames){
        $noOfDeployLogsFound = ([string[]]$deployLogFileNames.Name).Length
        if( $noOfDeployLogsFound -eq 1 ) {
            $reimageTest = "PASSED"
            $reimageMessage = "Deployment Log File found [$($deployLogFileNames.FullName)]"
            [string[]]$pathToLogFileStore_Array += [string]($deployLogFileNames.FullName)
        }
        else {
            $reimageTest = "BLOCKED"
            $reimageMessage = "A TOTAL OF $($noOfDeployLogsFound) DEPLOY logs were found [$( $deployLogFileNames.Name -join '], [' )] - ONLY 1 EXPECTED"
        }
    }
    else{
        $reimageTest = "FAILED"
        $reimageMessage = "Cannot find any files matching either regex [$($upgradeRegex)] or [$($deployRegex)] in directory [$($LoggingDirectory)]. This indicates no upgrade or deployment logs have been made. Please check manually to verify."
    }

    $feedbackMessage = "POSTBOOT Results: $($postbootTest): $($postbootMessage)`n`nREIMAGE Results: $($reimageTest): $($reimageMessage)"
    if(($reimageTest -eq "PASSED") -and ($postbootTest -eq "PASSED")){
        return Format-ResultsOutput -Result "PASSED" -Message "$( $feedbackMessage )`n`nSEE LOG FILES ATTACHED BELOW:" -pathToImageArr $pathToLogFileStore_Array
    }
    elseif( ( $reimageTest -eq "FAILED" ) -or ( $postbootTest -eq "FAILED" ) ) {
        return Format-ResultsOutput -Result "FAILED" -Message $feedbackMessage -pathToImageArr $pathToLogFileStore_Array
    }
    else {
        return Format-ResultsOutput -Result "BLOCKED" -Message $feedbackMessage -pathToImageArr $pathToLogFileStore_Array
    }

}

function Test-NICNames{
    param(
    )

    # AdapterNames1G

    # The adapter names is more complicated than it seems. On the config files, on some machines are only the names that are required, on some both 25 and 100 are filled in
    # so we need to find which one is actually on the machine, and check that field

    # Import the model specific config
    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject

    if(-not $modelConfig){
        $message = "Cannot import model specific config. Test cannot be ran."
        $result = "BLOCKED"
        Write-Host "$($result): $($message)"
        return Format-ResultsOutput -Result $result -Message $message
    }

    $netAdapters = (Get-NetAdapter).Name

    $requiredAdapterNames = $(if($modelConfig.hasRemoraManagementDevice){"disguiseMGMT"}; 
                                $modelConfig.AdapterNames1G; 
                                $modelConfig.AdapterNames10G; 
                                $modelConfig.AdapterNames25G; 
                                $modelConfig.AdapterNames100G)

    $result = "PASSED"
    $message = " "
    foreach($adapter in $netAdapters){
        if($requiredAdapterNames -notcontains $adapter){
            $result = "FAILED"
            $message += "The adapter [$($adapter)] does not appear in the whitelist of acceptable adapter names. "
            
        }
    }

    return Format-ResultsOutput -Result $result -Message $message
}


<#
.Description
Test-MachineName gets passed the machine it should be, and checks if it is the same as when running HOSTNAME.EXE
#>

function Test-MachineName{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle
    )
    # Need to browse to disguisePower to get the CM serial no functions in CMINFO -> TO DO: Use the implemented Format-disguiseModulePathForImport
    # rather than using a hardcoded logic here \/
    $result = "PASSED"
    $Message = ""
    $disguisedPowerPath = Format-disguiseModulePathForImport -RepoName "disguisedpower" -moduleName "CodeMeter"
    try {
        Import-Module $disguisedPowerPath -Force
    }
    catch {
        # Cannot test it if we cannot import the module, so we return the untested code
        $message = "We cannot verify the name of the machine, as the disguisePower module cannot be imported"
        $result = "BLOCKED"
    }
    # Pull the evidence
    $timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
    $pathToImageStore = Join-Path -path (Import-OSValidatonConfig).pathToOSValidationTempImageStore -ChildPath "MachineName_$($timestamp).bmp"

    start-process powershell '$MachineNameSB = HOSTNAME.EXE;Write-Host "=====Operating System QA Process=====";Write-Host "Machine Name: [$($MachineNameSB)]";start-sleep -seconds 2'
    start-sleep -seconds 1
    $evidenceSuccess = Get-PrintScreenandRetryIfFailed -PathAndFileName $pathToImageStore

    $modelConfig = Import-ModelConfig -ReturnAsPowershellObject

    [string[]]$possibleMachineNames = [string[]]$modelConfig.CodeMeterProductCodes.d3Model

    # pull the host name
    try{
        $machineName = HOSTNAME.EXE
    }
    catch{
        Write-Error "Cannot run [HOSTNAME.EXE]"
        $message += "Cannot run [HOSTNAME.EXE]. "
        $result = "BLOCKED"
    }
    
    $machineName = $machineName -split '-'

    if( -not( $machineName[0] -in $possibleMachineNames ) ){
        $message += "Machine Model is not listed as a [CodeMeterProductCodes].[d3Model] Value in the Model Config file in disguisedpower: Actual Model Taken From Server Name [$($machineName[0])], Possible Values from Config File [$( $requiredMachineName -join ']/[' )]. "
        $result = "FAILED"
    }

    $CMINFO = Get-CMinfo
    if($machineName[1] -ne $CMINFO.d3serial){
        $message += "Machine serial is not the same: Actual [$($machineName[1])], Required [$($CMINFO.d3serial)]"
        $result = "FAILED"
    }
    
    
    # Return the success code if it has reached the end
    if($result -eq "PASSED"){
        return Format-ResultsOutput -Result "PASSED" -Message "Machine name is correct: [$($machineName)]" -pathToImage $pathToImageStore
    }else{
        return Format-ResultsOutput -Result "FAILED" -Message "Machine name is incorrect. Actual machine name: [$($machineName)]. Required machine name: [$($requiredMachineName)-$($CMINFO.d3serial)]"
    }
}

function Test-OSName{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$TestRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$pathToOSValidationTemplate
    )

    # Dot-Source the OS Validation Settings ps1 file into a powershell object variable and validate it
    $OSValidationTemplatePSObject = ( . $pathToOSValidationTemplate )
    if( -not $OSValidationTemplatePSObject ) {
        return Format-ResultsOutput -Result "BLOCKED" -Message "ERROR: Could not load the Powershell OS Validation Template file [$( $pathToOSValidationTemplate )]. Either the file must be missing or it contains invalid powershell code."
    }

    $correctOSImageName = $OSValidationTemplatePSObject.RedisguiseName
    if( -not $correctOSImageName ) {
        return Format-ResultsOutput -Result "BLOCKED" -Message "ERROR: The Powershell OS Validation Template file [$( $pathToOSValidationTemplate )] does not contain a value for [RedisguiseName], cannot complete Test"
    }

    #Load and Validate Config YAML 
    $configYAMLPSObject = Get-ConfigYAMLAsPSObject
    if( -not $configYAMLPSObject ) {
        return Format-ResultsOutput -Result "BLOCKED" -Message "ERROR: The OS Validation YAML Config file [/config.config.yaml] could not be loaded. Either the file must be missing or it contains invalid YAML formatting."
    }

    #Fetch and validate the values we need from the config file
    $reg_location_oem_information_folder = $configYAMLPSObject.registry_keys.oem_information_folder
    $reg_location_os_release_entry = $configYAMLPSObject.registry_keys.oem_information_entries.os_release
    $d3Service_api_all_d3_servers_os_info_endpoint = $configYAMLPSObject.d3Service_api_endpoints.all_d3_servers_os_info
    if( -not $reg_location_oem_information_folder ) {
        return Format-ResultsOutput -Result "BLOCKED" -Message "ERROR: The OS Validation YAML Config file [/config.config.yaml] did not contain an entry for [registry_keys.oem_information_folder], cannot complete test"
        
    }
    if( -not $reg_location_os_release_entry ) {
        return Format-ResultsOutput -Result "BLOCKED" -Message "ERROR: The OS Validation YAML Config file [/config.config.yaml] did not contain an entry for [registry_keys.oem_information_entries.os_release], cannot complete test"
    }
    if( -not $d3Service_api_all_d3_servers_os_info_endpoint ) {
        return Format-ResultsOutput -Result "BLOCKED" -Message "ERROR: The OS Validation YAML Config file [/config.config.yaml] did not contain an entry for [d3Service_api_endpoints.all_d3_servers_os_info], cannot complete test"
    }


    # Test the OS Name from Regsitry
    $osReleaseNameFromRegistry = $null
    $d3Message_RegCheck = "AN UNKNOWN ERROR OCCURED TRING TO CHECK THE REGISTRY FOR THE OS NAME"
    $d3testResult_RegCheck = "BLOCKED"
    try{
        $osReleaseNameFromRegistry = Get-ItemPropertyValue -Path $reg_location_oem_information_folder -Name $reg_location_os_release_entry
        $d3Message_RegCheck = "Registry entry [$reg_location_os_release_entry] in registry location [$reg_location_oem_information_folder] contains [$osReleaseNameFromRegistry]. Expected OS Image Name: [$($correctOSImageName)]"
        if( $osReleaseNameFromRegistry -eq $correctOSImageName ){
            $d3testResult_RegCheck = "PASSED"
        }else{
            $d3testResult_RegCheck = "FAILED"
        }
    }catch{
        $d3Message_RegCheck = "Cannot find registry entry [$reg_location_os_release_entry] in registry location [$reg_location_oem_information_folder]. "
        $d3testResult_RegCheck = "FAILED"
    }


    # Test the OS Name from d3Service APIs
    $d3Message_APICheck = "AN UNKNOWN ERROR OCCURED TRING TO CHECK d3Service APIs FOR THE OS NAME"
    $d3testResult_APICheck = "BLOCKED"
    #Call API
    Write-Host
    Write-Host "Calling d3Service API Endpoint [$d3Service_api_all_d3_servers_os_info_endpoint]"
    try{ 
        $response = Invoke-RestMethod $d3Service_api_all_d3_servers_os_info_endpoint -Method 'GET'
    }
    catch {
        if( $_.Exception.StatusCode -eq "NotFound" ) {
            Write-Error "API STATUS CODE: [404 (Not Found)] - This Means the [api/service_internal/system/reimageserver] Endpoint cannot be found`n - Does the Actor Server have a Reimaging 2.0 Compatible Version of d3 Installed?"
        }
        else {
            Write-Error $_.Exception.Message
            $_
        }
        Write-Host
    }
    
    #Feed Back API Response to user 
    if( $response -and $response.status -and ( $response.status.code -eq 200 -or $response.status.code -eq 0 ) ) {
        $machineName = HOSTNAME.EXE
        $machinesOnNetwork = $response.result
        $thisMachine = $machinesOnNetwork | Where-Object{ $_.hostname -eq $machineName }
        if( $thisMachine ) {
            $thisMachinesAPIImageVersion = $thisMachine.imageVersion
            $d3Message_APICheck = "d3Service API with Endpoint [$d3Service_api_all_d3_servers_os_info_endpoint] returned and imageVersion of [$thisMachinesAPIImageVersion] for machine [$($thisMachine.hostname)]. Expected OS Image Name: [$($correctOSImageName)]"
            if( $osReleaseNameFromRegistry -eq $correctOSImageName ){
                $d3testResult_APICheck = "PASSED"
            }else{
                $d3testResult_APICheck = "FAILED"
            }
        }
        else {
            $d3Message_APICheck = "d3Service API with Endpoint [$d3Service_api_all_d3_servers_os_info_endpoint] returned a list of machines on the network: [$( $machinesOnNetwork.hostname -join ']/[' )] which DOES NOT include this servers machine name [$machineName]. Could not ascertain imageVersion from d3Service"
            $d3testResult_APICheck = "BLOCKED"
        }
    }
    else {
        $d3Message_APICheck = "d3Service API with Endpoint [$d3Service_api_all_d3_servers_os_info_endpoint] failed to run on this machine.`n`nThe API Response WAS:`n$( $response | ConvertTo-Json )"
        $d3testResult_APICheck = "BLOCKED"
    }
    
    # Return the success code if it has reached the end
    $overallResult = "BLOCKED"
    if( ( $d3testResult_RegCheck -eq "FAILED" ) -or ( $d3testResult_APICheck -eq "FAILED" ) ) {
        $overallResult = "FAILED"
    }
    if( ( $d3testResult_RegCheck -eq "PASSED" ) -and ( $d3testResult_APICheck -eq "PASSED" ) ) {
        $overallResult = "PASSED"
    }
    return Format-ResultsOutput -Result $overallResult -Message "REGISTRY CHECK: $($d3testResult_RegCheck) - $($d3Message_RegCheck)`n`n`nD3SERVICE CHECK: $($d3testResult_APICheck) - $($d3Message_APICheck)"
}

function Test-DDrive{
    param()

    $drive = get-PSDrive | Where-Object -Property Name -eq D

    if($drive){
        if($drive.Description -eq "Media"){
            return Format-ResultsOutput -Result "PASSED" -Message "D drive found. Name is [Media]"
        }else{
            return Format-ResultsOutput -Result "FAILED" -Message "D drive found, however name is [$($drive.Description)]"
        }
    }else{
        return Format-ResultsOutput -Result "FAILED" -Message "No D drive found"
    }

}

function Test-CWindowsDisguisedpowerGetsDeleted{
    param(        
        [Parameter(Mandatory=$false)]
        [String]$pathToDisguisedPowerOnCDrive = "C:\Windows\disguisedpower"
    )

    $disguisedPowerExists = Test-Path $pathToDisguisedPowerOnCDrive

    if($disguisedPowerExists){
        return Format-ResultsOutput -Result "FAILED" -Message "Directory [C:\Windows\disguisedpower] WAS found on C: Drive"
    }else{
        return Format-ResultsOutput -Result "PASSED" -Message "Directory [C:\Windows\disguisedpower] WAS NOT found on C: Drive"
    }
}




# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

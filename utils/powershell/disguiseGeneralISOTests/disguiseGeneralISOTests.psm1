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
    

    # Test the Renderstream projects file
    try{
        $RenderstreamprojectsFolder = Get-ItemProperty -Path "HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite" -Name "d3 Projects Folder"
        if($RenderstreamprojectsFolder."d3 Projects Folder" -eq "D:\d3 Projects"){
            $RenderstreamMessage = "Registry entry [d3 Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite] contains [$($RenderstreamprojectsFolder."d3 Projects Folder")]"
            $RenderstreamtestResult = "PASSED"
        }else{
            $RenderstreamMessage = "Registry entry [d3 Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite] contains [$($RenderstreamprojectsFolder."d3 Projects Folder")]. This is incorrect and must contain [D:\d3 Projects]"
            $RenderstreamtestResult = "FAILED"
            Write-Host "$($RenderstreamtestResult). $($RenderstreamMessage)"
        }
    }catch{
        $RenderstreamMessage = "Cannot find registry entry [d3 Projects Folder] in registry location [HKCU:\SOFTWARE\d3 Technologies\d3 Production Suite]. "
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

function Test-ReImageLogs{
    param(
    )
    # needs to be both postboot and upgrade

    $path = "C:\Windows\Logs"
    $postbootRegex = "(^PS(\d+)_POSTBOOT.*\.txt$)"
    $upgradeRegex = "(^PS((\d+)|(_UnknownSerial))_UPGRADE.*\.txt$)"

    $codeMeterPath = Format-disguiseModulePathForImport -RepoName "disguisedpower" -moduleName "CodeMeter"

    try {
        Import-Module $codeMeterPath -Force
    }catch{
        Write-Error "Cannot import codemeter module, will search using a wider regex."
    }

    if($CMINFO.d3serial){
        $postbootRegex = $postbootRegex -replace "\d+", $CMINFO.d3serial
        $upgradeRegex = $upgradeRegex -replace "\d+", $CMINFO.d3serial
    }

    $logDirectoryContents = Get-ChildItem -Path $path
    $postbootAppears = $logDirectoryContents | Where-Object -Property FullName -EQ $postbootRegex
    $upgradeAppears = $logDirectoryContents | Where-Object -Property FullName -EQ $upgradeRegex

    if($postbootAppears){
        $postbootTest = "PASSED"
        $postbootMessage = "Postboot log found."
    }else{
        $postbootTest = "FAILED"
        $postbootMessage = "Cannot find any files matching the regex [$($postbootRegex)]. This indicates no postboot logs have been made. Please check manually to verify, and if this test has produced a false-negative, please update the code of this test."
    }

    if($upgradeAppears){
        $upgradeTest = "PASSED"
        $upgradeMessage = "Upgrade log found."
    }else{
        $upgradeTest = "FAILED"
        $upgradeMessage = "Cannot find any files matching the regex [$($upgradeRegex)]. This indicates no upgrade logs have been made. Please check manually to verify, and if this test has produced a false-negative, please update the code of this test."
    }

    if(($upgradeTest -eq "PASSED") -and ($postbootTest -eq "PASSED")){
        return Format-ResultsOutput -Result "PASSED" -Message "Postboot Message: $($postbootTest): $($postbootMessage) `n`nUpgrade Message: $($upgradeTest): $($upgradeMessage)"
    }else{
        return Format-ResultsOutput -Result "FAILED" -Message "Postboot Message: $($postbootTest): $($postbootMessage) `n`nUpgrade Message: $($upgradeTest): $($upgradeMessage)"
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
        [String]$OSVersion
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

    $requiredMachineName = $modelConfig.biosHandle

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

    if($machineName[0] -ne $requiredMachineName){
        $message += "Machine name is not the same: Actual [$($machineName[0])], Required [$($requiredMachineName)]. "
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


# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

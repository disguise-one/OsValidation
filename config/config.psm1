$LOCAL_CONFIG_RELATIVE_PATH         =       "local/config.local.ps1"
$STATIC_CONFIG_RELATIVE_PATH        =       "static/config.static.ps1"
$TESTS_CONFIG_RELATIVE_PATH         =       "tests/config.tests.ps1"

$Global:OSValidationConfig = New-Object psobject -Property @{}
$Global:OSValidationTests = New-Object psobject -Property @{}

# ===Import config values and add them to the global config variable. This is done first===

# now we want to import the two config files, the local overwriting the static
$ImportConfig = {
    param(
        [Parameter(Mandatory=$true)]
        [String]$RelativePath
    )

    $ImportPath = Join-Path -Path $PSScriptRoot -ChildPath $RelativePath

    if(-not(Test-Path $ImportPath)){
        Write-Error "Cannot locate the config file at [$($ImportPath)]. This is a terminating error. Script will exit" -ErrorAction Stop
    }

    $ImportConfigContents = .$ImportPath
    foreach($key in $ImportConfigContents.Keys){
        if(-not ($ImportConfigContents[$key])){
            Write-Error "Error importing the config file [ $($RelativePath) ]: The property [$($key)] in the config file contains a null or empty value. This indicates a improperly set up environment. Please fill it out and re-run the script. Script will terminate. Press enter to exit..."
        }
        # If it already exists we overwrite it, else we create the member
        if($this.($key)){
            $this.($key) = $ImportConfigContents[$key]
        }else{
            $this | Add-Member NoteProperty -Name $key -Value $ImportConfigContents[$key]
        }
        
    }
}

# === Adding methods to the object ===

# This method imports the disguise config from disguisedPower. It creates a global variable of $Global:DisguiseConfig which stores the config
$importDisguisedPowerModelConfig = {
    
    # We modify the path to point to config files
    $modifiedPath = Join-Path -Path $this.pathToDisguisePowerAndSecParentDir -ChildPath "\disguisedPower\disguiseConfig"

    #Import all the config files, via already established methods -> see disguisePower config for info on this
    try{
        Import-Module $modifiedPath -Force
    }catch{
        throw "Error importing disguise model config: Path to disguisedPower config files [ $($modifiedPath) ] not found"
    }

    #Cast the config file to a PSCustomObject -> String in json format
    # Want to remove all the extra postboot scripts, as they are converted to powershell code which is inside the string. Unnessesary
    $configObject = [PSCustomObject]$Global:DisguiseConfig.getHardwarePlatformConfig()
    $configObject = $configObject | Select-Object -Property * -ExcludeProperty PostbootExtrasScriptBlock | Select-Object -Property * -ExcludeProperty Post_Reboot_Script_Block
    return $configObject
}

$SetTestRailRunObject = {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$TestRailRunObject
    )
    $Global:OSValidationConfig.TestRailRunObject = $TestRailRunObject
}

# Adding methods
$Global:OSValidationConfig | Add-Member -MemberType ScriptMethod -Name "ImportConfig" -Value $ImportConfig
$Global:OSValidationConfig | Add-Member -MemberType ScriptMethod -Name "ImportDisguisedPowerModelConfig" -Value $importDisguisedPowerModelConfig
$Global:OSValidationConfig | Add-Member -MemberType ScriptMethod -Name "SetTestRailRunObject" -Value $SetTestRailRunObject

# Setup of all values inside the object
try{
    $Global:OSValidationConfig.ImportConfig($STATIC_CONFIG_RELATIVE_PATH)
    $Global:OSValidationConfig.ImportConfig($LOCAL_CONFIG_RELATIVE_PATH)
}catch{
    Write-Host
    Write-Host "There was an error  $($_.ScriptStackTrace)  during config file import.: `n`n$($_.Exception.Message) " -ForegroundColor Red
    Write-Host
    Read-host "Press Enter to Exit..."
    exit
}

# Instantiating more values
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "StartingTimestamp" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "TestRailRunObject" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "disguisedPowerPath" -Value (Join-Path -path $Global:OSValidationConfig.pathToDisguisePowerAndSecParentDir -ChildPath "\disguisedPower")
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "disguisedSecPath" -Value (Join-Path -path $Global:OSValidationConfig.pathToDisguisePowerAndSecParentDir -ChildPath "\disguisedSec")
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "TestRunType" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "TestRailAPISuiteIDBeingUsed" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "testRunTitle" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "PathToOSValidationTemplate" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "afterInternalRestore" -Value $null
$Global:OSValidationConfig | Add-Member -MemberType NoteProperty -Name "TestrailUserDetails" -Value $null


# ===============       Tests        ===============
$Global:OSValidationTests | Add-Member -MemberType ScriptMethod -Name "ImportConfig" -Value $ImportConfig

# Consider changing this to an ENUM https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_enum?view=powershell-7.5
$TestResultTextToCodeLookup = {
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRailResult
    )
    switch ($TestRailResult.ToUpper()){
        "PASSED"            {return 1}
        "BLOCKED"           {return 2}
        "UNTESTED"          {return 3}
        "RETEST"            {return 4}
        "FAILED"            {return 5}
        "DONE"              {return 6}
        "WON'T TEST"        {return 7}
        "REQUIRE MORE INFO" {return 8}
        default             {return $null}
    }
}

$Global:OSValidationTests | Add-Member -MemberType ScriptMethod -Name "TestResultTextToCodeLookup" -Value $TestResultTextToCodeLookup

try{
    $Global:OSValidationTests.ImportConfig($TESTS_CONFIG_RELATIVE_PATH)
}catch{
    Write-Host
    Write-Host "There was an error  $($_.ScriptStackTrace) during config file import.: `n`n$($_.Exception.Message) " -ForegroundColor Red
    Write-Host
    Read-host "Press Enter to Exit..."
    exit
}


<#
Do not need the below, however this is a good reference for if you need to assign a method to an individual test object

$formatTestResultMessage = {
    $timestamp = Get-Date -Format "dd/MM/yyyy__HH:mm:ss"
    $TestMessage = @"
    +================================================+
    TESTNAME              
+================================================+
        TIMESTAMP

        Result:                         TESTRESULT

        Message:                        TESTMESSAGE
    
    ==================END OF TEST=====================
"@
    $this.TestMessage = $TestMessage.Replace("TESTNAME", $this.Name).Replace("TIMESTAMP", $timestamp).Replace("TESTMESSAGE", $this.TestMessage).Replace("TESTRESULT", $this.TestStatus)
}

This is the reference I mean \/

try{
    # loops through wim/usb/r20
    foreach($TestGroup in $Global:OSValidationTests.PSObject.Properties.Name){
        # loops through windowsTests/DeviceTests etc...
        foreach($TestFamily in $Global:OSValidationTests.($TestGroup).get_Keys()){
            # loops through each individual test
            foreach($Test in $Global:OSValidationTests.($TestGroup).($TestFamily)){
                # So the formatTestResultMessage is a method of each individual test
                $Test | Add-Member -MemberType ScriptMethod -Name "formatTestResultMessage" -Value $formatTestResultMessage
            }
        }
    }
}catch{
    Write-Host
    Write-Host "There was an error  $($_.ScriptStackTrace) during config file import.: `n`n$($_.Exception.Message) " -ForegroundColor Red
    Write-Host
    Read-host "Press Enter to Exit..."
    exit
}

#>
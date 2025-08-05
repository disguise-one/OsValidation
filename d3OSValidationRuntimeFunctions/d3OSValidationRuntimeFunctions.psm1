# Implement your module commands in this script.
function Format-ErrorMessage{
    param(
        [Parameter(Mandatory=$true)]
        [String]$FunctionName,
        [Parameter(Mandatory=$false)]
        [String]$ScriptStackTrace,
        [Parameter(Mandatory=$true)]
        [String]$ExceptionMessage,
        [Parameter(Mandatory=$false)]
        [hashtable]$ArgumentHashTable
    )
    $message = "There was an error with [ $($FunctionName) ]:"
    
    $message += if($ScriptStackTrace){"`n`n$($ScriptStackTrace)."}else{""}
    
    $message += "`n`nError Message:`n$($ExceptionMessage) `n`n"
    
    if($ArgumentHashTable){
        $message += "Arguments provided:`n`n"
    }
    
    foreach($argument in $ArgumentHashTable){
        $message += "$($argument.Keys):`t`t$($argument)`n`n"
    }

    return $message
}

function Complete-PreRunChecks{
    param()

    if(-not (Test-Path $Global:OSValidationConfig.disguisedPowerPath)){
        throw Format-ErrorMessage -FunctionName "Complete-PreRunChecks" -ExceptionMessage "Cannot find disguisedPower directory [ $($Global:OSValidationConfig.disguisedPowerPath) ]. Please ensure it is there or change the value inside [ config/static/config.static.ps1 ]"
    }

    if(-not (Test-Path $Global:OSValidationConfig.disguisedSecPath)){
        throw Format-ErrorMessage -FunctionName "Complete-PreRunChecks" -ExceptionMessage "Cannot find disguisedsec directory [ $($Global:OSValidationConfig.disguisedSecPath) ]. Please ensure it is there or change the value inside [ config/static/config.static.ps1 ]"
    }

    $d3TestRailPath = Join-Path -path $PSScriptRoot -childpath "..\powershell_common_utils\modules\d3PSTestRail"
    if(-not (Test-Path $d3TestRailPath)){
        Throw "Cannot find the powershell_common_util's module d3PSTestRail at [ $($d3TestRailPath) ] indicating that you have not cloned the subrepo of the git repository. Please do so" 
    }

    switch ($Global:OSValidationConfig.TestRunType){
        "WIM" {$Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed = $Global:OSValidationConfig.suite_id_WIM}
        "USB" {$Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed = $Global:OSValidationConfig.suite_id_USB}
        "R20" {$Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed = $Global:OSValidationConfig.suite_id_R20}
        default {$Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed = $null}
    }

    if($null -eq $Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed){
        throw Format-ErrorMessage -FunctionName "Complete-PreRunChecks" -ExceptionMessage "The field [ $($Global:OSValidationConfig.TestRunType) ] contains a non-approved test type. The approved test types are`n`t- WIM`n`t- USB `n`t-R20`nIf you think this is in error, and there is another test type that needs to be added, please add it to the validation set at [ Start-MainScript ] function definition and the switch statement in [ Complete-PreRunChecks ]"
    }

    Import-Module $d3TestRailPath -Force -scope Global
}

function Send-TestObjectToTestRail{
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$TestObject
    )

    $ResultCode = $Global:OSValidationTests.TestResultTextToCodeLookup($TestObject.TestStatus)
    if(-not ($ResultCode)){
        throw Format-ErrorMessage -FunctionName "Send-TestObjectToTestRail" -ExceptionMessage "After running the test [ $($TestObject.Name) ] it's test code has been detected as [ null ], indicating the test function has returned a non allowed test result of [ $($TestObject.TestStatus) ]`n`nThe allowed test results are:`n`t- PASSED`n`t- BLOCKED `n`t - UNTESTED `n`t- RETEST `n`t- FAILED `n`t- DONE `n`t- WON'T TEST `n`t- REQUIRE MORE INFO`nThis can be found inside config/config.psm1 [ TestResultTextToCodeLookup ]. If a new test result has been added on testrail, please update this table"
    }
    $TestrailAPIResult = Add-TestRailResultForCase -RunId $Global:OSValidationConfig.TestRailRunObject.ID -CaseId $TestObject.TestRailCode -StatusId $ResultCode -Comment $TestObject.TestMessage
    if($TestObject.PathToImage){
        Add-TestRailAttachemntToResult -ResultID $TestrailAPIResult.id -ImagePathArray $TestObject.PathToImage
    }
}

function Initialize-TestRailAndHandleIssues{
    param(
        [Parameter(Mandatory=$true)]
        [String]$TestRailUsername,
        [Parameter(Mandatory=$false)]
        [String]$TestRailPasswordEncoded
    )
    if(-not ($Global:OSValidationConfig.TestRailAPIRootURI)){
        Throw "The config file [ config/static/config.static.ps1 ] member [ TestRailAPIRootURI ] is null or empty. Please set this up. It should look similar to [ https://disguise.testrail.io/ ] "
    }

    if(-not ($TestRailUsername)){
        throw "The [ testRailUserName ] is null or empty. Please ensure this is passed in. It should look similar to [ my.name@disguise.one ]. If you do not have a testrail account set up, please talk to Luca Manzoni (Head of QA at time of writing), or to IT support"
    }

    if(-not ($TestRailPasswordEncoded)){
        throw "The [ testRailPassword ] is null or empty. Please ensure this is passed in. It must be ASCII encoded. If you do not have a testrail account set up, please talk to Luca Manzoni (Head of QA at time of writing), or to IT support"
    }

    try{
        Write-Host
        Initialize-TestRailSession -Uri $Global:OSValidationConfig.TestRailAPIRootURI -User $TestRailUsername -ApiKey ([System.Text.Encoding]::Ascii.GetString([System.Convert]::FromBase64String($TestRailPasswordEncoded)))
        Write-Host "Initialized Test Rail Settings under user [ $($TestRailUsername) ]"
    }catch{
        Throw Format-ErrorMessage -FunctionName "Initialize-TestRailSession" -ScriptStackTrace $_.ScriptStackTrace -ExceptionMessage $_.Exception.Message -ArgumentHashTable @{
                "TestRailAPIRootURI"                    =       $Global:OSValidationConfig.TestRailAPIRootURI
                "TestRailUserName"                      =       $TestRailUsername
                "testRailPassword (ASCII ENCODED)"      =       $TestRailPasswordEncoded
            }
    }

    try{
        $userDetails = Get-TestRailUserByEmail -userEmail $TestRailUsername
        $Global:OSValidationConfig.TestrailUserDetails = $userDetails
    }catch{
        Throw Format-ErrorMessage -FunctionName "Initialize-TestRailSession:`nSub-Function: Get-TestRailUserByEmail" -ScriptStackTrace $_.ScriptStackTrace -ExceptionMessage $_.Exception.Message -ArgumentHashTable @{
            "TestRailAPIRootURI"        =       $Global:OSValidationConfig.TestRailAPIRootURI
            "TestRailUserName"          =       $TestRailUsername
        }
    }
}

function Start-TestRailTestRun{
    param(
        [Parameter(Mandatory=$true)]
        [int]$testRun,
        [Parameter(Mandatory=$true)]
        [String]$testRunTitle
    )

    # If its a new run
    if($testRun -eq -1){
        try{
            $TestRailRunObject = Start-TestRailRun -ProjectID $Global:OSValidationConfig.TestRailAPIProjectID -SuiteId $Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed -Name $Global:OSValidationConfig.testRunTitle -Description " " -AssignedToID $Global:OSValidationConfig.TestrailUserDetails.ID
        }catch{
            throw Format-ErrorMessage -FunctionName "Start-TestRailTestRun:`nSub-Function: Start-TestRailRun" -ScriptStackTrace $_.ScriptStackTrace -ExceptionMessage $_.Exception.Message -ArgumentHashTable @{
                "OSValidationConfig.TestRailAPIProjectID"           =       $Global:OSValidationConfig.TestRailAPIProjectID
                "OSValidationConfig.TestRailAPISuiteIDBeingUsed"    =       $Global:OSValidationConfig.TestRailAPISuiteIDBeingUsed
                "OSValidationConfig.testRunTitle"                   =       $Global:OSValidationConfig.testRunTitle
                "OSValidationConfig.TestrailUserDetails.ID"         =       $Global:OSValidationConfig.TestrailUserDetails.ID
            }
        } 
    }
    # If its an existing run
    else{
        try{
            $TestRailRunObject = Get-TestRailRun -RunId $testRun
        }catch{
            throw Format-ErrorMessage -FunctionName "Start-TestRailTestRun:`nSub-Function: Get-TestRailRun" -ScriptStackTrace $_.ScriptStackTrace -ExceptionMessage $_.Exception.Message -ArgumentHashTable @{
                "RunID"           =       $testRun
            }
        }
    }

    # Store the run object
    $Global:OSValidationConfig.SetTestRailRunObject($TestRailRunObject)
    Write-Host "Done. Test Rail API Response:"
    $TestRailRunObject | Format-List * | Out-Host

    # The running tests bit
    Write-Host
    Write-Host "==========================================================================================================" -ForegroundColor Cyan
    Write-Host "Performing $($Global:OSValidationConfig.TestRunType) Tests" -ForegroundColor Cyan
    Write-Host "==========================================================================================================" -ForegroundColor Cyan
    
    foreach($TestFamily in $Global:OSValidationTests.($Global:OSValidationConfig.TestRunType).Keys){
        foreach($test in $Global:OSValidationTests.($Global:OSValidationConfig.TestRunType).($TestFamily)){
            # This is actually where the test block is run
            Write-Host
            Write-Host "----------------------------------------------------------------------------------------------------------" -ForegroundColor Yellow
            Write-Host "Testing [$($TestFamily)] - [$($test.Name)]..." -ForegroundColor Yellow
            Write-Host "----------------------------------------------------------------------------------------------------------" -ForegroundColor Yellow
            try{
               $resultObject       =   .($Test.TestScriptBlock)
            }catch{
                Write-Host (Format-ErrorMessage -FunctionName "$($Test.TestScriptBlock)" -ScriptStackTrace $_.ScriptStackTrace -ExceptionMessage "Something has gone wrong when executing a Test's scriptblock function. Please see the exception message: `n`n$($_.Exception.Message)") -ForegroundColor Yellow
            }
            # Then we parse the result
            $test.TestStatus    =   $resultObject.OverallResult
            $Test.TestMessage   =   $resultObject.Message
            $test.PathToImage   =   $resultObject.PathToImage
            # And upload it to testrail
            Write-Host "Test Finished`n`tTest Result: $($test.TestStatus)`n`tTest Message: $($Test.TestMessage)"
            Send-TestObjectToTestRail -testObject $Test
            Write-Host
            Write-Host
        }
    }
}



function Start-MainScript{
    param(
        [Parameter(Mandatory=$true)]
        [String]$testRun,
        [Parameter(Mandatory=$true)]
        [String]$testRunTitle,
        [Parameter(Mandatory=$true)]
        [String]$testrailUsername,
        [Parameter(Mandatory=$true)]
        [String]$testrailPassword,
        [Parameter(Mandatory=$true)]
        [String]$OSValidationTemplatePath,
        [Parameter(Mandatory=$true)]
        [ValidateSet('WIM','USB','R20')]
        [String]$TestType,
        [Parameter(Mandatory=$true)]
        [String]$afterInternalRestore_string
    )

    # Set up the passed in arguments into the Config object
    $Global:OSValidationConfig.TestRunType = $TestType
    $Global:OSValidationConfig.testRunTitle = $testRunTitle
    if(-not (Test-Path $OSValidationTemplatePath)){
        throw Format-ErrorMessage -FunctionName "Start-MainScript" -ExceptionMessage "[ OSValidationTemplatePath ] did not resolve to any valid file location [ $($OSValidationTemplatePath) ]. There may be an issue with OSBuilder's OSValdiationTemplate creation. Please restart this script, and if this still fails, please restart OSBuilder and try again."
    }
    $Global:OSValidationConfig.PathToOSValidationTemplate = $OSValidationTemplatePath
    $Global:OSValidationConfig.afterInternalRestore = $afterInternalRestore_string

    Complete-PreRunChecks
    Initialize-TestRailAndHandleIssues -TestRailUsername $testrailUsername -TestRailPasswordEncoded $testrailPassword
    Start-TestRailTestRun -testRun $testRun -testRunTitle $testRunTitle

}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

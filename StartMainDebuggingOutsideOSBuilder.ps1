$pathToPython = "\\d3deploydev\deploymentshare\PortablePython\WPy64-31241\python-3.12.4.amd64\python.exe" #Join-Path $Global:OSBuilderStaticConfig.disguiseTemplatingTemplatesRoot "WPy64-31241\python-3.12.4.amd64\python.exe"
$pathToOSValidationRootDir = "N:\OSValidation" 
$pathToOSValidationMainPythonScript = <# ".\ #>"main.py"
$osFamilyName ="OSValidation"
$testRunTitle = "Testing"
$testRailUsername = "jacob.tomaszewski@disguise.one"
$encodedTestrailPassword = "UTtBLllfKCQ8ajNjZ1UySmtkS3dCWA=="
$testRailTestRunId = 18419
$pathToStoreOSValidationTemplateObject = "C:\Windows\Temp\OSValidationTemplate.ps1"
$osFamilyName_encoded = $osFamilyName.Replace("``", "````").Replace("`"", "```"")
$testType = "WIM"
$AfterInternalRestore = $false
# $ArgumentStringArray = @( $pathToOSValidationMainPythonScript, $testRailTestRunId, "`"$($testRunTitle)`"", $testRailUsername, $encodedTestrailPassword, $pathToStoreOSValidationTemplateObject, $testType)
$ArgumentStringArray = @(   $pathToOSValidationMainPythonScript, 
                            $testRailTestRunId, 
                            "`"$($testRunTitle)`"", 
                            $testRailUsername, 
                            $encodedTestrailPassword, 
                            $pathToStoreOSValidationTemplateObject, 
                            $TestType, 
                            $AfterInternalRestore )


#and Call Script
Write-Host "Opening Python Script [$($pathToOSValidationMainPythonScript)] as a new process to Validate the [$($osFamilyName)][$($testRunTitle)] OS " -ForegroundColor Blue
Write-Host "DEBUG: Argument list is [$($ArgumentStringArray -join "  |  ")]"
Write-Host "DEBUG: Working Directory is [$($pathToOSValidationRootDir)]"



Start-Process $pathToPython -Verb RunAs -WorkingDirectory $pathToOSValidationRootDir -ArgumentList $ArgumentStringArray
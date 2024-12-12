$pathToPython = "\\d3deploydev\deploymentshare\PortablePython\WPy64-31241\python-3.12.4.amd64\python.exe" #Join-Path $Global:OSBuilderStaticConfig.disguiseTemplatingTemplatesRoot "WPy64-31241\python-3.12.4.amd64\python.exe"
$pathToOSValidationRootDir = "N:\OSValidation" 
$pathToOSValidationMainPythonScript = <# ".\ #>"main.py"
$osFamilyName ="OSValidation"
$osBuildName = "Testing"
$testRailUsername = "jacob.tomaszewski@disguise.one"
$encodedTestrailPassword = "UTtBLllfKCQ8ajNjZ1UySmtkS3dCWA=="
$testRailTestRunId = 14526
$pathToStoreOSValidationTemplateObject = "C:\Windows\Temp\OSValidationTemplate.ps1"
$osFamilyName_encoded = $osFamilyName.Replace("``", "````").Replace("`"", "```"")
$testType = "USB"
$ArgumentStringArray = @( $pathToOSValidationMainPythonScript, $testRailTestRunId, "`"$($osBuildName)`"", $testRailUsername, $encodedTestrailPassword, $pathToStoreOSValidationTemplateObject, $testType)

#and Call Script
Write-Host "Opening Python Script [$($pathToOSValidationMainPythonScript)] as a new process to Validate the [$($osFamilyName)][$($osBuildName)] OS " -ForegroundColor Blue
Write-Host "DEBUG: Argument list is [$($ArgumentStringArray -join "  |  ")]"
Write-Host "DEBUG: Working Directory is [$($pathToOSValidationRootDir)]"
Start-Process $pathToPython -Verb RunAs -WorkingDirectory $pathToOSValidationRootDir -ArgumentList $ArgumentStringArray
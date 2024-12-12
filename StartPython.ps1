param(
    [Parameter(Mandatory=$true)]
    [String]$PathToPythonInterpreter,
    [Parameter(Mandatory=$true)]
    [String]$PathToOSValidationMainPythonScript,    
    [Parameter(Mandatory=$true)]
    [String]$testRailTestRunID,
    [Parameter(Mandatory=$true)]
    [String]$OSBuildName,
    [Parameter(Mandatory=$true)]
    [String]$testRailUsername,
    [Parameter(Mandatory=$true)]
    [String]$EncodedTestRailPassword,
    [Parameter(Mandatory=$true)]
    [String]$PathToStoreOSValidationTemplateObject,
    [Parameter(Mandatory=$true)]
    [String]$TestType
)

# Setting up the mapped drive
$Username = "d3tech"
$Password = ConvertTo-SecureString "uvauvaDepl0y" -AsPlainText -Force
$cred = [PsCredential]::New($Username,$Password)
$letter = "T"

try{
    $drive = New-PSDrive -Persist  -Name $letter -PSProvider "FileSystem" -Root "\\d3deploydev\DeploymentShare" -Credential $cred -Scope Global -ErrorAction Stop
}catch{
    $errorMessage = "Something went wrong creating the temporary drive. Have you already got a mapped drive to letter [$($letter)]? If so please remove it and try again. Python will not be opened. `nSee error message: `n`n $($_)"
    Write-Error $errorMessage
    read-host
    return
}

$argumentStringArray = @($PathToOSValidationMainPythonScript, $testRailTestRunID, "`"$($OSBuildName)`"", $testRailUsername, $EncodedTestRailPassword, $PathToStoreOSValidationTemplateObject, $TestType)

try{
    Start-Process $PathToPythonInterpreter -Verb RunAs -ArgumentList $argumentStringArray -WorkingDirectory $PSScriptRoot
}catch{
    Write-Error "Something went wrong with the python command. `n`nPython file executed: [$($PathToOSValidationMainPythonScript)]. `n`nInterpreter path: [$($PathToPythonInterpreter)]. `n`n Arguments array [$($argumentStringArray)]. `n`nError:"
    Write-Error $_
}
finally{
    try{
        $drive | Remove-PSDrive
    }catch{
        Write-Error "Cannot remove drive [$($letter)]. Please do it manually."
    }
    
}

read-host

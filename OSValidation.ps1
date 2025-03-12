param(
    [Parameter(Mandatory=$true)]
    [int]$testRun,
    [Parameter(Mandatory=$true)]
    [String]$testRunTitle,
    [Parameter(Mandatory=$true)]
    [String]$testrailUsername,
    [Parameter(Mandatory=$true)]
    [String]$testrailPassword,
    [Parameter(Mandatory=$true)]
    [String]$OSValidationTemplatePath,
    [Parameter(Mandatory=$true)]
    [String]$TestType,
    [Parameter(Mandatory=$true)]
    [String]$afterInternalRestore_string
)

# ALLLLL (not quite all...) the imports
$configPath = Join-Path -path $PSScriptRoot -childpath "config"
$d3OSQAUtilsPath = Join-Path -path $PSScriptRoot -childpath "d3OSQAUtils"
$d3OSValidationRuntimeRunctions = Join-Path -path $PSScriptRoot -childpath "d3OSValidationRuntimeFunctions"
$disguiseDevicesQA = Join-Path -path $PSScriptRoot -childpath "disguiseDevicesQA"
$disguiseGeneralISOTests = Join-Path -path $PSScriptRoot -childpath "disguiseGeneralISOTests"
$disguiseWindowsSettingsQA = Join-Path -path $PSScriptRoot -childpath "disguiseWindowsSettingsQA"
$powershellyaml = Join-Path -path $PSScriptRoot -childpath "powershell-yaml"
Import-Module $configPath -Force
Import-Module $d3OSQAUtilsPath -Force
Import-Module $d3OSValidationRuntimeRunctions -Force
Import-Module $disguiseDevicesQA -Force
Import-Module $disguiseGeneralISOTests -Force
Import-Module $disguiseWindowsSettingsQA -Force
Import-Module $powershellyaml -Force

# Setting up logging
$timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
try{
    Start-Transcript -Path "C:\Windows\Logs\OSValidation-$($testRunTitle)-$($timestamp).log" -IncludeInvocationHeader
    $Global:OSValidationConfig.StartingTimestamp = $timestamp
}catch{
    Start-Transcript -Path "C:\Users\$($Env:UserName)\Desktop\OSValidation-$($testRunTitle)-$($timestamp).log" -IncludeInvocationHeader
}

# Main script
try{
    Start-MainScript -testRun $testRun -testRunTitle $testRunTitle -testrailUsername $testrailUsername -testrailPassword $testrailPassword -OSValidationTemplatePath $OSValidationTemplatePath -TestType $TestType -afterInternalRestore_string $afterInternalRestore_string
}catch{
    Write-Error "There was an error $($_.ScriptStackTrace) during runtime: `n`n$($_.Exception.Message)"
}finally{
    Stop-Transcript
}

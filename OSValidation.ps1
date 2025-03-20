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
Import-Module $disguiseGeneralISOTests -Force -Scope Global
Import-Module $disguiseWindowsSettingsQA -Force
Import-Module $powershellyaml -Force

# Setting up logging
$timestamp = Get-Date -Format "dd_MM_yyyy__HH_mm_ss"
$logTitle = $testRunTitle.Replace('.','').Replace(' ','_').Replace('-','').Replace('][','_').Replace('__','_').Replace(']','').Replace('[','')
try{
    $transcriptPath = "C:\Windows\Logs\OSValidation_$($logTitle)_$($timestamp).log"
    Write-Host "Attempting to start transcript at [ $($transcriptPath) ]"
    Start-Transcript -Path $transcriptPath #-IncludeInvocationHeader
    $Global:OSValidationConfig.StartingTimestamp = $timestamp
}catch{
    $transcriptPath = "C:\Users\$($Env:UserName)\Desktop\OSValidation_$($logTitle)_$($timestamp).log"
    Write-Host "Initial transcript start failed. Trying to start backup logs at [ $transcriptPath ]"
    Start-Transcript -Path $transcriptPath #-IncludeInvocationHeader
}

# Main script
try{
    Write-Host "Starting OS Validation test With following parameters:`n`t- testRun: `t`t`t`t[ $($testRun) ]`n`t- testRunTitle: `t`t`t[ $($testRunTitle) ]`n`t- testrailUsername: `t`t`t[ $($testrailUsername) ]`n`t- testrailPassword: `t`t`t[ $($testrailPassword) ]`n`t- OSValidationTemplatePath: `t`t[ $($OSValidationTemplatePath) ]`n`t- TestType: `t`t`t`t[ $($TestType) ]`n`t- afterInternalRestore_string: `t`t[ $($afterInternalRestore_string) ]"

    Start-MainScript -testRun $testRun -testRunTitle $testRunTitle -testrailUsername $testrailUsername -testrailPassword $testrailPassword -OSValidationTemplatePath $OSValidationTemplatePath -TestType $TestType -afterInternalRestore_string $afterInternalRestore_string
}catch{
    Write-Error "There was an error $($_.ScriptStackTrace) during runtime: `n`n$($_.Exception.Message)"
    Read-Host "Press Enter to exit..."
}finally{
    Stop-Transcript
    Read-Host "Press Enter to exit..."
}

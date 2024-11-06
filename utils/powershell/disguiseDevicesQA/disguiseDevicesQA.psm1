# Implement your module commands in this script.
# $d3ModelConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3ModelConfigImporter"
$d3OSQAUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\d3OSQAUtils"
# Import-Module $d3ModelConfigPath -Force
Import-Module $d3OSQAUtilsPath -Force

function Test-GraphicsCardControlPannel{
    param(        
        [Parameter(Mandatory=$true)]
        [String]$OSVersion,
        [Parameter(Mandatory=$true)]
        [String]$userInputMachineName
    )
    $path = Format-disguiseModulePathForImport -RepoName "disguisedsec" -ModuleName "d3HardwareValidation"
    Import-Module $path
    $hw = Assert-Hardware
    if($hw.gpu.Manufacturer -eq "NVIDIA"){
        $process = $null

        Get-AppxPackage 'NVIDIACorp.NVIDIAControlPanel' | % { 
            Copy-Item -LiteralPath $_.InstallLocation -Destination $Env:USERPROFILE\Desktop -Recurse -Force  | Out-Null
            Start-Process "$Env:USERPROFILE\Desktop\NVIDIACorp.NVIDIAControlPanel_*\nvcplui.exe"  | Out-Null
        }
        
        $process = Get-Process | Where-Object {$_.ProcessName -eq "nvcplui"} 
        start-sleep -Seconds 2

        if($process){
            $path = Join-Path -Path "Z:\OSQA\$($userInputMachineName)\$($OSVersion)\Images\Devices\" -ChildPath "NvidiaControlPannel.bmp"
            Get-PrintScreenandRetryIfFailed -PathAndFileName $path | Out-Null
            Stop-Process -Name $process.Name | Out-Null
            Wait-Process -Name $process.Name | Out-Null
        }

        $command = {Remove-Item "$Env:USERPROFILE\Desktop\NVIDIACorp.NVIDIAControlPanel_*" -Force -Recurse -WarningAction Continue}
        Invoke-Command -ScriptBlock $command | Out-Null

        if($process){
            return "PASSED"
        }else{
            return "FAILED"
        }
    }
    else{
        # AMD STUFF
        Write-Error "GPU Detected as AMD (or atleast not NVIDIA). This hasn't been implemented yet. Implement it?"
        return "UNTESTED"
    }
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*

$ModuleManifestName = 'd3OSQAUtils.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath
        $? | Should Be $true
    }
}

$ModuleName = 'd3OSQAUtils.psm1'
$ModulePath = "$PSScriptRoot\..\$ModuleName"
Import-Module $ModulePath -Force

# module tests go here

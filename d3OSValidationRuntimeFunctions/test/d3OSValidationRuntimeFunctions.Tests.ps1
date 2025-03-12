$ModuleManifestName = 'd3OSValidationRuntimeFunctions.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath
        $? | Should Be $true
    }
}

$ModuleName = 'd3OSValidationRuntimeFunctions.psm1'
$ModulePath = "$PSScriptRoot\..\$ModuleName"
Import-Module $ModulePath -Force

# module tests go here

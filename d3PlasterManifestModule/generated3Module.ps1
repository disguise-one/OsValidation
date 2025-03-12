param (
    [Parameter(Mandatory=$True)]
    [string]$ModuleName
)

Import-Module Plaster

#Changing path to allow it to work inside the powershell section
Invoke-Plaster -TemplatePath ".\d3PlasterManifestModule" -Destination ".\$ModuleName"  -Verbose -ModuleName $ModuleName
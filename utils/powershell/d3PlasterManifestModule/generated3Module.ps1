param (
    [Parameter(Mandatory=$True)]
    [string]$ModuleName
)

Import-Module Plaster

#Changing path to allow it to work inside the powershell section
Invoke-Plaster -TemplatePath ".\utils\powershell\d3PlasterManifestModule" -Destination ".\utils\powershell\$ModuleName"  -Verbose -ModuleName $ModuleName
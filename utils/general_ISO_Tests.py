import subprocess
from utils.test_case_classes import TestCase
from utils import useful_utilities

def check_projects_reg_paths(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-ProjectsRegPath"
    registryPathTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "754268", "RenderStream - Check registry path is correct")
    return registryPathTestCase

def check_logs_present(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-ReImageLogs"
    registryPathTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "754271", "Reimage Logs")
    return registryPathTestCase

def check_net_adapter_names(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-NICNames"
    registryPathTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "754273", "Network adapter naming")
    return registryPathTestCase

def check_machine_name(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-MachineName -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" )+ "\""
    machineNameTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "754270", "Machine Name")
    return machineNameTestCase

def check_audio_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-AudioCard -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    audioCardTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "754277", "Audio devices - Enabled in Device manager")
    return audioCardTestCase

def check_D_drive(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-DDrive"
    driveTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "754280", "Check for media drive")
    return driveTestCase
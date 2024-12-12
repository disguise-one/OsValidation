import subprocess
from utils.test_case_classes import TestCase
from utils import useful_utilities

def check_projects_reg_paths(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-ProjectsRegPath"
    registryPathTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374732", "RenderStream - Check registry path is correct")
    return registryPathTestCase

def check_logs_present(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-ReImageLogs"
    registryPathTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374740", "Reimage Logs")
    return registryPathTestCase

def check_net_adapter_names(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-NICNames"
    registryPathTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374740", "Reimage Logs")
    return registryPathTestCase

def check_machine_name(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-MachineName -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" )+ "\""
    machineNameTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374727", "Machine Name")
    return machineNameTestCase

def check_audio_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-AudioCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    audioCardTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "588215", "Audio devices - Enabled in Device manager")
    return audioCardTestCase

def check_D_drive(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseGeneralISOTests -Force -DisableNameChecking; Test-DDrive"
    driveTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374753", "Check for media drive")
    return driveTestCase
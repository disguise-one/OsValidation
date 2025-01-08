import subprocess
from utils.test_case_classes import TestCase
from utils import useful_utilities


def check_graphics_card_control_pannel(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-GraphicsCardControlPannel -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    GPUControlPannelTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374743", "Graphics Card Control Panel")
    return GPUControlPannelTestCase

def check_matrox_capture_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'MATROX'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    MatroxTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374748", "MATROX ONLY: Driver Check")
    return MatroxTestCase

def check_deltacast_capture_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'deltacast'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    deltacastTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "588212", "DELTACAST ONLY: Driver Check")
    return deltacastTestCase

def check_bluefish_capture_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'bluefish'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    bluefishTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374746", "BLUEFISH ONLY: Driver Check")
    return bluefishTestCase

def check_audio_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-AudioCard -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    audioCardTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374749", "Audio devices - Driver Version Check")
    return audioCardTestCase

def check_device_manager_driver_versions(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-DeviceManagerDriverVersions -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate \"" + OSValidationDict["OSValidationTemplatePath"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    return useful_utilities.RunPowershellAndParseOutput(powershellComand, "374755", "Driver Validation via Device Manager")


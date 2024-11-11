import subprocess
from utils.test_case_classes import TestCase

def check_graphics_card_control_pannel(OSVersion, ComputerName):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-GraphicsCardControlPannel -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    GPUControlPannelTestCase = TestCase("374748", "Graphics Card Control Panel", "UNTESTED")
    try:
        GPUControlPannel = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        GPUControlPannel = "UNTESTED"

    GPUControlPannelTestCase.set_testResult(str(GPUControlPannel))
    GPUControlPannelTestCase.printFormattedResults()
    return GPUControlPannelTestCase


def check_matrox_capture_cards(OSVersion, ComputerName):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName + "-CaptureCardManufacturer 'MATROX'"

    MatroxTestCase = TestCase("374748", "MATROX ONLY: Driver Check", "UNTESTED")
    try:
        MatroxResults = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        MatroxResults = "UNTESTED"

    if "FAILED" in MatroxResults:
        MatroxTestCase.set_testResult("FAILED")
    elif "WON'T TEST" in MatroxResults:
        MatroxTestCase.set_testResult("WON'T TEST")
    elif "REQUIRE MORE INFO" in MatroxResults:
        MatroxTestCase.set_testResult("REQUIRE MORE INFO")
    elif "Error" in MatroxResults:
        MatroxTestCase.set_testResult("BLOCKED")
    else:
        MatroxTestCase.set_testResult("PASSED")

    MatroxTestCase.set_testResultMessage(MatroxResults)
    MatroxTestCase.printFormattedResults()
    return MatroxTestCase

def check_deltacast_capture_cards(OSVersion, ComputerName):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName + "-CaptureCardManufacturer 'deltacast'"

    deltacastTestCase = TestCase("588212", "DELTACAST ONLY: Driver Check", "UNTESTED")
    try:
        deltacastResults = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        deltacastResults = "UNTESTED"

    if "FAILED" in deltacastResults:
        deltacastTestCase.set_testResult("FAILED")
    elif "WON'T TEST" in deltacastResults:
        deltacastTestCase.set_testResult("WON'T TEST")
    elif "REQUIRE MORE INFO" in deltacastResults:
        deltacastTestCase.set_testResult("REQUIRE MORE INFO")
    elif "Error" in deltacastResults:
        deltacastTestCase.set_testResult("BLOCKED")
    else:
        deltacastTestCase.set_testResult("PASSED")

    deltacastTestCase.set_testResultMessage(deltacastResults)
    deltacastTestCase.printFormattedResults()
    return deltacastTestCase

def check_bluefish_capture_cards(OSVersion, ComputerName):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName + "-CaptureCardManufacturer 'bluefish'"

    bluefishTestCase = TestCase("374746", "BLUEFISH ONLY: Driver Check", "UNTESTED")
    print("\033[93mWARNING: This function has not been tested, so please report any unexpected behaviour\033[0m")
    try:
        bluefishResults = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        bluefishResults = "UNTESTED"

    if "FAILED" in bluefishResults:
        bluefishTestCase.set_testResult("FAILED")
    elif "WON'T TEST" in bluefishResults:
        bluefishTestCase.set_testResult("WON'T TEST")
    elif "REQUIRE MORE INFO" in bluefishResults:
        bluefishTestCase.set_testResult("REQUIRE MORE INFO")
    elif "Error" in bluefishResults:
        bluefishTestCase.set_testResult("BLOCKED")
    else:
        bluefishTestCase.set_testResult("PASSED")

    bluefishTestCase.set_testResultMessage(bluefishResults)
    bluefishTestCase.printFormattedResults()
    return bluefishTestCase


import subprocess
from utils.test_case_classes import TestCase

def check_taskbar_icons(OSVersion, ComputerName):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-GraphicsCardControlPannel -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    GPUControlPannelTestCase = TestCase("374743", "Graphics Card Control Panel", "UNTESTED")
    try:
        GPUControlPannel = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
        print(GPUControlPannel)
    except:
        GPUControlPannel = "UNTESTED"

    GPUControlPannelTestCase.set_testResult(str(GPUControlPannel))
    GPUControlPannelTestCase.printFormattedResults()
    return GPUControlPannelTestCase
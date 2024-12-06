import subprocess
from utils.test_case_classes import TestCase
from utils import useful_utilities


def check_graphics_card_control_pannel(OSValidationDict):
    print("Inside graphics python function")
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-GraphicsCardControlPannel -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    GPUControlPannelTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374743", "Graphics Card Control Panel")
    return GPUControlPannelTestCase
    # Legacy, but may be useful if stuff starts going wrong
    # powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-GraphicsCardControlPannel -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]

    # GPUControlPannelTestCase = TestCase("374743", "Graphics Card Control Panel", "UNTESTED")
    # try:
    #     GPUControlPannel = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    # except Exception as error:
    #     GPUControlPannel = "BLOCKED"

    # if "FAILED" in GPUControlPannel:
    #     GPUControlPannelTestCase.set_testResult("FAILED")
    #     GPUControlPannelTestCase.set_testResultMessage(GPUControlPannel)
    # elif "PASSED" in GPUControlPannel:
    #     GPUControlPannelTestCase.set_testResult("PASSED")
    #     GPUControlPannelTestCase.set_testResultMessage(GPUControlPannel)
    # elif "UNTESTED" in GPUControlPannel:
    #     GPUControlPannelTestCase.set_testResult("UNTESTED")
    #     GPUControlPannelTestCase.set_testResultMessage("Result of [UNTESTED] as error detected in calling powershell script. Error message from Python: [" + str(error) + "]. If powershell has been called this is its output (unless [UNTESTED] is displayed, in which case the powershell process did not run): . Output of powershell process: [" + str(GPUControlPannel) + "]")
    # else:
    #     GPUControlPannelTestCase.set_testResult("UNTESTED")
    #     GPUControlPannelTestCase.set_testResultMessage("Untested as unhandled issue detected. Output of powershell process: [" + str(GPUControlPannel) + "]")
    
    # GPUControlPannelTestCase.printFormattedResults()
    # return GPUControlPannelTestCase




def check_matrox_capture_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'MATROX'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    MatroxTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374748", "MATROX ONLY: Driver Check")
    return MatroxTestCase
    # powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'MATROX'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]

    # MatroxTestCase = TestCase("374748", "MATROX ONLY: Driver Check", "UNTESTED")
    # try:
    #     MatroxResults = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    # except Exception as error:
    #     MatroxResults = "BLOCKED"
    #     MatroxTestCase.set_testResultMessage("Untested as unhandled issue detected when calling powershell script: [" + str(error) + "]")

    # if "FAILED" in MatroxResults:
    #     MatroxTestCase.set_testResult("FAILED")
    #     MatroxTestCase.set_testResultMessage(MatroxResults)
    # elif "WON'T TEST" in MatroxResults:
    #     MatroxTestCase.set_testResult("WON'T TEST")
    #     MatroxTestCase.set_testResultMessage(MatroxResults)
    # elif "REQUIRE MORE INFO" in MatroxResults:
    #     MatroxTestCase.set_testResult("REQUIRE MORE INFO")
    #     MatroxTestCase.set_testResultMessage(MatroxResults)
    # elif "Error" in MatroxResults:
    #     MatroxTestCase.set_testResult("BLOCKED")
    #     MatroxTestCase.set_testResultMessage(MatroxTestCase.get_testResultMessage() + "Error in powershell script: [" + MatroxResults + "]. ")
    # elif "UNTESTED" in MatroxResults:
    #     MatroxTestCase.set_testResult("UNTESTED")
    #     MatroxTestCase.set_testResultMessage(MatroxResults)
    # elif "PASSED" in MatroxResults:
    #     MatroxTestCase.set_testResult("PASSED")
    #     MatroxTestCase.set_testResultMessage(MatroxResults)
    # else:
    #     MatroxTestCase.set_testResult("BLOCKED")
    #     MatroxTestCase.set_testResultMessage(MatroxResults)

    # MatroxTestCase.printFormattedResults()
    # return MatroxTestCase



def check_deltacast_capture_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'deltacast'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    deltacastTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "588212", "DELTACAST ONLY: Driver Check")
    return deltacastTestCase
    # powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'deltacast'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]

    # deltacastTestCase = TestCase("588212", "DELTACAST ONLY: Driver Check", "UNTESTED")
    # try:
    #     deltacastResults = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    # except Exception as error:
    #     deltacastResults = "BLOCKED"
    #     deltacastTestCase.set_testResultMessage("Untested as unhandled issue detected when calling powershell script: [" + str(error) + "]. ")


    # if "FAILED" in deltacastResults:
    #     deltacastTestCase.set_testResult("FAILED")
    #     deltacastTestCase.set_testResultMessage(deltacastResults)
    # elif "WON'T TEST" in deltacastResults:
    #     deltacastTestCase.set_testResult("WON'T TEST")
    #     deltacastTestCase.set_testResultMessage(deltacastResults)
    # elif "REQUIRE MORE INFO" in deltacastResults:
    #     deltacastTestCase.set_testResult("REQUIRE MORE INFO")
    #     deltacastTestCase.set_testResultMessage(deltacastResults)
    # elif "Error" in deltacastResults:
    #     deltacastTestCase.set_testResult("BLOCKED")
    #     deltacastTestCase.set_testResultMessage(deltacastTestCase.get_testResultMessage() + "Error in powershell script: [" + deltacastResults + "]")
    # elif "UNTESTED" in deltacastResults:
    #     deltacastTestCase.set_testResult("UNTESTED")
    #     deltacastTestCase.set_testResultMessage(deltacastResults)
    # elif "PASSED" in deltacastResults:
    #     deltacastTestCase.set_testResult("PASSED")
    #     deltacastTestCase.set_testResultMessage(deltacastResults)
    # else:
    #     deltacastTestCase.set_testResult("BLOCKED")
    #     deltacastTestCase.set_testResultMessage(deltacastResults)

    
    # deltacastTestCase.printFormattedResults()
    # return deltacastTestCase

def check_bluefish_capture_cards(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'bluefish'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]
    bluefishTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374746", "BLUEFISH ONLY: Driver Check")
    return bluefishTestCase

    # powershellComand = "import-Module .\\utils\\powershell\\disguiseDevicesQA -Force -DisableNameChecking; Test-CaptureCard -OSVersion \"" + OSValidationDict["OSVersion"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -userInputMachineName \"" + OSValidationDict["ServerName"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -CaptureCardManufacturer 'bluefish'" + " -pathToOSValidationTemplate " + OSValidationDict["OSValidationTemplatePath"]

    # bluefishTestCase = TestCase("374746", "BLUEFISH ONLY: Driver Check", "UNTESTED")
    # print("\033[93mWARNING: This function has not been tested, so please report any unexpected behaviour\033[0m")
    # try:
    #     bluefishResults = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    # except Exception as error:
    #     bluefishResults = "BLOCKED"
    #     bluefishTestCase.set_testResultMessage("Untested as unhandled issue detected when calling powershell script: [" + str(error) + "]. ")

    # if "FAILED" in bluefishResults:
    #     bluefishTestCase.set_testResult("FAILED")
    #     bluefishTestCase.set_testResultMessage(bluefishResults)
    # elif "WON'T TEST" in bluefishResults:
    #     bluefishTestCase.set_testResult("WON'T TEST")
    #     bluefishTestCase.set_testResultMessage(bluefishResults)
    # elif "REQUIRE MORE INFO" in bluefishResults:
    #     bluefishTestCase.set_testResult("REQUIRE MORE INFO")
    #     bluefishTestCase.set_testResultMessage(bluefishResults)
    # elif "Error" in bluefishResults:
    #     bluefishTestCase.set_testResult("BLOCKED")
    #     bluefishTestCase.set_testResultMessage(bluefishTestCase.get_testResultMessage() + "Error in powershell script: [" + bluefishResults + "]")
    # elif "UNTESTED" in bluefishResults:
    #     bluefishTestCase.set_testResult("UNTESTED")
    #     bluefishTestCase.set_testResultMessage(bluefishResults)
    # elif "PASSED" in bluefishResults:
    #     bluefishTestCase.set_testResult("PASSED")
    #     bluefishTestCase.set_testResultMessage(bluefishResults)
    # else:
    #     bluefishTestCase.set_testResult("BLOCKED")
    #     bluefishTestCase.set_testResultMessage(bluefishResults)

    # bluefishTestCase.printFormattedResults()
    # return bluefishTestCase


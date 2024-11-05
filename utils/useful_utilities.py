import subprocess
import json

def printError(output):
    RED = '\033[31m'
    RESET = '\033[0m' # called to return to standard terminal text color
    errorMsg = RED + output + RESET
    print(errorMsg)

def ImportOSValidationConfig(OSValidationConfigPath="./config/OSValidationConfig.json"):
    OSValidationConfigRaw = None
    OSValidationConfigJson = None

    try:
        with open(OSValidationConfigPath) as OSValidationConfigRaw:
            OSValidationConfigJson = json.load(OSValidationConfigRaw)
    except:
        printError("ERROR: Cannot access [" + OSValidationConfigPath + "]. Is the file there? Is it open in another file? Exiting script.")
        input("Press Enter to continue...")
        exit()
    
    return OSValidationConfigJson


def ImportOSValidationSecureConfig(OSValidationConfigJson):

    if(OSValidationConfigJson == None):
        OSValidationConfigJson = ImportOSValidationConfig()

    UserCredentialsRaw = None
    UserCredentialsJson = None
    UserCredentialsPath = str(OSValidationConfigJson['userCredentialsPath'])

    try:
        with open(UserCredentialsPath) as UserCredentialsRaw:
            UserCredentialsJson = json.load(UserCredentialsRaw)
    except:
        printError("ERROR: Cannot access [" + UserCredentialsPath + "]. Creating file at location...")
        # it tries to make one for them
        success = createTestrailUserConfig(UserCredentialsPath)
        if(success == False):
            # If this doesnt work 
            printError('ERROR: File creation unsuccessful. Steps to resolve: Please go to OSValidation/config, and create a file called UserCredentials.local.json\n Inside it please write \n{\n\t"testRailUsername": "*YOUR USERNAME*",\n\t"testRailPassword": "*YOUR PASSWORD*"\n}\n If this does not work, contact Systems Integration (Jake)')
            input("Press Enter when you have completed this to continue...")
        # If the file has been created we try and reload the JSON data
        if(success == True):
            try:
                with open(UserCredentialsPath) as UserCredentialsRaw:
                    UserCredentialsJson = json.load(UserCredentialsRaw)
            except:
                # If we cant reload the data for the second time we kick the user out the script to try again
                printError('ERROR: Cannot find [' + UserCredentialsPath + "] for a second time. Re-run script. Exiting")
                input("Press Enter to continue...")
                exit()
        
    return UserCredentialsJson

# Asks the user to enter their username and password to testrail, and saves it as the usercredentials.local.json
def createTestrailUserConfig(UserCredentialsPath):
        Username = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter your TestRail username:', 'Testrail Username')"]).strip().decode('utf-8')
        Password = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter your TestRail password:', 'Testrail Password')"]).strip().decode('utf-8')
        userInfoDict = {
            "testRailUsername": Username,
            "testRailPassword": Password
        }
        # Overwrite, just in case of a security issue
        Username = None
        Password = None

        # Serializing json
        jsonToWrite = json.dumps(userInfoDict, indent=1)
        
        # Writing to sample.json
        try:
            with open(UserCredentialsPath, "w") as outfile:
                outfile.write(jsonToWrite)
        except:
            return False
            
        return True

# This is a wrapper function for the Powershell module d3ModelConfigImporter/Import-ModelConfig
# It opens a powershell subprocess, imports the module, executes the function, and returns a python object containing the powersehll disguisedPower model config info
def ImportModelConfig():
    powershellComand = "import-Module .\\utils\\powershell\\d3ModelConfigImporter -Force -DisableNameChecking; Import-ModelConfig "
    ConfigString = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    ConfigObject = json.loads(ConfigString)
    return ConfigObject


        


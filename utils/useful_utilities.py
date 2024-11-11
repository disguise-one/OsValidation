import subprocess
import json
import tkinter as tk
import os
import re

def printError(output):
    RED = '\033[31m'
    RESET = '\033[0m' # called to return to standard terminal text color
    errorMsg = RED + output + RESET
    print(errorMsg)

def printWarning(output):
    RED = '\033[93m'
    RESET = '\033[0m' # called to return to standard terminal text color
    warningMsg = RED + output + RESET
    print(warningMsg)

def ImportOSValidationConfig(OSValidationConfigPath="./config/OSValidationConfig.json"):
    OSValidationConfigRaw = None
    OSValidationConfigJson = None
    # get working directory
    path = os.getcwd()
    # combine paths
    OSValidationConfigPath = os.path.join(path, OSValidationConfigPath)
    try:
        with open(OSValidationConfigPath) as OSValidationConfigRaw:
            OSValidationConfigJson = json.load(OSValidationConfigRaw)
    except:
        printError("ERROR: Cannot access [" + OSValidationConfigPath + "]. Is the file there? Is it open in another file? Exiting script.")
        input("Press Enter to continue...")
        exit()
    
    return OSValidationConfigJson


def ImportOSValidationSecureConfig(OSValidationConfigJson, ignoreCreateNewAccount = False, userCredentialsPath = None):

    if(OSValidationConfigJson == None):
        OSValidationConfigJson = ImportOSValidationConfig()

    UserCredentialsRaw = None
    UserCredentialsJson = None
    if(not(userCredentialsPath)):
        UserCredentialsPath = str(OSValidationConfigJson['userCredentialsPath'])

    try:
        with open(UserCredentialsPath) as UserCredentialsRaw:
            UserCredentialsJson = json.load(UserCredentialsRaw)
    except:
        printError("ERROR: Cannot access [" + UserCredentialsPath + "]")
        return None
        # if(not(ignoreCreateNewAccount)):
            
        #     # it tries to make one for them
        #     success = createTestrailUserConfig(UserCredentialsPath)
        #     if(success == False):
        #         # If this doesnt work 
        #         printError('ERROR: File creation unsuccessful. Steps to resolve: Please go to OSValidation/config, and create a file called UserCredentials.local.json\n Inside it please write \n{\n\t"testRailUsername": "*YOUR USERNAME*",\n\t"testRailPassword": "*YOUR PASSWORD*"\n}\n If this does not work, contact Systems Integration (Jake)')
        #         input("Press Enter when you have completed this to continue...")
        #     # If the file has been created we try and reload the JSON data
        #     if(success == True):
        #         try:
        #             with open(UserCredentialsPath) as UserCredentialsRaw:
        #                 UserCredentialsJson = json.load(UserCredentialsRaw)
        #         except:
        #             # If we cant reload the data for the second time we kick the user out the script to try again
        #             printError('ERROR: Cannot find [' + UserCredentialsPath + "] for a second time. Re-run script. Exiting")
        #             input("Press Enter to continue...")
        #             exit()
        # else:
        #     return None
        
    return UserCredentialsJson

# Asks the user to enter their username and password to testrail, and saves it as the usercredentials.local.json
def createTestrailUserConfig(UserCredentialsPath = None):
    # read in the JSON
    # append a user to it
    # json.dumps to save it to the file and overwrite it

    # find the path to the json
    if(not(UserCredentialsPath)):
        OSValidationConfigJson = ImportOSValidationConfig()
        UserCredentialsPath = str(OSValidationConfigJson['userCredentialsPath'])

    # User Creation UI
    print("====User Creation====")
    name = input("Please enter new Name of the user (eg: Jake Tomaszewski): ")
    userName = input("Please enter Testrail Username: ")
    userPassword = input("Please enter Testrail password: ")

    # Storing the info as a dict
    userInfoDict = {
        "Name" : name,
        "testRailUsername": userName,
        "testRailPassword": userPassword
    }

    # opening the JSON
    try:
        with open(UserCredentialsPath, "r") as outfile:
            UserCredentialsJson = json.load(outfile)
    except:
        printError("ERROR: cannot open [userCredentials.local.json] file at path [" + str(UserCredentialsPath) + "]")
        return False
    
    UserCredentialsJson.append(userInfoDict)
    jsonToWrite = json.dumps(UserCredentialsJson, indent=1)

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

def userSelectionConsole(UserCredentialsJson = None):
    if(UserCredentialsJson == None):
        printError("ERROR: Function userSelectionConsole: User Credential Json MUST be provided")
        return None
    
    userChoice = 10000
    
    # greater than + 1 to user choice to take into account of the create new account
    while(int(userChoice) > len(UserCredentialsJson) + 1):
        index = 1
        print("Please select user: \n" + str(index) + ": Create New Account")
        for account in UserCredentialsJson:
            index = index + 1
            print(str(index) + ": " + str(account["Name"]))
        userChoice = input("Selection: ")
        if(re.search("\D", userChoice)):
            print("\n\n")
            print("Input [" + str(userChoice) + "] not accepted, please only input the number corresponding to the account you would like to use.")
            userChoice = 10000
    return int(userChoice)


        


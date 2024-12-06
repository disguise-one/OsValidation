import subprocess
import json
import tkinter as tk
import os
import re
from utils.test_case_classes import TestCase
# import pillow

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

def printColor(output, color):
    print(f"\033[38;5;{color}m{output}\033[0m")


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


# This is a wrapper function for the Powershell module d3ModelConfigImporter/Import-ModelConfig
# It opens a powershell subprocess, imports the module, executes the function, and returns a python object containing the powersehll disguisedPower model config info
def ImportModelConfig():
    powershellComand = "import-Module .\\utils\\powershell\\d3ModelConfigImporter -Force -DisableNameChecking; Import-ModelConfig "
    ConfigString = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    ConfigObject = json.loads(ConfigString)
    return ConfigObject



def uploadTestBatchToTestRail(testBatch, runRequrestResponse, client):
    """
    uploadTestBatchToTestRail
    This function takes an array of testcase classes, loops through them and uploads them to testRail via the TestRailAPI. It checks the runrequestresponse to ensure the 
    testrail API is configured correctly. It has some user interaction if the upload fails it asks if the user would like to retry or abort

    :testBatch:             List of testCase classes
    :runRequestResponse:    Integer containing the api response from the initial setup of the test run in main()
    :client:                testrail class containing information about the user. Username/password etc...
    
    """
    import urllib
    # Now we check which response the API gave back
    if(runRequrestResponse != -1):
        # Once all tests are called we loop through and send to the API request
        failedUploads = []
        for testcase in testBatch:                          #str(runRequrestResponse['id'])
            # No 'do...while' in python. A loop that is evaluated at the end is required, so I will implement it like this
            retries = 3
            while True:
                result = None
                print(testcase.formatSendingResultsMessage())
                try:
                    result = client.send_post('add_result_for_case/' + str(urllib.parse.quote_plus(str(runRequrestResponse['id']))) + '/' + str(urllib.parse.quote_plus(str(testcase.get_testCode()))), {
                        'status_id': str(testcase.get_testStatusCode()), 'comment': testcase.get_testResultMessage()
                    })
                except Exception as e: 
                    print("An error occured when communicating with TestRail API: " + str(e))

                
                if(result != None):
                    break
                else:
                    # Python doenst have any easy inbuilt way to have a user input with time out - Using a batch command instead
                    output = 'CHOICE /T 10 /C Yn /D Y /M "Testrail API returned a non [200] return code, indicating an error communicating with the API. Retry? Waiting 5 seconds for user input. Retrying ' + str(retries) + ' more times..."'
                    userInput = None
                    userInput = subprocess.call(output, shell=True)
                    print("userInput: " + str(userInput))
                    retries = retries - 1
                    # As N is option 2, it defaults to this if it times out so it retries the API request, or the user enters Y to abort, it breaks
                    if(userInput == 2 or retries == 0):
                        failedUploads.append(str("\n\tTest Name:\t\t" + str(testcase.get_testName()) + "\n\tResult:\t\t" + str(testcase.get_testResult()) + ". \n\tMessage:\t" + str(testcase.get_testResultMessage())))
                        break
            
            # Now we upload any images if they have been set
            if(testcase.get_testImagePathArr()):
                print("Image upload in progress...")
                # we need to get the resultID To be able to upload an image to it
                results = client.send_get(f"get_results_for_case/{str(urllib.parse.quote_plus(str(runRequrestResponse['id'])))}/{str(urllib.parse.quote_plus(str(testcase.get_testCode())))}")
                # This gets all results for that id and test code, so we now need to find the greatest created_on value and find the associated record
                mostRecentTimeIndex = 0
                for index in range(len(results["results"])):
                    if results["results"][index]["created_on"] > results["results"][mostRecentTimeIndex]["created_on"]:
                        mostRecentTimeIndex = index

                # Pull the test ID out the most recent record
                testId = results["results"][mostRecentTimeIndex]["id"]

                # Go through each image path passed in and uplaod it
                doNotUpload = False
                for imagePath in testcase.get_testImagePathArr():
                    # check the image exists
                    if not os.path.exists(imagePath):
                        print(f"Image cannot be found at [{imagePath}] for test run [{testcase.get_testName()}]. Upload aborted.")
                        doNotUpload = True
                        
                    # Upload it if you can find the image
                    if not doNotUpload:
                        result = client.send_post(f'add_attachment_to_result/{str(testId)}',imagePath)
                        print(f"File uploaded to test rail with API Result code: {result}")
            
                
                    
        print("DONE")
        return failedUploads

    elif(runRequrestResponse == -1):
        printError("Error Response -1: Error indicates there was an problem adding run to test rail. Script exited")
        input("Exiting script. Press enter to exit...")
        # TO DO: Output results as a text file so the testing is not lost!!
        exit()


def RunPowershellAndParseOutput(PowershellCommand, testCaseID, testCaseName):
    testCase = TestCase(testCaseID, testCaseName, "Untested")
    # run the command
    try:
        PowershellOutput = subprocess.check_output(['powershell', '-executionpolicy', 'Bypass', '-Command', PowershellCommand], shell=False).strip().decode('utf-8')
    except Exception as error:
        printError("Error: Issue with running subprocess [" + str(PowershellCommand) + "]. Error Message: [" + str(error) + "]")
        return None
    # we split it by new lines
    PowershellOutput = PowershellOutput.split("\n")
    # as there may be no \n inside a well run script, there may be nothing to split. So we need to check if this has worked, and if it has not split anything, convert 
    # the string that it returns to an array with 1 row
    if(isinstance(PowershellOutput,str)):
        PowershellOutput = [PowershellOutput]
        hasMoreInfo = False
    else:
        hasMoreInfo = True
    # on the last line is the JSON result
    JsonObjectAsString = PowershellOutput[len(PowershellOutput)-1]
    try:
        PythonObject = json.loads(JsonObjectAsString)
    except Exception as error:
        printError("Error: Cannot convert output of command [" + str(PowershellCommand) + "] to JSON. \n\nOutput is [" + str(PowershellOutput) + "]. \n\nWith string attempting to be converted is [" + str(JsonObjectAsString) + "]")
        return None
    
    fullOutput = {
        "RawOutput" : PowershellOutput,
        "DebugMessage" : PowershellOutput[0:len(PowershellOutput)-2] if hasMoreInfo else "",
        "Results" : PythonObject
    }

    if fullOutput["DebugMessage"]:
        printColor("\n-------------------------------------------------\nPowershell Script Logged The Folloing Debug Info:\n-------------------------------------------------",250)
        for message in PowershellOutput[0:len(PowershellOutput)-2]:
            printColor(str(message), 245)
        printColor("-------------------------------------------------\n",250)

 
    testCase.set_testResult(fullOutput["Results"]["OverallResult"])
    testCase.set_testResultMessage(fullOutput["Results"]["Message"])
    testCase.set_testPathToImageArr(fullOutput["Results"]["PathToImage"])
    testCase.printFormattedResults()
    
    return testCase

    


#===================================================================================
# LEGACY CODE. This is depreciated but may be useful in the future? so I wont delete it but it has now been removed
#===================================================================================
# Legacy Code
# def userSelectionConsole(UserCredentialsJson = None):
#     if(UserCredentialsJson == None):
#         printError("ERROR: Function userSelectionConsole: User Credential Json MUST be provided")
#         return None
    
#     userChoice = 10000
    
#     # greater than + 1 to user choice to take into account of the create new account
#     while(int(userChoice) > len(UserCredentialsJson) + 1):
#         index = 1
#         print("Please select user: \n" + str(index) + ": Create New Account")
#         for account in UserCredentialsJson:
#             index = index + 1
#             print(str(index) + ": " + str(account["Name"]))
#         userChoice = input("Selection: ")
#         if(re.search("\D", userChoice)):
#             print("\n\n")
#             print("Input [" + str(userChoice) + "] not accepted, please only input the number corresponding to the account you would like to use.")
#             userChoice = 10000
#     return int(userChoice)

# Legacy Code
# def ImportOSValidationSecureConfig(OSValidationConfigJson, ignoreCreateNewAccount = False, userCredentialsPath = None):

#     if(OSValidationConfigJson == None):
#         OSValidationConfigJson = ImportOSValidationConfig()

#     UserCredentialsRaw = None
#     UserCredentialsJson = None
#     if(not(userCredentialsPath)):
#         UserCredentialsPath = str(OSValidationConfigJson['userCredentialsPath'])

#     try:
#         with open(UserCredentialsPath) as UserCredentialsRaw:
#             UserCredentialsJson = json.load(UserCredentialsRaw)
#     except:
#         printError("ERROR: Cannot access [" + UserCredentialsPath + "]")
#         return None
#         # if(not(ignoreCreateNewAccount)):
            
#         #     # it tries to make one for them
#         #     success = createTestrailUserConfig(UserCredentialsPath)
#         #     if(success == False):
#         #         # If this doesnt work 
#         #         printError('ERROR: File creation unsuccessful. Steps to resolve: Please go to OSValidation/config, and create a file called UserCredentials.local.json\n Inside it please write \n{\n\t"testRailUsername": "*YOUR USERNAME*",\n\t"testRailPassword": "*YOUR PASSWORD*"\n}\n If this does not work, contact Systems Integration (Jake)')
#         #         input("Press Enter when you have completed this to continue...")
#         #     # If the file has been created we try and reload the JSON data
#         #     if(success == True):
#         #         try:
#         #             with open(UserCredentialsPath) as UserCredentialsRaw:
#         #                 UserCredentialsJson = json.load(UserCredentialsRaw)
#         #         except:
#         #             # If we cant reload the data for the second time we kick the user out the script to try again
#         #             printError('ERROR: Cannot find [' + UserCredentialsPath + "] for a second time. Re-run script. Exiting")
#         #             input("Press Enter to continue...")
#         #             exit()
#         # else:
#         #     return None
        
#     return UserCredentialsJson

# Legacy code:
# Asks the user to enter their username and password to testrail, and saves it as the usercredentials.local.json
# def createTestrailUserConfig(UserCredentialsPath = None):
#     # read in the JSON
#     # append a user to it
#     # json.dumps to save it to the file and overwrite it

#     # find the path to the json
#     if(not(UserCredentialsPath)):
#         OSValidationConfigJson = ImportOSValidationConfig()
#         UserCredentialsPath = str(OSValidationConfigJson['userCredentialsPath'])

#     # User Creation UI
#     print("====User Creation====")
#     name = input("Please enter new Name of the user (eg: Jake Tomaszewski): ")
#     userName = input("Please enter Testrail Username: ")
#     userPassword = input("Please enter Testrail password: ")

#     # Storing the info as a dict
#     userInfoDict = {
#         "Name" : name,
#         "testRailUsername": userName,
#         "testRailPassword": userPassword
#     }

#     # opening the JSON
#     try:
#         with open(UserCredentialsPath, "r") as outfile:
#             UserCredentialsJson = json.load(outfile)
#     except:
#         printError("ERROR: cannot open [userCredentials.local.json] file at path [" + str(UserCredentialsPath) + "]")
#         return False
    
#     UserCredentialsJson.append(userInfoDict)
#     jsonToWrite = json.dumps(UserCredentialsJson, indent=1)

#     try:
#         with open(UserCredentialsPath, "w") as outfile:
#             outfile.write(jsonToWrite)
#     except:
#         return False
        
#     return True



        


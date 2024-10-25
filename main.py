# Check that the requiements are installed - Only run this on first run to ensure all modules are installed
from utils.auto_import import import_or_install
firstTimeRun = True    # <- set this to true to check
if(firstTimeRun == True):
    import_or_install("requirements.txt")
    print("Starting OS QA checking:")


from utils import file_handling, windows_settings, d3_interaction, useful_utilities
from utils.logger import logging
from utils import testrail
import subprocess
import sys, select
import json


def gather_user_idenitifaction_of_run():
    ServerName = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the Server you are testing as it appears on the config file name (or for multi-machine config files, CodeMeterProductCodes -> d3Model):', 'Auto OS QA')"]).strip().decode('utf-8')
    OSVersion = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the OS version you are testing:', 'Auto OS QA')"]).strip().decode('utf-8')
    # description = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Do you want to add any optional description to your test run? Enter nothing if no:', 'Auto OS QA')"]).strip().decode('utf-8')
    return ServerName, OSVersion #, description


def run_validation_group(validation_functions, group_name, OSVersion, MachineName):
    """
    Executes a group of validation functions and handles common exceptions.

    This function logs the start of each validation group, runs each function
    in the list, and handles keyboard interrupts and unexpected exceptions.

    Args:
        validation_functions (list): A list of functions to be executed.
        group_name (str): Name of the validation group for logging purposes.
    """
    TestRunArray = []
    try:
        logging.info(f"--- Running Test Group {group_name} ---")
        for function in validation_functions:
            TestRunArray.append(function(OSVersion, MachineName))
        return TestRunArray
    except KeyboardInterrupt:
        logging.info("Keyboard Interrupt received, exiting the program.")
        sys.exit(0)
    except Exception as e:
        logging.exception(f"An unexpected error occurred: {e}")
        


def main():
    """
    Main function to orchestrate various validation checks.

    This function is the entry point of the script. It first loads the configuration,
    then runs different groups of validation functions related to Windows settings,
    file handling, device checks, and d3 interaction.
    """

    # !!! ---- WHEN CHANGING FROM SANDBOX TESTRAIL TO LIVE TEST RAIL *ENSURE* YOU CHANGE THE TEST CODE ON EACH TEST FUNCTION ---- !!!
    
    # ===================== Config file creation ===================== #
    #   SECTION OPERATIONS:
    # In this section we go through all the config files, ensuring they are there, and reading them in
    # If the user hasnt set up their local login config file it tries to make one for them,
    # if this doesnt work it prompts them to make one


    # Pull the JSON files. If you havent set up a UserCredentials.local.JSON file it will create one for you, and prompt you for the information
    OSValidationConfigJson = useful_utilities.ImportOSValidationConfig()

    # sanity checks to ensure above has worked
    if(OSValidationConfigJson == None):
        useful_utilities.printError("Cannot access OSValidationConfig.json. This is necessary for the script to continue. Exiting.")
        input("Press Enter to continue...")
        exit()

    # --- Now we use the config to find the local config ---
    UserCredentialsJson = useful_utilities.ImportOSValidationSecureConfig(OSValidationConfigJson)
    
    if(UserCredentialsJson == None):
        useful_utilities.printError("Cannot access UserCredentials.local.json. This is necessary for the script to continue. Exiting.")
        input("Press Enter to continue...")
        exit()

    ModelConfig = useful_utilities.ImportModelConfig()

    # ===================== Interacting with Testrail API ===================== #

    # In this section we pull all the TestRail information, if the testRun field in OSCalidationConfig.json is filled out we pull that test run
    # else we set up a new test run 

    # The TestRail API uses python binding: https://support.testrail.com/hc/en-us/articles/7077135088660-Binding-Python#01G68HCTTNHFT1WVDXKW4BC4WP
    # Where you ab either get or post to the API, with a standard format filter to identify what you want to do
    # Eg send_get('get_runs/2&suite_id=6279') says get the runs of project 2 with suite id of 6279
    # Need to do something with this \/ Make it securer
    client = testrail.APIClient(str(OSValidationConfigJson['testRailAPI']))
    client.user = str(UserCredentialsJson['testRailUsername'])
    client.password = str(UserCredentialsJson['testRailPassword'])

    projectNumber = OSValidationConfigJson["projectNumber"]
    suite_id = OSValidationConfigJson["suite_id"]
    testRun = OSValidationConfigJson["testRun"]

    # Gather the user id of runs and stuff
    ServerName, OSVersion = gather_user_idenitifaction_of_run()       # <- description not working yet

    # Check the user inputted the required data
    if((ServerName == "") or (OSVersion == "")):
        useful_utilities.printError("Server Name and OS Version is required. Exiting script")
        input("Press Enter to continue...")
        exit()

    # We need to get the latest test run number, and increase it to set up the next test run -> maybe not needed?
    allCases = client.send_get('get_cases/' + str(OSValidationConfigJson["projectNumber"]) + '&suite_id=' + str(suite_id))
    allRuns = client.send_get('get_runs/' + str(OSValidationConfigJson["projectNumber"]) + '&suite_id=' + str(suite_id))
    currentRunNumber = len(allRuns['runs']) + 1

    # Setting up the new run, if we want it to. Otherwise we get the existing run
    if(OSValidationConfigJson["testRun"] == None):
        runAPIString = 'add_run/' + str(OSValidationConfigJson["projectNumber"]) + '&suite_id=' + str(suite_id) + '&name=' + ServerName + '_' + OSVersion
    else:
        runAPIString = 'get_run/'+ str(OSValidationConfigJson["testRun"]) + '&suite_id=' + str(suite_id) + '&project_id='+str(OSValidationConfigJson["projectNumber"])

    
    runRequrestResponse = -1
    # if(description != ''):
    #     runAPIString += "&description=" + description


    try:
        # Send a requrest to the API to create a test run

        if(testRun == None):
            runRequrestResponse = client.send_post(runAPIString, {
            "suite_id": OSValidationConfigJson["suite_id"],
            "name": ServerName + "_" + OSVersion + "_TESTING_NOT_REAL_RESULTS",
            # "description": description,
            "include_all": True,
            })
        else:
            runRequrestResponse = client.send_get(runAPIString)
    except Exception as error:
        useful_utilities.printError("An error occured when trying to communicate with TestRail API: " + str(error))

    # Now we check which response the API gave back
    if(runRequrestResponse != -1):
        
        # Run the windows validation functions for startup and windows sections
        windows_validation_functions = [
            windows_settings.check_taskbar_icons,
            windows_settings.check_start_menu_tiles,
            windows_settings.check_app_menu_contents,
            windows_settings.check_windows_licensing,
            windows_settings.check_chrome_history,
            windows_settings.check_chrome_homepage,
            windows_settings.check_chrome_bookmarks,
            windows_settings.check_machine_name,
            windows_settings.check_notifications_disabled
        ]
        windowsTests = run_validation_group(windows_validation_functions, "Windows Settings", OSVersion, ServerName)

        # Once all tests are called we loop through and send to the API request
        for testcase in windowsTests:                          #str(runRequrestResponse['id'])
            # No 'do...while' in python. A loop that is evaluated at the end is required, so I will implement it like this
            while True:
                result = None
                result = client.send_post('add_result_for_case/' + str(runRequrestResponse['id']) + '/' + str(testcase.get_testCode()), {
                    'status_id': str(testcase.get_testStatusCode()), 'comment': testcase.get_testResultMessage()
                })
                if(result != None):
                    break
                else:
                    # Python doenst have any easy inbuilt way to have a user input with time out - Using a batch command instead
                    userInput = None
                    userInput = subprocess.call('CHOICE /T 10 /C YN /D N /M "Testrail API returned a non [200] return code, indicating an error communicating with the API. Abort retry? Waiting 5 seconds for user input..."', shell=True)
                    # As N is option 2, it defaults to this if it times out so it retries the API request, or the user enters Y to abort, it breaks
                    if(userInput == 1):
                        break
    
                    
                    
            print(testcase.get_testName() + ": " + testcase.get_testResult() + ": " +  str(testcase.get_testStatusCode()))

    
        print("DONE")

    elif(runRequrestResponse == -1):
        useful_utilities.printError("Error Response -1: Error indicates there was an problem adding run to test rail. Script exited")







    # else:
    #     # Load the configuration from YAML file
    #     devices.load_config()

    #     # Group of functions for validating Windows settings
    #     windows_validation_functions = [
    #         windows_settings.check_taskbar_icons,
    #         windows_settings.check_start_menu_tiles,
    #         windows_settings.check_app_menu_contents,
    #         windows_settings.check_windows_licensing,
    #         windows_settings.check_windows_background_color,
    #         windows_settings.check_machine_name,
    #         windows_settings.check_notifications_disabled,
    #         windows_settings.check_sticky_keys_disabled,
    #         windows_settings.check_windows_firewall_disabled
    #     ]
    #     windowsTests = run_validation_group(windows_validation_functions, "Windows Settings", OSVersion)

    #     # Group of functions for file handling validation
    #     file_handling_functions = [
    #         file_handling.check_system_failure_checkboxes,
    #         file_handling.check_dump_file_path,
    #         file_handling.check_file
    #     ]
    #     run_validation_group(file_handling_functions, "File Handling")

    #     # Group of functions for device validation
    #     device_validation_functions = [
    #         devices.check_general_devices,
    #         devices.detect_gpu_brand,
    #         devices.check_gpu_devices,
    #         devices.check_network_devices,
    #         devices.check_capture_card_devices,
    #         devices.check_audio_devices,
    #         devices.check_audio_card_management,
    #         devices.check_media_drives,
    #         devices.check_raid_tool
    #     ]
    #     run_validation_group(device_validation_functions, "Devices Validation")

    #     # Group of functions for d3 interaction validation
    #     d3_interaction_functions = [
    #         d3_interaction.check_d3_project,
    #         d3_interaction.check_d3_manager_help,
    #         d3_interaction.check_d3_licences,
    #         d3_interaction.check_OS_image_version
    #     ]
    #     run_validation_group(d3_interaction_functions, "d3 Interaction")
    
    


if __name__ == "__main__":
    main()

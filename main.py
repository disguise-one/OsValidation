
def gather_user_idenitifaction_of_run():
    ServerName = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the Server you are testing as it appears on the config file name (or for multi-machine config files, CodeMeterProductCodes -> d3Model):', 'Auto OS QA')"]).strip().decode('utf-8')
    OSVersion = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the OS version you are testing:', 'Auto OS QA')"]).strip().decode('utf-8')
    # description = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Do you want to add any optional description to your test run? Enter nothing if no:', 'Auto OS QA')"]).strip().decode('utf-8')
    return ServerName, OSVersion #, description


def run_validation_group(validation_functions, group_name, OSValidationDict, runRequrestResponse, client, GroupName):
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
            TestRunArray.append(function(OSValidationDict))
        # return TestRunArray
    except KeyboardInterrupt:
        logging.info("Keyboard Interrupt received, exiting the program.")
        sys.exit(0)
    except Exception as e:
        logging.exception(f"An unexpected error occurred when running function [{str(function.__name__)}]: {e}")

    # Upload the batch to testrail
    print("\033[1mEnd of " + str(GroupName) + ". Starting TestRail API calls to upload results. Please do not interrupt...\033[0m")
    failedUploads = useful_utilities.uploadTestBatchToTestRail(TestRunArray, runRequrestResponse, client)
    if(failedUploads):
        useful_utilities.printError("There may have been some failed uploads. Please check at the end for manual uploads of test results.")
    
    print("=====================================================================================")
    return failedUploads
        


def main(testRun, ServerName, OSVersion, testrailUsername, testrailPassword, OSValidationTemplatePath):
    """
    Main function to orchestrate various validation checks.

    This function is the entry point of the script. It first loads the configuration,
    then runs different groups of validation functions related to Windows settings,
    file handling, device checks, and d3 interaction.
    """

    # !!! ---- WHEN CHANGING FROM SANDBOX TESTRAIL TO LIVE TEST RAIL *ENSURE* YOU CHANGE THE TEST CODE ON EACH TEST FUNCTION ---- !!!
    
    # ===================== Config file creation ===================== #
    #   SECTION OPERATIONS:
    # In this section we go through the config file, ensuring it is there, and reading it

    print("==============================Starting main() function=================================")
    print("Loading OS Validation Config...")
    # Pull the JSON file.
    OSValidationConfigJson = useful_utilities.ImportOSValidationConfig()

    # sanity checks to ensure above has worked
    if(OSValidationConfigJson == None):
        useful_utilities.printError("Cannot access OSValidationConfig.json. This is necessary for the script to continue. Exiting.")
        input("Press Enter to continue...")
        exit()

    print("Success")

    print("Creating Parameter Dictionary")
    OSValidationDict = {
        "OSVersion": OSVersion,
        "ServerName": ServerName,
        "OSValidationTemplatePath" : OSValidationTemplatePath
    }

    # ===================== Interacting with Testrail API ===================== #

    # In this section we pull all the TestRail information, if the testRun field in OSCalidationConfig.json is filled out we pull that test run
    # else we set up a new test run 

    # The TestRail API uses python binding: https://support.testrail.com/hc/en-us/articles/7077135088660-Binding-Python#01G68HCTTNHFT1WVDXKW4BC4WP
    # Where you ab either get or post to the API, with a standard format filter to identify what you want to do
    # Eg send_get('get_runs/2&suite_id=6279') says get the runs of project 2 with suite id of 6279
    print("Setting up local TestRail API Client")
    client = testrail.APIClient(str(OSValidationConfigJson['testRailAPI']))
    client.user = str(testrailUsername)
    client.password = str(testrailPassword)

    projectNumber = OSValidationConfigJson["projectNumber"]
    suite_id = OSValidationConfigJson["suite_id"]
    print("Success")

    
    # Setting up the new run, if we want it to. Otherwise we get the existing run

    # if(testRun == -1):
    #     runAPIString = 'add_run/' + str(urllib.parse.quote_plus(str(OSValidationConfigJson["projectNumber"]))) + '&suite_id=' + str(urllib.parse.quote_plus(str(suite_id))) + '&name=' + str(urllib.parse.quote_plus(ServerName + '_' + OSVersion))
    # else:
    #     runAPIString = 'get_run/'+ str(urllib.parse.quote_plus(str(testRun))) + '&suite_id=' + str(urllib.parse.quote_plus(str(suite_id))) + '&project_id='+ str(urllib.parse.quote_plus(str(OSValidationConfigJson["projectNumber"])))
    
    if(testRun == -1):
        # runAPIString = 'add_run/' + str(OSValidationConfigJson["projectNumber"]) + '&suite_id=' +str(suite_id) + '&name=' + str(ServerName) + '_' + str(OSVersion)
        runAPIString = 'add_run/' + str(OSValidationConfigJson["projectNumber"])
    else:
        runAPIString = 'get_run/'+str(testRun) + '&suite_id=' + str(suite_id) + '&project_id='+ str(OSValidationConfigJson["projectNumber"])
    
    runRequrestResponse = -1

    

    try:
        # Send a requrest to the API to create a test run

        if(testRun == -1):
            print("Creating New TestRail test run")
            runRequrestResponse = client.send_post(runAPIString, {
            "suite_id": str(OSValidationConfigJson["suite_id"]),
            "name": str(ServerName + "_" + OSVersion + "_TESTING_NOT_REAL_RESULTS"),
            # "description": description,
            "include_all": True,
            })
        else:
            print("Getting previous test run with id [" + str(testRun) + "]")
            runRequrestResponse = client.send_get(runAPIString)
    except Exception as error:
        useful_utilities.printError("An error occured when trying to communicate with TestRail API: " + str(error))
        input("Failed getting/creating testrail API call. Exiting script. Press enter to exit...")
        exit()

    # Run the windows validation functions for startup and windows sections
    failedUploads = []
    windows_validation_functions = [
        windows_settings.check_taskbar_icons,
        windows_settings.check_start_menu_tiles,
        windows_settings.check_app_menu_contents,
        windows_settings.check_windows_licensing,
        windows_settings.check_chrome_history,
        windows_settings.check_chrome_homepage,
        windows_settings.check_chrome_bookmarks,
        windows_settings.check_machine_name,
        windows_settings.check_notifications_disabled,
        windows_settings.check_VFC_overlay,
        windows_settings.check_windows_update_disabled,
        windows_settings.check_firewall_disabled
    ]
    failedUploads += run_validation_group(windows_validation_functions, "Windows Settings", OSValidationDict, runRequrestResponse, client, "Windows Tests")

    devices_validation_functions = [
        device_testing.check_graphics_card_control_pannel,
        device_testing.check_matrox_capture_cards,
        device_testing.check_deltacast_capture_cards,
        device_testing.check_bluefish_capture_cards
    ]
    failedUploads += run_validation_group(devices_validation_functions, "Devices", OSValidationDict, runRequrestResponse, client, "Device Tests")

    if(failedUploads):
        print("==================================Failed Uploads=====================================")
        useful_utilities.printError("MANUAL UPLOAD REQUIRED...")
        print("There seems to be some test results that failed to upload to TestRail. Please do this manually, and/or report the bug that is stopping the upload.\n\n")
        print("Failed Uploads: ")
        for fail in failedUploads:
            print(fail)
            print()

        print("=====================================================================================")
    print()
    print("Finished Testing and Uploading.")


    


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
    print("+===============================================+")
    print("|                 OS Validation                 |")
    print("+===============================================+")
    print("\nImporting required modules...")
    # Check that the requiements are installed - Only run this on first run to ensure all modules are installed
    from utils import windows_settings, useful_utilities, device_testing
    from utils.logger import logging
    from utils import testrail
    import subprocess, json, re, base64, sys, select, urllib
    import numpy as np
    print("Success.\n")
    NumberOfArgsExludingExeName = 6
    needToExit = False

    try:
        print("Parsing Arguments...")

        if(len(sys.argv) > NumberOfArgsExludingExeName + 1):
            useful_utilities.printError("ERROR: Too many arguments passed into OSValidation Main script. Expected [5]. Received [" + str(len(sys.argv) - 1) + "]")
            input("Press enter to exit...")
            exit()
        elif (len(sys.argv) < NumberOfArgsExludingExeName):
            useful_utilities.printError("ERROR: Too few arguments passed into OSValidation Main script. Expected [5]. Received [" + str(len(sys.argv) - 1) + "]")
            input("Press enter to exit...")
            exit()

        testRun, osFamilyName, osBuildName, testrailUsername, testrailPassword, OSValidationTemplatePath = sys.argv[1:NumberOfArgsExludingExeName + 1]

        try:
            testRun = int(testRun)
        except Exception as error:
            input("Cannot convert [testRun] to int. Execption: " + str(error) + "\n\n Press enter to exit...")
            exit()

        try:
            testrailPassword = base64.b64decode(testrailPassword).decode('ascii')
        except Exception as error:
            input("Cannot decode [testrailPassword]. Execption: " + str(error) + "\n\n Press enter to exit...")
            exit()


        if((testRun or osFamilyName or osBuildName or testrailUsername or testrailPassword) == ""):
            useful_utilities.printError("All 5 arguments must be passed in. Exiting script")
            input("Press Enter to continue...")
            exit()
        
        print("Success.\n")
    
    except Exception as error:
        useful_utilities.printError("An error occured before main() could be executed: " + str(error))
        input("Exiting script. Press enter to exit...")
        exit()

    osFamilyName = osFamilyName.strip()
    osBuildName = osBuildName.strip()
    testrailUsername = testrailUsername.strip()
    testrailPassword = testrailPassword.strip()

    try:
        main(testRun, osFamilyName, osBuildName, testrailUsername, testrailPassword, OSValidationTemplatePath)
    except Exception as error:
        useful_utilities.printError("An error occured when running main(): " + str(error))
        input("Exiting script. Press enter to exit...")
        exit()
    input("Press Enter to exit...")
    exit()

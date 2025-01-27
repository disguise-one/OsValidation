
def gather_user_idenitifaction_of_run():
    ServerName = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the Server you are testing as it appears on the config file name (or for multi-machine config files, CodeMeterProductCodes -> d3Model):', 'Auto OS QA')"]).strip().decode('utf-8')
    TestRunTitle = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Please enter the OS version you are testing:', 'Auto OS QA')"]).strip().decode('utf-8')
    # description = subprocess.check_output(['powershell', "[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); return [Microsoft.VisualBasic.Interaction]::InputBox('Do you want to add any optional description to your test run? Enter nothing if no:', 'Auto OS QA')"]).strip().decode('utf-8')
    return ServerName, TestRunTitle #, description


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
    print()
    logging.info(f"--- Running Test Group {group_name} ---")
    for function in validation_functions:
        try:
            print()
            TestRunArray.append(function(OSValidationDict))
            if(TestRunArray[len(TestRunArray)-1].get_testImagePathArr() != ''):
                print(str(TestRunArray[len(TestRunArray)-1].get_testImagePathArr()))
        except KeyboardInterrupt:
            logging.info("Keyboard Interrupt received, exiting the program.")
            exit()
        except Exception as e:
            logging.exception(f"An unexpected error occurred when running function [{str(function.__name__)}]: {e}")

    # Upload the batch to testrail
    logging.info("\033[1mEnd of " + str(GroupName) + ". Starting TestRail API calls to upload results. Please do not interrupt...\033[0m")
    failedUploads = useful_utilities.uploadTestBatchToTestRail(TestRunArray, runRequrestResponse, client)
    if(failedUploads):
        logging.error("There may have been some failed uploads. Please check at the end for manual uploads of test results.")
    
    logging.info("=====================================================================================")
    return failedUploads
        


def main(testRun, TestRunTitle, testrailUsername, testrailPassword, OSValidationTemplatePath, TestType, afterInternalRestore):
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
    print()
    logging.info("==============================Starting main() function=================================")
    print()
    logging.info("Loading OS Validation Config...")
    # Pull the JSON file.
    OSValidationConfigJson = useful_utilities.ImportOSValidationConfig()

    # sanity checks to ensure above has worked
    if(OSValidationConfigJson == None):
        logging.error("Cannot access OSValidationConfig.json. This is necessary for the script to continue. Exiting.")
        input("Press Enter to continue...")
        exit()

    logging.info("Success")

    logging.info("Creating Parameter Dictionary")
    OSValidationDict = {
        "TestRunTitle": TestRunTitle,
        "OSValidationTemplatePath" : OSValidationTemplatePath,
        "TestType" : TestType,
        "AfterInternalRestore" : afterInternalRestore
    }

    # ===================== Interacting with Testrail API ===================== #

    # In this section we pull all the TestRail information, if the testRun field in OSCalidationConfig.json is filled out we pull that test run
    # else we set up a new test run 

    # The TestRail API uses python binding: https://support.testrail.com/hc/en-us/articles/7077135088660-Binding-Python#01G68HCTTNHFT1WVDXKW4BC4WP
    # Where you ab either get or post to the API, with a standard format filter to identify what you want to do
    # Eg send_get('get_runs/2&suite_id=6279') says get the runs of project 2 with suite id of 6279
    print()
    logging.info("Setting up local TestRail API Client")
    apiRootURL = OSValidationConfigJson['testRailAPI']
    if( not apiRootURL ):
        logging.error("Could not retrieve the setting [testRailAPI] from OSValidationConfig.Json")
        input("Could not retrieve the setting [testRailAPI] from OSValidationConfig.Json. Press enter to exit...")
        exit()
    client = testrail.APIClient(str(apiRootURL))
    client.user = str(testrailUsername)
    client.password = str(testrailPassword)
    projectNumber = OSValidationConfigJson["projectNumber"]
    if( not projectNumber ):
        logging.error("Could not retrieve the setting [projectNumber] from OSValidationConfig.Json")
        input("Could not retrieve the setting [projectNumber] from OSValidationConfig.Json. Press enter to exit...")
        exit()
    suite_id = OSValidationConfigJson["suite_id_"+TestType]
    if( not suite_id ):
        logging.error("Could not retrieve the setting ["+"suite_id_"+TestType+"] from OSValidationConfig.Json")
        input("Could not retrieve the setting ["+"suite_id_"+TestType+"] from OSValidationConfig.Json. Press enter to exit...")
        exit()
    logging.info("TestRail API URL: " + str(apiRootURL))
    logging.info("TestRail Project Number: " + str(projectNumber))
    logging.info("TestRail Suite ID: " + str(suite_id))
    logging.info("Success")

    # Setting up the new run, if we want it to. Otherwise we get the existing run
    runRequrestResponse = -1
    try:
        # Send a requrest to the API to create a test run

        if(testRun == -1):
            
            runAPIString = 'add_run/' + str( projectNumber )
            print()
            logging.info("Creating New Test Run in TestRail")
            runRequrestResponse = client.send_post(runAPIString, {
            "suite_id": suite_id,
            "name": str(TestRunTitle),
            # "description": description,
            "include_all": True,
            })
            logging.info("Created Test Run [" + str( runRequrestResponse["id"] ) + "] Successfully")
        else:
            runAPIString = 'get_run/'+str(testRun) + '&suite_id=' + str(suite_id) + '&project_id='+ str( projectNumber )
            print()
            logging.info("Retrieving Test Run [" + str(testRun) + "] from TestRail")
            runRequrestResponse = client.send_get(runAPIString)
            logging.info("Retrieved Test Run [" + str( runRequrestResponse["id"] ) + "] Successfully")
    except Exception as error:
        logging.error("An error occured when trying to communicate with TestRail API: " + str(error))
        input("Failed getting/creating testrail API call. Exiting script. Press enter to exit...")
        
        exit()

    # Run the windows validation functions for startup and windows sections
    failedUploads = []
    if TestType == "WIM":
        windows_validation_functions = [
            windows_settings.check_taskbar_icons,
            windows_settings.check_start_menu_tiles,
            windows_settings.check_app_menu_contents,
            windows_settings.check_windows_licensing,
            windows_settings.check_chrome_history,
            windows_settings.check_chrome_homepage,
            windows_settings.check_chrome_bookmarks,
            windows_settings.check_notifications_disabled,
            windows_settings.check_VFC_overlay,
            windows_settings.check_windows_update_disabled,
            windows_settings.check_firewall_disabled,
            windows_settings.check_installed_app_versions
        ]
        failedUploads += run_validation_group(windows_validation_functions, "Windows Settings", OSValidationDict, runRequrestResponse, client, "Windows Tests")

        devices_validation_functions = [
            device_testing.check_graphics_card_control_pannel,
            device_testing.check_matrox_capture_cards,
            device_testing.check_deltacast_capture_cards,
            device_testing.check_bluefish_capture_cards,
            device_testing.check_audio_cards,
            device_testing.check_device_manager_driver_versions
        ]
        failedUploads += run_validation_group(devices_validation_functions, "Devices", OSValidationDict, runRequrestResponse, client, "Device Tests")

    elif TestType == "USB" or "R20":
        general_iso_functions = [
            general_ISO_Tests.check_projects_reg_paths,
            general_ISO_Tests.check_machine_name,
            general_ISO_Tests.check_logs_present_local,
            general_ISO_Tests.check_logs_present_remote,
            general_ISO_Tests.check_net_adapter_names,
            general_ISO_Tests.check_audio_cards,
            general_ISO_Tests.check_D_drive
        ]
        failedUploads += run_validation_group(general_iso_functions, "ISO Tests", OSValidationDict, runRequrestResponse, client, "ISO Tests")

    
    if(failedUploads):
        logging.info("==================================Failed Uploads=====================================")
        logging.info("MANUAL UPLOAD REQUIRED...")
        logging.info("There seems to be some test results that failed to upload to TestRail. Please do this manually, and/or report the bug that is stopping the upload.\n\n")
        logging.info("Failed Uploads: ")
        for fail in failedUploads:
            logging.info(fail)
            logging.info('\n')

        logging.info("=====================================================================================")
    logging.info("\n")
    logging.info("Finished Testing and Uploading.")
    logging.info(f"YOUR TEST RAIL TEST RUN ID IS: {str(runRequrestResponse["id"])}")


    


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
    #     windowsTests = run_validation_group(windows_validation_functions, "Windows Settings", TestRunTitle)

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
    try:
        from utils.logger import logging, bespokeLogging
        # from utils.logger import logger
        from utils import testrail
        import subprocess, json, re, base64, sys, select, urllib, time
        import numpy as np
        from utils import windows_settings, useful_utilities, device_testing, general_ISO_Tests
    except Exception as error:
        print("Error Importing dependancies. Error: " + str(error))
        input("Press Enter to exit...")
        exit()

    try:
        logs = bespokeLogging("C:\\Windows\\Logs", "OSValidationTempLog.log")
    except Exception as error:
        print("Error creating logging object. Error: " + str(error))
        input("Press Enter to exit...")
        exit()
    
    logging.info("Starting logs...")
    logging.info("Success Importing Modules.")
    NumberOfArgsExludingExeName = 7
    needToExit = False

    try:
        print()
        logging.info("Parsing Arguments...")

        if(len(sys.argv) > NumberOfArgsExludingExeName + 1):
            logging.error("ERROR: Too many arguments passed into OSValidation Main script. Expected [5]. Received [" + str(len(sys.argv) - 1) + "]")
            input("Press enter to exit...")
            exit()
        elif (len(sys.argv) < NumberOfArgsExludingExeName):
            logging.error("ERROR: Too few arguments passed into OSValidation Main script. Expected [5]. Received [" + str(len(sys.argv) - 1) + "]")
            input("Press enter to exit...")
            exit()

        testRun, testRunTitle, testrailUsername, testrailPassword, OSValidationTemplatePath, TestType, afterInternalRestore_string = sys.argv[1:NumberOfArgsExludingExeName + 1]

        try:
            testRun = int(testRun)
        except Exception as error:
            logging.error("Cannot convert [testRun] to int. Execption: " + str(error))
            input("Press enter to exit...")
            exit()

        try:
            testrailPassword = base64.b64decode(testrailPassword).decode('ascii')
        except Exception as error:
            logging.error("Cannot decode [testrailPassword]. Execption: " + str(error))
            input("\n\n Press enter to exit...")
            exit()

        try:
            afterInternalRestore = ( afterInternalRestore_string == 'True' )
        except Exception as error:
            logging.error("Cannot decode [afterInternalRestore]. Execption: " + str(error))
            input("\n\n Press enter to exit...")
            exit()

        # NEEDS SOME LOVE \/
        if((testRun or testRunTitle or testrailUsername or testrailPassword or afterInternalRestore_string) == ""):
            logging.error("All 6 arguments must be passed in. Exiting script")
            input("Press Enter to continue...")
            exit()

        logging.info("Success.\n")
    
    except Exception as error:
        logging.error("An error occured before main() could be executed: " + str(error))
        input("Exiting script. Press enter to exit...")
        exit()

    testRunTitle = testRunTitle.strip()
    timestr = time.strftime("%Y%m%d-%H%M%S")

    try:
        logs.change_log_path(f"C:\\Windows\\Logs\\{testRunTitle}{timestr}.log")
    except Exception as error:
        logging.error(f"Something went wrong changing log directory: [{error}]")
        

    testrailUsername = testrailUsername.strip()
    testrailPassword = testrailPassword.strip()

    print()
    logging.info(f"Test Type detected as: [{TestType}]")

    try:
        main(testRun, testRunTitle, testrailUsername, testrailPassword, OSValidationTemplatePath, TestType, afterInternalRestore )
    except Exception as error:
        logging.error("An error occured when running main(): " + str(error))
        input("Exiting script. Press enter to exit...")
    finally:
        logging.info("Uploading logs to testrail...")
        logContent = logger.read_log_file()
    input("Press Enter to exit...")
    exit()

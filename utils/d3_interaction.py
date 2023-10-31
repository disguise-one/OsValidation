import os
import subprocess
from pywinauto.application import Application
import time


def check_d3_projects():
    folder_path = "D:\\d3 Projects"

    if os.path.exists(folder_path) and os.path.isdir(folder_path):
        print("| C62865 | d3 Projects check passed: 'd3 Projects' folder exists on D: drive.")
    else:
        print("| C62865 | d3 Projects check failed: 'd3 Projects' folder not found on D: drive.")


def check_d3_manager_tests():
    # Initialize the d3 manager path
    d3_manager_path = "C:\\Program Files\\d3 Production Suite\\build\\msvc\\d3manager.exe"

    # Launch d3 manager
    print("| INFO | Launching d3 manager, please wait...")
    subprocess.Popen(d3_manager_path)
    time.sleep(10)  # Delay to ensure the application window is fully initialized

    # Connect to the d3manager application using pywinauto
    app = Application(backend="uia").connect(path=d3_manager_path)
    main_win = app.window(class_name="D3Manager")

    # Expand the Help menu
    help_menu = main_win.child_window(title="Help", control_type="MenuItem")
    help_menu.click_input()

    # Wait a bit for the submenu to appear
    time.sleep(5)

    # Check d3 manager help
    print("| C62864 | Checking for the d3 manager help...")
    d3manager_help = main_win.child_window(auto_id="D3ManagerClass.actionHelp", control_type="MenuItem")
    d3manager_help.click_input()
    response = input("| C62864 | Did the d3 manager help open? (Y/N) ")
    print("| C62864 | d3 Manager help check " + ("passed." if response.upper() == 'Y' else "failed."))

    # Refocus on the main window and expand the Help menu again
    main_win.set_focus()
    help_menu.click_input()
    time.sleep(5)

    # Check d3 licenses
    print("| C62865 | Checking for the d3 licences...")
    for _ in range(3):  # Try 3 times
        try:
            d3_licenses = main_win.child_window(auto_id="D3ManagerClass.actionLicense", control_type="MenuItem")
            d3_licenses.wait('visible', timeout=10)
            d3_licenses.click_input()
            break
        except Exception as e:
            print(f"| ERROR | Retry accessing d3 Licenses due to: {str(e)}")
    else:
        print("| ERROR | Failed to access d3 Licenses after multiple attempts.")
        return

    # Ask the user if the d3 licences window opened and the licence was found
    response = input("| C62865 | Did the d3 licences window open, and the licence was found? (Y/N) ")
    if response.upper() == 'Y':
        print("| C62865 | d3 licences check passed.")
    else:
        print("| C62865 | d3 licences check failed.")

    # Refocus on the main window and expand the Help menu again
    main_win.set_focus()
    help_menu.click_input()
    time.sleep(5)

    # Check OS image version
    print("| C62865 | Checking for the OS image version...")
    about_d3manager = main_win.child_window(auto_id="D3ManagerClass.actionAbout", control_type="MenuItem")
    about_d3manager.click_input()
    response = input("| C62864 | Did the About d3 manager window open, and the OS image Version was found? (Y/N) ")
    print("| C62864 | Machine OS image version check " + ("passed." if response.upper() == 'Y' else "failed."))

    # Close the d3 manager
    print("| INFO | Closing d3 manager...")
    close_button = main_win.child_window(title="Close", control_type="Button")
    close_button.click()

import time
import pyautogui
import subprocess


def check_d3_project():
    print("| C62863 | Checking for the d3 Project folder, please wait...")
    time.sleep(2)
    d3_manager_path = "C:\\Program Files\\d3 Production Suite\\build\\msvc\\d3manager.exe"
    subprocess.Popen(d3_manager_path)

    while True:
        input_str = input("| C62863 | Is d3 Project available on the D drive? (Y/N): ")
        if input_str.lower() == 'y':
            print("| C62863 | d3 Project check passed")
            break
        elif input_str.lower() == 'n':
            print("| C62863 | d3 Project check failed")
            break
        else:
            print("| C62863 | Invalid input. Please enter 'y' or 'n'.")


def check_d3_manager_help():
    print("| C62864 | Checking for the d3 manager help, please wait...")
    time.sleep(2)
    d3_manager_path = "C:\\Program Files\\d3 Production Suite\\build\\msvc\\d3manager.exe"
    subprocess.Popen(d3_manager_path)

    time.sleep(5)
    # click the 'x' button to close any existing instances of the d3 manager help
    pyautogui.click(x=876, y=130, duration=0.5)
    time.sleep(5)
    # open the d3 manager help
    pyautogui.click(x=963, y=159, duration=0.5)
    time.sleep(2)  # wait for the help to open

    # ask the user if the d3 manager help opened
    response = input("| C62864 | Did the d3 manager help open? (Y/N) ")
    if response.upper() == 'Y':
        print("| C62864 | d3 Manager help check passed.")
    else:
        print("| C62864 | d3 Manager help check failed.")


def check_d3_licences():
    print("| C62865 | Checking for the d3 licences, please wait...")
    time.sleep(2)
    d3_manager_path = "C:\\Program Files\\d3 Production Suite\\build\\msvc\\d3manager.exe"
    subprocess.Popen(d3_manager_path)

    time.sleep(5)
    # click the 'x' button to close any existing instances of the d3 manager help
    pyautogui.click(x=876, y=130, duration=0.5)
    time.sleep(5)
    # open the d3 manager help
    pyautogui.click(x=932, y=381, duration=0.5)
    time.sleep(2)  # wait for the help to open

    # ask the user if the d3 manager help opened
    response = input("| C62865 | Did the d3 licences window open, and the licence was found? (Y/N) ")
    if response.upper() == 'Y':
        print("| C62865 | d3 licences check passed.")
    else:
        print("| C62865 | d3 licences check failed.")


def check_OS_image_version():
    print("| C62865 | Checking for the OS image version, please wait...")
    time.sleep(2)
    d3_manager_path = "C:\\Program Files\\d3 Production Suite\\build\\msvc\\d3manager.exe"
    subprocess.Popen(d3_manager_path)

    time.sleep(5)
    # click the 'x' button to close any existing instances of the d3 manager help
    pyautogui.click(x=876, y=130, duration=0.5)
    time.sleep(5)
    # open the d3 manager help
    pyautogui.click(x=918, y=475, duration=0.5)
    time.sleep(2)  # wait for the help to open

    # ask the user if the d3 manager help opened
    response = input("| C62864 | Did the About d3 manager window open, and the OS image Version was found? (Y/N) ")
    if response.upper() == 'Y':
        print("| C62864 | Machine OS image version check passed.")
    else:
        print("| C62864 | Machine OS image version check failed.")

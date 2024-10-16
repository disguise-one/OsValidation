import subprocess
import winreg
import yaml
from utils.test_case_classes import TestCase

# Some of these return only true or false. I need to switch them over to returning the status codes of testrail ascan be found in the test_case_classes class


def check_taskbar_icons(OSVersion, ComputerName):
    authorized_taskbar_icons = ["Explorer", "Chrome"]

    # Check taskbar icons
    taskbar_icons = subprocess.check_output(['powershell', 'Get-ChildItem -Path "$env:APPDATA\\Microsoft\\Internet Explorer\\Quick Launch\\User Pinned\\TaskBar" | Select-Object -ExpandProperty Name']).strip().decode('utf-8')

    taskbar_icons_list = taskbar_icons.split("\r\n")

    unauthorized_icons = [icon for icon in taskbar_icons_list if icon not in authorized_taskbar_icons]

    # Create the test case
    taskbarTestCase = TestCase("374768", "Taskbar Icons", "Untested")
    if len(unauthorized_icons) == 0:
        taskbarTestCase.set_testResult("PASSED")
    else:
        authorized_icons = [icon for icon in taskbar_icons_list if icon in authorized_taskbar_icons]
        taskbarTestCase.set_testResult("FAILED")

    taskbarTestCase.printFormattedResults
    return taskbarTestCase


def check_start_menu_tiles(OSVersion, ComputerName):
    authorized_programs = ["Chrome", "d3manager", "Media Player Classic", "Recycle Bin"]

    # Check start menu tiles
    start_menu_tiles = subprocess.check_output(['powershell', 'Get-ChildItem -Path "$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs" -Recurse | Where-Object {$_.Extension -eq ".lnk"} | Select-Object -ExpandProperty Name']).strip().decode('utf-8')

    # Collect the evidence
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-StartMenuEvidence -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    try:
        StartMenuContents = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        StartMenuContents = "Exception"
    
    start_menu_tiles_list = start_menu_tiles.split("\r\n")

    unauthorized_programs = [program for program in start_menu_tiles_list if program not in authorized_programs]

    taskbarTestCase = TestCase("374769", "Start Menu Icons", "Untested")

    if len(unauthorized_programs) == 0:
        taskbarTestCase.set_testResult("PASSED")
    else:
        taskbarTestCase.set_testResult("FAILED")

    taskbarTestCase.printFormattedResults()

    return taskbarTestCase

def check_app_menu_contents(OSVersion, ComputerName):
    # Approbved apps are: Paint, Snipping Tool, Steps Recorder, Notepad, Wordpad, Character Map, Remote Desktop Connection, Math input
    # Needs to find calculator
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsAppMenuContents -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    AppMenuTestCase = TestCase("374770", "App Menu Contents", "Untested")
    try:
        AppMenuContents = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        AppMenuContents = "Exception"

    if('False' in AppMenuContents):
        AppMenuTestCase.set_testResult("FAILED")
        # Need to find which apps failed

        AppMenuContents = AppMenuContents.split('\r\n')
        # first open the config, brows to windows allowed apps

        with open("config\\config.yaml") as stream:
            try:
                config = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc)

        # loop through the AppMenuContents and find the index of each false in the results
        failed_apps = []
        failed_app_message = ""
        for index in range(len(config["windows_settings"]["windows_allowed_apps"])):
            # find the app matching that index
            if(AppMenuContents[index] == 'False'):
                # add to a list of failed apps
                failed_apps.append(config["windows_settings"]["windows_allowed_apps"][index])
                if len(failed_apps) == 1:
                    failed_app_message = "Missing Apps: " + config["windows_settings"]["windows_allowed_apps"][index]
                else:
                    failed_app_message += ", " + config["windows_settings"]["windows_allowed_apps"][index]

        # call the set_testResultMessage method of the testCase class and store the failed apps
        AppMenuTestCase.set_testResultMessage(failed_app_message)
    elif(AppMenuContents == "Exception"):
        AppMenuTestCase.set_testResult("FAILED")
    else:
        AppMenuTestCase.set_testResult("PASSED")

    AppMenuTestCase.printFormattedResults()
        
    return AppMenuTestCase


def check_windows_licensing(OSVersion, ComputerName):
    # Check licensing status
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-WindowsLicensingAndEvidence -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    # Create the test suite
    licenseTestCase = TestCase("374728", "Windows License", "Untested")
    # , stdout=subprocess.PIPE
    lisenceActivated = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')

    if lisenceActivated == "True":
        licenseTestCase.set_testResult("PASSED")
    else:
        licenseTestCase.set_testResult("FAILED")

    licenseTestCase.printFormattedResults()
    
    return licenseTestCase

def check_chrome_history(OSVersion, ComputerName):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeHistory -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    # Create the test suite
    chromeHistoryTestCase = TestCase("374722", "Chrome History", "Untested")
    # , stdout=subprocess.PIPE
    chromeHistory = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')

    if chromeHistory == "True":
        chromeHistoryTestCase.set_testResult("PASSED")
    else:
        chromeHistoryTestCase.set_testResult("FAILED")

    chromeHistoryTestCase.printFormattedResults()
    
    return chromeHistoryTestCase

def check_chrome_bookmarks(OSVersion, ComputerName):
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeBookmarks -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    # Create the test suite
    chromeBookmarksTestCase = TestCase("401173", "Chrome Bookmarks", "Untested")
    # , stdout=subprocess.PIPE
    chromeBookmarks = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    if(chromeBookmarks == "True"):
        chromeBookmarksTestCase.set_testResult("PASSED")
    else:
        chromeBookmarksTestCase.set_testResult("FAILED")
        chromeBookmarksTestCase.set_testResultMessage(chromeBookmarks)
    
    chromeBookmarksTestCase.printFormattedResults()

    return chromeBookmarksTestCase


def check_chrome_homepage(OSVersion, ComputerName):
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeHomepage -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName

    # Create the test suite
    chromeHomepageTestCase = TestCase("401174", "Chrome Homepage", "Untested")
    # , stdout=subprocess.PIPE
    chromeHomepageResults = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    if(chromeHomepageResults == "True"):
        chromeHomepageTestCase.set_testResult("PASSED")
    else:
        chromeHomepageTestCase.set_testResult("FAILED")
        chromeHomepageTestCase.set_testResultMessage(chromeHomepageResults)
    
    chromeHomepageTestCase.printFormattedResults()

    return chromeHomepageTestCase

# This doesnt seem to correctly ID the color. In the OS e change something that overwrites the REGISTRY, not replacing the values on it, so this check doesnt check the right thing
def check_windows_background_color(OSVersion, ComputerName):
    # Check background color
    background_color = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\\Control Panel\\Colors" -Name "Background" | Select-Object -ExpandProperty Background']).strip().decode('utf-8')

    if background_color == "58 58 58":
        print("| C62836 | Windows background color: PASSED")
    else:
        print("| C62836 | Windows background color: FAILED")


# Need to find a way to verify the name is correct
def check_machine_name(OSVersion, ComputerName):

    # Create the test class
    machineNameTestCase = TestCase("374727", "Machine Name", "UNTESTED")

    # Check machine name
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-MachineName -OSVersion " + OSVersion + " -userInputMachineName " + ComputerName
    machine_name_return_status = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    machineNameTestCase.set_testResult(machine_name_return_status)
    machineNameTestCase.printFormattedResults()

    return machineNameTestCase


def check_notifications_disabled(OSVersion, ComputerName):

    notificationTestCase = TestCase("374729", "Machine Name", "UNTESTED")

    try:
        notifications_disabled = subprocess.check_output(['powershell', 'Get-ItemPropertyValue -Path "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PushNotifications" -Name "NoToastApplicationNotification"']).strip().decode('utf-8')
    except subprocess.CalledProcessError:
        notificationTestCase.set_testResult("FAILED")
        return notificationTestCase

    if notifications_disabled == "1":
        notificationTestCase.set_testResult("PASSED")
    else:
        notificationTestCase.set_testResult("FAILED")
    
    notificationTestCase.printFormattedResults()
    return notificationTestCase


def check_windows_update_disabled(OSVersion, ComputerName):
    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU') as key:
        try:
            value, _ = winreg.QueryValueEx(key, 'NoAutoUpdate')
            if value == 1:
                print("| C62839 | Windows Update: DISABLED")
            else:
                print("| C62839 | Windows Update: ENABLED")
        except OSError:
            print("| C62839 | Windows Update: ENABLED")


def check_sticky_keys_disabled(OSVersion):
    sticky_keys_disabled = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\\Control Panel\\Accessibility\\StickyKeys" | Select-Object -ExpandProperty Flags']).strip().decode('utf-8')
    if '0' in sticky_keys_disabled:
        print("| C62840 | Sticky keys: DISABLED")
    else:
        print("| C62840 | Sticky keys: NOT DISABLED")


def check_windows_firewall_disabled(OSVersion):
    firewall_status = subprocess.check_output(['powershell', 'Get-NetFirewallProfile -All | Select-Object -Property Name, Enabled']).strip().decode('utf-8')
    if 'False' in firewall_status:
        print("| C73261 | Windows Firewall: DISABLED")
    else:
        print("| C73261 | Windows Firewall: NOT DISABLED")

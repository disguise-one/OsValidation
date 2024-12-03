import subprocess
import winreg
import yaml
from utils.test_case_classes import TestCase

# Some of these return only true or false. I need to switch them over to returning the status codes of testrail ascan be found in the test_case_classes class


def check_taskbar_icons(OSValidationDict):
    OSVersion = OSValidationDict["OSVersion"]
    ComputerName = OSValidationDict["ServerName"]
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsTaskbarContents -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

    taskbarTestCase = TestCase("374768", "Taskbar Contents", "Untested")
    try:
        TaskBarContents = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        TaskBarContents = "Exception"

    if(TaskBarContents == "True"):
        taskbarTestCase.set_testResult("PASSED")
    else:
        taskbarTestCase.set_testResult("PASSED")
        message = "Missing Task Bar Apps: " + str(TaskBarContents)
        print(message)
        taskbarTestCase.set_testResultMessage(message)

    taskbarTestCase.printFormattedResults()
    return taskbarTestCase


# To do: Make a function in POWERSHELL module that will take the model configs and identify which apps should be installed
def check_start_menu_tiles(OSValidationDict):

    # Create the powershell command
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsStartMenuContents -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

    # Execute it
    try:
        StartMenuContents = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        StartMenuContents = "Exception"

    startMenuTestCase = TestCase("374769", "Start Menu Icons", "Untested")

    if StartMenuContents == "PASSED":
        startMenuTestCase.set_testResult(StartMenuContents)
        startMenuTestCase.set_testResultMessage("All default apps installed.")
    else:
        startMenuTestCase.set_testResult("FAILED")
        startMenuTestCase.set_testResultMessage("Missing Apps: " + str(StartMenuContents))

    startMenuTestCase.printFormattedResults()
    return startMenuTestCase




def check_app_menu_contents(OSValidationDict):
    # Approbved apps are: Paint, Snipping Tool, Steps Recorder, Notepad, Wordpad, Character Map, Remote Desktop Connection, Math input
    # Needs to find calculator
    
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsAppMenuContents -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

    AppMenuTestCase = TestCase("374770", "App Menu Contents", "Untested")
    try:
        AppMenuContents = subprocess.check_output(['powershell', powershellComand]).strip().decode('utf-8')
    except:
        AppMenuContents = "Exception"

    Message = "Manual Check Required: Please ensure Snipping Tool is installed. "

    if(AppMenuContents == "BLOCKED"):
        AppMenuTestCase.set_testResult(AppMenuContents)
        AppMenuTestCase.set_testResultMessage(Message)
    else:
        AppMenuTestCase.set_testResult("FAILED")
        AppMenuTestCase.set_testResultMessage(Message + " Additionally, these apps are not installed: " + str(AppMenuContents))

    AppMenuTestCase.printFormattedResults()
        
    return AppMenuTestCase


def check_windows_licensing(OSValidationDict):
    # Check licensing status
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-WindowsLicensingAndEvidence -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

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

def check_chrome_history(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeHistory -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

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

def check_chrome_bookmarks(OSValidationDict):
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeBookmarks -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

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


def check_chrome_homepage(OSValidationDict):
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeHomepage -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]

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
def check_windows_background_color(OSValidationDict):
    # Check background color
    background_color = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\\Control Panel\\Colors" -Name "Background" | Select-Object -ExpandProperty Background']).strip().decode('utf-8')

    if background_color == "58 58 58":
        print("| C62836 | Windows background color: PASSED")
    else:
        print("| C62836 | Windows background color: FAILED")


# Need to find a way to verify the name is correct
def check_machine_name(OSValidationDict):

    # Create the test class
    machineNameTestCase = TestCase("374727", "Machine Name", "UNTESTED")

    # Check machine name
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-MachineName -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]
    machine_name_return_status = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    machineNameTestCase.set_testResult(machine_name_return_status)
    machineNameTestCase.printFormattedResults()

    return machineNameTestCase


def check_notifications_disabled(OSValidationDict):

    notificationTestCase = TestCase("374729", "Notifications Disabled", "UNTESTED")

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


def check_windows_update_disabled(OSValidationDict):
    # Setup the test case
    windowsUpdateTestCase = TestCase("374730", "Update Disabled", "UNTESTED")

    # Check if windows updates are enabled
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-WindowsUpdateEnabled -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]
    windowsUpdateTestStatus = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    windowsUpdateTestCase.set_testResult(windowsUpdateTestStatus)
    windowsUpdateTestCase.printFormattedResults()

    return windowsUpdateTestCase


def check_VFC_overlay(OSValidationDict):
    # Setup the test case
    VFCOverlayTestCase = TestCase("374734", "VFC Overlay", "UNTESTED")

    # Check if windows updates are enabled
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-VFCOverlay -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]
    VFCOverlayTestStatus = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    VFCOverlayTestCase.set_testResult(VFCOverlayTestStatus)
    VFCOverlayTestCase.printFormattedResults()

    return VFCOverlayTestCase


def check_firewall_disabled(OSValidationDict):
    # Setup the test case
    firewallTestCase = TestCase("374731", "Windows Firewall Disabled", "UNTESTED")

    # Check if firewall is disabled
    powershellCommand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-WindowsFirewallDisabled -OSVersion " + OSValidationDict["OSVersion"] + " -userInputMachineName " + OSValidationDict["ServerName"]
    firewallStatus = subprocess.check_output(['powershell', powershellCommand]).strip().decode('utf-8')

    if(firewallStatus == "PASSED"):
        firewallTestCase.set_testResult(firewallStatus)
    else:
        firewallTestCase.set_testResult("FAILED")
        firewallTestCase.set_testResultMessage(firewallStatus)

    firewallTestCase.printFormattedResults()

    return firewallTestCase



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

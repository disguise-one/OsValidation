import subprocess
import winreg
import yaml
from utils.test_case_classes import TestCase
from utils import useful_utilities

# Some of these return only true or false. I need to switch them over to returning the status codes of testrail ascan be found in the test_case_classes class

def check_taskbar_icons(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsTaskbarContents -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    taskbarTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374768", "Taskbar Contents")
    return taskbarTestCase

# To do: Make a function in POWERSHELL module that will take the model configs and identify which apps should be installed
def check_start_menu_tiles(OSValidationDict):
    # Create the powershell command
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsStartMenuContents -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    # Execute it, and store the resultant test case
    StartMenuTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374769", "Start Menu Icons")
    return StartMenuTestCase

def check_app_menu_contents(OSValidationDict):
    # Approbved apps are: Paint, Snipping Tool, Steps Recorder, Notepad, Wordpad, Character Map, Remote Desktop Connection, Math input
    # Needs to find calculator
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-AndTestWindowsAppMenuContents -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    AppMenuTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374770", "App Menu Contents")
    return AppMenuTestCase

def check_windows_licensing(OSValidationDict):
    # Check licensing status
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-WindowsLicensingAndEvidence -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    licenseTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374728", "Windows License")
    return licenseTestCase

def check_chrome_history(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeHistory -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    chromeHistoryTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374722", "Chrome History")
    return chromeHistoryTestCase

def check_chrome_bookmarks(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeBookmarks -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    chromeBookmarksTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "401173", "Chrome Bookmarks")
    return chromeBookmarksTestCase

def check_chrome_homepage(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-ChromeHomepage -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    chromeHomepageTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "401174", "Chrome Homepage")
    return chromeHomepageTestCase

def check_notifications_disabled(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-NotificationsDisabled -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    notificationTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374729", "Notifications Disabled")
    return notificationTestCase

def check_windows_update_disabled(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-WindowsUpdateEnabled -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" )+ "\""
    windowsUpdateTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374730", "Update Disabled")
    return windowsUpdateTestCase

def check_VFC_overlay(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Get-VFCOverlay -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    VFCOverlayTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374734", "VFC Overlay")
    return VFCOverlayTestCase

def check_firewall_disabled(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-WindowsFirewallDisabled -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    firewallTestCase = useful_utilities.RunPowershellAndParseOutput(powershellComand, "374731", "Windows Firewall Disabled")
    return firewallTestCase

def check_installed_app_versions(OSValidationDict):
    powershellComand = "import-Module .\\utils\\powershell\\disguiseWindowsSettingsQA -Force -DisableNameChecking; Test-InstalledAppAndFeatureVersions -TestRunTitle \"" + OSValidationDict["TestRunTitle"].replace("`", "``" ).replace( "\"", "`\"" ) + "\" -pathToOSValidationTemplate \"" + OSValidationDict["OSValidationTemplatePath"].replace("`", "``" ).replace( "\"", "`\"" ) + "\""
    return useful_utilities.RunPowershellAndParseOutput(powershellComand, "795477", "Installed Apps and Features Version Check")


#===================================================================================
# LEGACY CODE. This is depreciated but may be useful in the future? so I wont delete it but it has now been removed
#===================================================================================

# Legacy code:
# def check_sticky_keys_disabled(TestRunTitle):
#     sticky_keys_disabled = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\\Control Panel\\Accessibility\\StickyKeys" | Select-Object -ExpandProperty Flags']).strip().decode('utf-8')
#     if '0' in sticky_keys_disabled:
#         print("| C62840 | Sticky keys: DISABLED")
#     else:
#         print("| C62840 | Sticky keys: NOT DISABLED")


# def check_windows_firewall_disabled(TestRunTitle):
#     firewall_status = subprocess.check_output(['powershell', 'Get-NetFirewallProfile -All | Select-Object -Property Name, Enabled']).strip().decode('utf-8')
#     if 'False' in firewall_status:
#         print("| C73261 | Windows Firewall: DISABLED")
#     else:
#         print("| C73261 | Windows Firewall: NOT DISABLED")

# This doesnt seem to correctly ID the color. In the OS we change something that overwrites the REGISTRY, not replacing the values on it, so this check doesnt check the right thing
# Legacy:
# def check_windows_background_color(OSValidationDict):
#     # Check background color
#     background_color = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\\Control Panel\\Colors" -Name "Background" | Select-Object -ExpandProperty Background']).strip().decode('utf-8')

#     if background_color == "58 58 58":
#         print("| C62836 | Windows background color: PASSED")
#     else:
#         print("| C62836 | Windows background color: FAILED")
import subprocess
import winreg


def check_taskbar_icons():
    authorized_taskbar_icons = ["Explorer", "Chrome"]

    # Check taskbar icons
    taskbar_icons = subprocess.check_output(['powershell', 'Get-ChildItem -Path "$env:APPDATA\\Microsoft\\Internet Explorer\\Quick Launch\\User Pinned\\TaskBar" | Select-Object -ExpandProperty Name']).strip().decode('utf-8')

    taskbar_icons_list = taskbar_icons.split("\r\n")

    unauthorized_icons = [icon for icon in taskbar_icons_list if icon not in authorized_taskbar_icons]

    if len(unauthorized_icons) == 0:
        print("| C62834 | Taskbar icons: PASSED")
    else:
        authorized_icons = [icon for icon in taskbar_icons_list if icon in authorized_taskbar_icons]
        print("| C62834 | Taskbar icons: FAILED")


def check_start_menu_tiles():
    authorized_programs = ["Chrome", "d3manager", "Media Player Classic", "Recycle Bin"]

    # Check start menu tiles
    start_menu_tiles = subprocess.check_output(['powershell', 'Get-ChildItem -Path "$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs" -Recurse | Where-Object {$_.Extension -eq ".lnk"} | Select-Object -ExpandProperty Name']).strip().decode('utf-8')

    start_menu_tiles_list = start_menu_tiles.split("\r\n")

    unauthorized_programs = [program for program in start_menu_tiles_list if program not in authorized_programs]

    if len(unauthorized_programs) == 0:
        print("| C62834 | Start menu tiles: PASSED")
    else:
        print("| C62834 | Start menu tiles: FAILED")


def check_windows_licensing():
    # Check licensing status
    subprocess.check_call(['powershell', 'slmgr /dli | Select-String "License Status"'], stdout=subprocess.PIPE)
    print("| C62835 | Windows licensing: PASSED")


def check_windows_background_color():
    # Check background color
    background_color = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\\Control Panel\\Colors" -Name "Background" | Select-Object -ExpandProperty Background']).strip().decode('utf-8')

    if background_color == "58 58 58":
        print("| C62836 | Windows background color: PASSED")
    else:
        print("| C62836 | Windows background color: FAILED")


def check_machine_name():
    # Check machine name
    machine_name = subprocess.check_output(['powershell', 'hostname']).strip().decode('utf-8')

    print("| C62837 | Machine name: ", machine_name)


def check_notifications_disabled():
    try:
        notifications_disabled = subprocess.check_output(['powershell', 'Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoToastApplicationNotification"']).strip().decode('utf-8')
    except subprocess.CalledProcessError:
        print("| C62838 | Notifications: DISABLED")
        return

    if notifications_disabled == "1":
        print("| C62838 | Notifications: DISABLED")
    else:
        print("| C62838 | Notifications: ENABLED")


def check_windows_update_disabled():
    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU') as key:
        try:
            value, _ = winreg.QueryValueEx(key, 'NoAutoUpdate')
            if value == 1:
                print("| C62839 | Windows Update: DISABLED")
            else:
                print("| C62839 | Windows Update: ENABLED")
        except OSError:
            print("| C62839 | Windows Update: ENABLED")


def check_sticky_keys_disabled():
    sticky_keys_disabled = subprocess.check_output(['powershell', 'Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" | Select-Object -ExpandProperty Flags']).strip().decode('utf-8')
    if '0' in sticky_keys_disabled:
        print("| C62840 | Sticky keys: DISABLED")
    else:
        print("| C62840 | Sticky keys: NOT DISABLED")


def check_windows_firewall_disabled():
    firewall_status = subprocess.check_output(['powershell', 'Get-NetFirewallProfile -All | Select-Object -Property Name, Enabled']).strip().decode('utf-8')
    if 'False' in firewall_status:
        print("| C73261 | Windows Firewall: DISABLED")
    else:
        print("| C73261 | Windows Firewall: NOT DISABLED")

import os
import subprocess
import pyaudio
import pyautogui
import wmi
import colorama
import time
import sys
import psutil
import ctypes
from utils.logger import logging

colorama.init()


def check_general_devices():
    logging.info("| C62845 | Checking general devices, please wait...")
    time.sleep(1)

    # initialize WMI object
    c = wmi.WMI()
    warning_devices = []

    # iterate over all devices and check if any have warning symbols
    for device in c.Win32_PnPEntity():
        if device.status != 'OK':
            if 'Microsoft Basic Display Adapter' not in device.caption:
                logging.info(f"| C62845 | Device {device.caption} has a warning symbol and is not installed correctly")
                warning_devices.append(device)
            else:
                logging.info(f"| C62845 | Device {device.caption} has a warning symbol but this is expected, skipping.")
                time.sleep(2)

    if not warning_devices:
        logging.info("| C62845 | Device check passed")
        return True
    else:
        logging.error("| C62845 | Device Check Failed, please verify it")
        return False


def check_gpu_devices():
    logging.info("| C62846 | Checking GPU, please wait...")
    time.sleep(2)

    amd_path = os.path.join(os.environ['ProgramFiles'], 'AMD')
    nvidia_path = os.path.join(os.environ['ProgramFiles'], 'NVIDIA Corporation')

    if os.path.exists(amd_path):
        logging.info('| C62846 | AMD control panel found.')
        amd_control_panel_exe = os.path.join(amd_path, 'CNext', 'cnext.exe')
        if os.path.exists(amd_control_panel_exe):
            subprocess.Popen(amd_control_panel_exe)
            time.sleep(2)
            user_input = input('| C62846 | Please confirm that the AMD control panel is open (Y/N): ')
            if user_input.lower() == 'y':
                logging.info('| C62846 | AMD control panel present and able to open.\n')
                logging.info("| C62846 | GPU check passed")
                return True
            else:
                logging.info('| C62846 | AMD control panel executable not confirmed.\n')
                logging.error("| C62846 | GPU check failed, please check.")
                return False
        else:
            logging.error('| C62846 | AMD control panel executable not found.\n')
            logging.error("| C62846 | GPU check failed, please check.")
            return False
    elif os.path.exists(nvidia_path):
        logging.info('| C62846 | Nvidia control panel found.')
        nvidia_control_panel_exe = os.path.join(nvidia_path, 'Control Panel Client', 'nvcplui.exe')
        if os.path.exists(nvidia_control_panel_exe):
            subprocess.Popen(nvidia_control_panel_exe)
            time.sleep(2)
            user_input = input('| C62846 | Please confirm that the Nvidia control panel is open (Y/N): ')
            if user_input.lower() == 'y':
                logging.info('| C62846 | Nvidia control panel present and able to open.')
                time.sleep(2)
                logging.info("| C62846 | GPU check passed")
                return True
            else:
                logging.info('| C62846 | Nvidia control panel executable not confirmed.')
                time.sleep(2)
                logging.error("| C62846 | GPU check failed, please check.")
                return False
        else:
            logging.info('| C62846 | Nvidia control panel executable not found.')
            time.sleep(2)
            logging.error("| C62846 | GPU check failed, please check.")
            return False
    else:
        logging.error('| C62846 | Neither AMD nor Nvidia control panel found.')
        time.sleep(2)
        logging.error("| C62846 | GPU check failed, please check.")
        return False


def check_network_devices():
    expected_names_25 = ["A - d3Net 1Gbit",
                         "B - Media 10Gbit", "C - Media 10Gbit", "D - 25Gbit", "disguiseMGMT",
                         "E - 25Gbit"]
    expected_names_100 = ["A - d3Net 1Gbit",
                          "B - Media 10Gbit", "C - Media 10Gbit", "D - 100Gbit", "disguiseMGMT",
                          "E - 100Gbit"]

    wmi_obj = wmi.WMI()
    adapters = wmi_obj.Win32_NetworkAdapter()

    logging.info("| C62847 | Checking Network Adapters, please wait...")
    time.sleep(1)

    found_25 = False
    found_100 = False

    for adapter in adapters:
        if adapter.NetConnectionID is not None:
            if any(name in adapter.NetConnectionID for name in expected_names_25):
                logging.info(f"| C62847 | Adapter '{adapter.NetConnectionID}' found")
                found_25 = True
            elif any(name in adapter.NetConnectionID for name in expected_names_100):
                logging.info(f"| C62847 | Adapter '{adapter.NetConnectionID}' found")
                found_100 = True
            time.sleep(1)

    if found_25 and not found_100:
        logging.info("| C62847 | Network Adapters check passed")
        return True
    elif found_100 and not found_25:
        logging.info("| C62847 | Network Adapters check passed")
        return True
    else:
        not_found_25 = set(expected_names_25) - set(
            [adapter.NetConnectionID for adapter in adapters if adapter.NetConnectionID is not None])
        not_found_100 = set(expected_names_100) - set(
            [adapter.NetConnectionID for adapter in adapters if adapter.NetConnectionID is not None])
        message = ""
        if not_found_25:
            message += f"| C62847 | {len(not_found_25)} expected 25Gbit adapters not found: {', '.join(not_found_25)}"
        if not_found_100:
            message += f"| C62847 | {len(not_found_100)} expected 100Gbit adapters not found: {', '.join(not_found_100)}"
        logging.error(message)
        return False


def check_deltacast_devices():
    logging.info("| C62850 | Checking for Deltacast capture cards, please wait...")
    time.sleep(2)
    try:
        output = subprocess.check_output(
            "wmic path Win32_PNPEntity where \"caption like '%%%DELTA-12G-elp-h%%%'\" get caption",
            shell=True,
            stderr=subprocess.DEVNULL  # Discard the standard error stream
        )
    except subprocess.CalledProcessError:
        logging.error('| C62850 | Error: DeltaCast capture cards not found in the Device Manager, '
                      'must be a Matrox or Bluefish machine.')
        return False

    if "DELTA-12G-elp-h" in output.decode("utf-8"):
        logging.info("| C62850 | DeltaCast capture cards found in the Device Manager.")
    else:
        logging.error('| C62850 | Error: DeltaCast capture cards not found in the Device Manager, '
                      'must be a Matrox or a Bluefish machine.')
        return False

    dcare_exe = r"C:\Program Files\deltacast\dCARE\bin\dCARE.exe"
    if os.path.exists(dcare_exe):
        subprocess.Popen(dcare_exe)
        user_input = input('| C62850 | Please confirm that the dCARE utility is open (Y/N): ')
        if user_input.lower() == 'y':
            logging.info('| C62850 | dCARE successfully loaded.')
            return True
        else:
            logging.error('| C62850 | dCARE failed to load.')
            return False
    else:
        logging.error('| C62850 | Error: dCARE executable not found.')
        return False


def check_matrox_devices():
    logging.info("| C62851 | Checking for Matrox capture cards, please wait...")
    time.sleep(2)
    c = wmi.WMI()
    matrox_devices = ['Matrox Bus', 'Matrox Multi-function Device', 'Matrox Node Transfer Device',
                      'Matrox System Clock', 'Matrox Topology Device']
    found_devices = []

    for device in c.Win32_PnPEntity():
        if device.Caption in matrox_devices:
            found_devices.append(device.Caption)

    logging.info("| C62851 | Found Matrox devices:")
    time.sleep(1)
    for i, device in enumerate(found_devices):
        logging.info(f"| C62851 | {i + 1}. {device}")
        time.sleep(1)

    if set(matrox_devices) == set(found_devices):
        logging.info("| C62851 | Matrox Capture card check passed")
    else:
        logging.error("| C62851 | Matrox Capture card check not passed")


def check_audio_devices():
    logging.info("| C62852 | Checking for Audio devices, please wait...")
    time.sleep(1)
    p = pyaudio.PyAudio()
    info = p.get_host_api_info_by_index(0)
    numdevices = info.get('deviceCount')
    input_device_names = set()
    output_device_names = set()

    for i in range(0, numdevices):
        if p.get_device_info_by_host_api_device_index(0, i).get('maxInputChannels') > 0:
            input_device_names.add(p.get_device_info_by_host_api_device_index(0, i).get('name'))
            time.sleep(1)

        if p.get_device_info_by_host_api_device_index(0, i).get('maxOutputChannels') > 0:
            output_device_names.add(p.get_device_info_by_host_api_device_index(0, i).get('name'))
            time.sleep(1)

    input_device_names = sorted(list(input_device_names))
    output_device_names = sorted(list(output_device_names))

    expected_input_device_names = [
        'ADAT (1+2) (RME HDSPe AIO)',
        'ADAT (3+4) (RME HDSPe AIO)',
        'ADAT (5+6) (RME HDSPe AIO)',
        'ADAT (7+8) (RME HDSPe AIO)',
        'AES (1+2) (RME HDSPe AIO)',
        'Analog (1+2) (RME HDSPe AIO)',
        'Microphone (2- USB Audio Device',
        'Microsoft Sound Mapper - Input',
        'SPDIF (RME HDSPe AIO)'
    ]

    expected_output_device_names = [
        'ADAT (1+2) (RME HDSPe AIO)',
        'ADAT (3+4) (RME HDSPe AIO)',
        'ADAT (5+6) (RME HDSPe AIO)',
        'ADAT (7+8) (RME HDSPe AIO)',
        'AES (1+2) (RME HDSPe AIO)',
        'Analog (1+2) (RME HDSPe AIO)',
        'Microsoft Sound Mapper - Output',
        'Phones (RME HDSPe AIO)',
        'SPDIF (RME HDSPe AIO)',
        'Speakers (2- USB Audio Device)'
    ]

    logging.info("| C62852 | Input devices:")
    time.sleep(1)
    for i, name in enumerate(input_device_names):
        logging.info(f"| C62852 | {i + 1}. {name}")
        time.sleep(1)

    time.sleep(1)

    logging.info("| C62852 | Output devices:")
    time.sleep(1)
    for i, name in enumerate(output_device_names):
        logging.info(f"| C62852 | {i + 1}. {name}")
        time.sleep(1)

    time.sleep(1)

    if set(expected_input_device_names) == set(input_device_names) and set(expected_output_device_names) == set(
            output_device_names):
        logging.info("| C62852 | Audio devices check passed")
    else:
        logging.error("| C62852 | Audio devices check not passed")


def check_audio_card_management():
    logging.info("| C62853 | Checking for RME Hammerfall, please wait...")
    sys.stdout.flush()
    # wait for system tray to load
    time.sleep(5)

    # navigate to Hammerfall DSP icon and click on it
    pyautogui.click(x=1690, y=1065)

    # wait for the Hammerfall DSP settings window to open
    time.sleep(5)

    logging.info("| C62854 | Checking for TotalMix Audio patch, please wait...")
    sys.stdout.flush()

    # navigate to TotalMix icon and click on it
    pyautogui.click(x=1665, y=1058)
    time.sleep(3)
    pyautogui.click(x=1710, y=981)
    time.sleep(3)
    # switch to Matrix View to check
    pyautogui.press('x')

    # ask the user if the settings window opened
    user_input = input('| C62854 | Please check that the matrix is mapped as a diagonal line from Analog 1/2 '
                       'to ADAT 7/8, with a column of mappings in the third and fourth column. Press Enter when ready.')
    time.sleep(2)
    user_input = input('| C62853 | Did the Hammerfall DSP settings window open '
                       'and the matrix is configured as expected? (Y/N): ')
    if user_input.lower() == 'y':
        logging.info("| C62853 | Audio card management check passed")
        return True
    else:
        logging.error("| C62853 | Audio card management check failed")
        return False


def check_media_drives():
    logging.info("| C62855 | Checking for media drives, please wait...")
    media_drives = []

    for partition in psutil.disk_partitions():
        if partition.fstype != '':
            usage = psutil.disk_usage(partition.mountpoint)
            volume_name = ''
            if partition.device.startswith('\\\\'):
                # UNC path, skip the volume name retrieval
                pass
            else:
                # retrieve the volume name using the ctypes module
                volume_name_buffer = ctypes.create_unicode_buffer(1024)
                ctypes.windll.kernel32.GetVolumeInformationW(
                    ctypes.c_wchar_p(partition.device.rstrip('\\')),
                    volume_name_buffer,
                    ctypes.sizeof(volume_name_buffer),
                    None, None, None, None, 0
                )
                volume_name = volume_name_buffer.value.strip()

            drive_info = {"drive_letter": partition.device.rstrip('\\'), "name": volume_name,
                          "filesystem": partition.fstype, "size": f"{usage.total / (1024 * 1024 * 1024):.2f} GB"}
            media_drives.append(drive_info)
            time.sleep(1)

    for i, drive in enumerate(media_drives):
        logging.info(
            f"| C62855 | {i + 1}. {drive['drive_letter']} - {drive['name']} - {drive['filesystem']} - {drive['size']}")
        time.sleep(1)

    media_drive_found = any(drive['name'] == 'Media' and drive['drive_letter'] == 'D:' for drive in media_drives)

    if media_drive_found:
        logging.info("| C62855 | Media drive check passed")
    else:
        logging.error("| C62855 | Media drive check failed")

    return media_drives


def check_raid_tool():
    logging.info("| C62856 | Checking for the RAID controller tool, please wait...")
    time.sleep(2)
    try:
        subprocess.Popen("C:\\Program Files\\LSI\\LSIStorageAuthority\\startupLSAUI.bat")
        logging.info("| C62856 | Raid controller tool opened successfully.")
    except FileNotFoundError:
        logging.error("| C62856 | ERROR: Rais controller tool not found.")

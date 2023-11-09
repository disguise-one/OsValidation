import os
import subprocess
import pyaudio
import wmi
import time
from utils.logger import logging, log_and_print
import yaml
import pyautogui
import sys
import psutil
import ctypes


# Global variable to store the configuration
CONFIG = None


def load_config():
    global CONFIG
    config_path = 'config/config.yaml'
    try:
        with open(config_path, 'r') as f:
            CONFIG = yaml.safe_load(f)
        if CONFIG is None:
            raise ValueError("Configuration is empty")
    except Exception as e:
        logging.error(f"Failed to load configuration: {e}")
        CONFIG = {}


# Call load_config  to load the configuration
load_config()


def check_general_devices():
    # Log the start of the general device check
    logging.info("| C62845 | Checking general devices, please wait...")

    # Initialize WMI object to query system components
    c = wmi.WMI()
    # Create an empty list to store devices with warnings
    warning_devices = []

    # Iterate over all hardware devices in the system
    for device in c.Win32_PnPEntity():
        # Check if the device's status is not OK
        if device.status != 'OK':
            # Exclude 'Microsoft Basic Display Adapter' from the warning, as it's an expected fallback driver
            if 'Microsoft Basic Display Adapter' not in device.caption:
                logging.info(f"| C62845 | Device {device.caption} has a warning symbol and is not installed correctly")
                warning_devices.append(device)
            else:
                logging.info(f"| C62845 | Device {device.caption} has a warning symbol but this is expected, skipping.")

    # Determine and log the result of the device check
    if not warning_devices:
        logging.info("| C62845 | Device check passed")
        return True
    else:
        logging.error("| C62845 | Device Check Failed, please verify it")
        return False


def detect_gpu_brand():
    # Initialize WMI object
    c = wmi.WMI()
    # Iterate over all hardware devices to detect GPU brand based on its Hardware ID
    for device in c.Win32_PnPEntity():
        if device.PNPDeviceID:
            hardware_id = device.PNPDeviceID.upper()
            if 'VEN_10DE' in hardware_id:  # NVIDIA Vendor ID
                return 'nvidia', hardware_id
            elif 'VEN_1002' in hardware_id:  # AMD Vendor ID
                return 'amd', hardware_id
    return None, None


def check_gpu_devices(open_panel=False):
    # Log the start of the GPU check
    logging.info("Checking GPU, please wait...")

    # Define paths to AMD and NVIDIA control panels
    amd_path = os.path.join(os.environ['ProgramFiles'], 'AMD')
    nvidia_path = os.path.join(os.environ['ProgramFiles'], 'NVIDIA Corporation')

    # Detect the GPU brand and its hardware ID
    gpu_brand, hardware_id = detect_gpu_brand()

    # Log the detected GPU hardware ID
    if hardware_id:
        logging.info(f"Detected GPU with Hardware ID: {hardware_id}")
        logging.info("Checking GPU Vendor, please wait...")

    # Check the GPU brand and validate the respective control panel
    if gpu_brand == 'amd':
        logging.info("Detected an AMD GPU.")
        return check_gpu_control_panel(amd_path, 'CNext\\Cnext\\RadeonSoftware.exe', 'AMD', open_panel)
    elif gpu_brand == 'nvidia':
        logging.info("Detected an nvidia GPU.")
        return check_gpu_control_panel(nvidia_path, 'Control Panel Client\\nvcplui.exe', 'Nvidia', open_panel)
    else:
        logging.info('No recognized GPU or control panel found.', "error")
        return False


def check_gpu_control_panel(path, exe_name, control_panel_name, open_panel=False):
    # Log the start of the control panel check for the detected GPU brand
    logging.info(f"Checking for {control_panel_name} control panel in path {path}.")
    # Build the full path to the control panel executable
    control_panel_exe = os.path.join(path, exe_name)

    # Check if the control panel executable exists
    if os.path.exists(control_panel_exe):
        logging.info(f"Found {control_panel_name} control panel executable.")
        # If the open_panel flag is True, attempt to open the control panel and ask for user confirmation
        if open_panel:
            subprocess.Popen(control_panel_exe)
            time.sleep(2)
            user_input = ''
            # Loop until a valid response ('y' or 'n') is received
            while user_input.lower() not in ['y', 'n']:
                user_input = input(f'Please confirm that the {control_panel_name} control panel is open (Y/N): ')
            if user_input.lower() == 'y':
                logging.info(f"{control_panel_name} control panel present and able to open.")
                return True
            else:
                logging.info(f"{control_panel_name} control panel executable not confirmed by user.", "error")
                return False
        return True
    else:
        logging.info(f"{control_panel_name} control panel executable not found.", "error")
        return False


def check_network_devices():
    # Use the global CONFIG variable
    global CONFIG
    expected_names_25 = set(CONFIG["expected_names_25"])
    expected_names_100 = set(CONFIG["expected_names_100"])

    wmi_obj = wmi.WMI()
    adapters = wmi_obj.Win32_NetworkAdapter()

    logging.info("| C62847 | Checking Network Adapters, please wait...")

    found_adapters = set([adapter.NetConnectionID for adapter in adapters if adapter.NetConnectionID])

    found_25 = expected_names_25.issubset(found_adapters)
    found_100 = expected_names_100.issubset(found_adapters)

    if found_25:
        found_list = sorted(list(expected_names_25 & found_adapters))
        logging.info(f"| INFO | Found: {', '.join(found_list)}.")
        return True
    elif found_100:
        found_list = sorted(list(expected_names_100 & found_adapters))
        logging.info(f"| INFO | Found: {', '.join(found_list)}.")
        return True
    else:
        found_list = sorted(list(found_adapters))
        logging.info(f"| ERROR | No complete set of 25Gbit or 100Gbit adapters found. Found: {', '.join(found_list)}.")
        return False


def check_capture_card_devices():
    logging.info("| C62852 | Checking for capture cards, please wait...")

    # Initialize WMI object
    c = wmi.WMI()

    # Capture card vendor identification by hardware ID
    for device in c.Win32_PnPEntity():
        if device.PNPDeviceID:
            hardware_id = device.PNPDeviceID.upper()

            # Check for Matrox
            if 'PCI\VEN_102B' in hardware_id:
                return _check_matrox_devices()

            # Check for Deltacast by Vendor ID
            elif 'PCI\VEN_1B66' in hardware_id:
                return _check_deltacast_devices()

    logging.warning(
        "| C62852 | No recognized capture card found by vendor ID. Checking for Deltacast by driver name...")
    if _check_deltacast_devices():
        return True

    logging.warning("| C62852 | No recognized capture card found by vendor ID. Checking for Matrox by driver name...")
    return _check_matrox_devices()


def _check_deltacast_devices():
    # Check for the "delta" keyword in device's caption to ensure driver presence
    for device in wmi.WMI().Win32_PnPEntity():
        if "DELTA" in (device.Caption or "").upper():
            logging.info("| C62850 | Deltacast driver detected in Device Manager.")
            break
    else:
        logging.error("| C62850 | Deltacast driver not detected in Device Manager.")
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


def _check_matrox_devices():
    matrox_devices = ['Matrox Bus', 'Matrox Multi-function Device', 'Matrox Node Transfer Device',
                      'Matrox System Clock', 'Matrox Topology Device']
    found_devices = [device.Caption for device in wmi.WMI().Win32_PnPEntity() if device.Caption in matrox_devices]

    if set(matrox_devices) == set(found_devices):
        logging.info("| C62851 | Matrox Capture card check passed")
        return True
    else:
        missing_devices = set(matrox_devices) - set(found_devices)
        logging.error(
            f"| C62851 | Matrox Capture card check not passed. Missing devices: {', '.join(missing_devices)}")
        return False


def detect_audio_device_by_hardware_id():
    """
    Detects the audio device by its hardware ID.
    Returns True if found, otherwise False.
    """
    hardware_id = "PCI\\VEN_1D18&DEV_3FC6"
    c = wmi.WMI()
    for device in c.Win32_PnPEntity():
        if device.PNPDeviceID and hardware_id in device.PNPDeviceID:
            return True
    return False


def check_audio_devices():
    global CONFIG
    EXPECTED_INPUT_NAMES = CONFIG["audio_devices"]["expected_input_names"]
    EXPECTED_OUTPUT_NAMES = CONFIG["audio_devices"]["expected_output_names"]
    logging.info("| C62852 | Checking for Audio devices, please wait...")

    # Check for audio devices by their hardware IDs
    if not detect_audio_device_by_hardware_id():
        logging.error("| C62852 | No recognized audio device found by hardware ID.")
        return False

    p = pyaudio.PyAudio()
    info = p.get_host_api_info_by_index(0)
    numdevices = info.get('deviceCount')
    input_device_names = set()
    output_device_names = set()

    for i in range(0, numdevices):
        device_info = p.get_device_info_by_host_api_device_index(0, i)
        if device_info.get('maxInputChannels') > 0:
            input_device_names.add(device_info.get('name'))
        if device_info.get('maxOutputChannels') > 0:
            output_device_names.add(device_info.get('name'))

    input_device_names = sorted(list(input_device_names))
    output_device_names = sorted(list(output_device_names))

    logging.info("| C62852 | Input devices:")
    for i, name in enumerate(input_device_names):
        logging.info(f"| C62852 | {i + 1}. {name}")

    logging.info("| C62852 | Output devices:")
    for i, name in enumerate(output_device_names):
        logging.info(f"| C62852 | {i + 1}. {name}")

    if set(EXPECTED_INPUT_NAMES) == set(input_device_names) and set(EXPECTED_OUTPUT_NAMES) == set(output_device_names):
        logging.info("| C62852 | Audio devices check passed")
        return True
    else:
        missing_input_devices = set(EXPECTED_INPUT_NAMES) - set(input_device_names)
        missing_output_devices = set(EXPECTED_OUTPUT_NAMES) - set(output_device_names)
        logging.error(f"| C62852 | Missing input devices: {', '.join(missing_input_devices)}")
        logging.error(f"| C62852 | Missing output devices: {', '.join(missing_output_devices)}")
        return False


# TO-DO
#
# def check_audio_card_management():
#     logging.info("| C62853 | Checking for RME Hammerfall, please wait...")
#     sys.stdout.flush()
#     # wait for system tray to load
#     time.sleep(5)
#
#     # navigate to Hammerfall DSP icon and click on it
#     pyautogui.click(x=1690, y=1065)
#
#     # wait for the Hammerfall DSP settings window to open
#     time.sleep(5)
#
#     logging.info("| C62854 | Checking for TotalMix Audio patch, please wait...")
#     sys.stdout.flush()
#
#     # navigate to TotalMix icon and click on it
#     pyautogui.click(x=1665, y=1058)
#     time.sleep(3)
#     pyautogui.click(x=1710, y=981)
#     time.sleep(3)
#     # switch to Matrix View to check
#     pyautogui.press('x')
#
#     # ask the user if the settings window opened
#     user_input = input('| C62854 | Please check that the matrix is mapped as a diagonal line from Analog 1/2 '
#                        'to ADAT 7/8, with a column of mappings in the third and fourth column. Press Enter when ready.')
#     time.sleep(2)
#     user_input = input('| C62853 | Did the Hammerfall DSP settings window open '
#                        'and the matrix is configured as expected? (Y/N): ')
#     if user_input.lower() == 'y':
#         logging.info("| C62853 | Audio card management check passed")
#         return True
#     else:
#         logging.error("| C62853 | Audio card management check failed")
#         return False
#


def check_media_drives():
    global CONFIG
    expected_drive_letter = CONFIG['media_drives']['expected_drive_letter']
    expected_volume_name = CONFIG['media_drives']['expected_volume_name']

    logging.info("| C62855 | Checking for media drives, please wait...")
    media_drives = []

    try:
        for partition in psutil.disk_partitions():
            if partition.fstype != '':
                usage = psutil.disk_usage(partition.mountpoint)
                volume_name = ''
                if not partition.device.startswith('\\\\'):  # Skip UNC paths
                    volume_name_buffer = ctypes.create_unicode_buffer(1024)
                    ctypes.windll.kernel32.GetVolumeInformationW(
                        ctypes.c_wchar_p(os.path.splitext(partition.device)[0]),
                        volume_name_buffer,
                        ctypes.sizeof(volume_name_buffer),
                        None, None, None, None, 0
                    )
                    volume_name = volume_name_buffer.value.strip()

                drive_info = {
                    "drive_letter": os.path.splitext(partition.device)[0],
                    "name": volume_name,
                    "filesystem": partition.fstype,
                    "size": f"{usage.total / (1024 ** 3):.2f} GB"
                }
                media_drives.append(drive_info)

        for drive in media_drives:
            logging.info(
                f"| C62855 | {drive['drive_letter']} - {drive['name']} - {drive['filesystem']} - {drive['size']}")

        media_drive_found = any(
            drive['name'] == expected_volume_name and drive['drive_letter'] == expected_drive_letter for drive in
            media_drives)
        if media_drive_found:
            logging.info("| C62855 | Media drive check passed")
        else:
            logging.error("| C62855 | Media drive check failed")

    except Exception as e:
        logging.error(f"| C62855 | An error occurred while checking media drives: {e}")

    return media_drives


def detect_raid_controller():
    global CONFIG
    raid_hardware_id = CONFIG['raid_controller']['hardware_id']
    raid_device_name = CONFIG['raid_controller']['device_name']
    c = wmi.WMI()

    for device in c.Win32_PnPEntity():
        # Ensure that HardwareID and Name are iterable before checking
        if device.HardwareID and raid_hardware_id in device.HardwareID:
            return True
        if device.Name and raid_device_name.lower() in device.Name.lower():
            return True
    return False


def check_raid_tool():
    logging.info("| C62856 | Checking for the RAID controller tool, please wait...")
    time.sleep(2)

    if not detect_raid_controller():
        logging.error("| C62856 | ERROR: RAID controller not detected on the system.")
        return

    raid_tool_path = CONFIG['raid_controller']['tool_path']
    try:
        subprocess.Popen(raid_tool_path)
        logging.info("| C62856 | RAID controller tool opened successfully.")
    except FileNotFoundError:
        logging.error(f"| C62856 | ERROR: RAID controller tool not found at {raid_tool_path}.")

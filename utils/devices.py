import os
import subprocess
import pyaudio
import wmi
import time
from utils.logger import logging
import yaml
import pyautogui
import sys
import psutil
import ctypes
import logging
import time
import cv2
import numpy as np
from pywinauto.application import Application
from pywinauto.keyboard import send_keys
from PIL import Image

# Global variable to store the configuration
CONFIG = None


def load_config():
    """
    Loads the configuration from the 'config/config.yaml' file into the global CONFIG variable.
    If the configuration is empty or an error occurs, it logs the error and sets CONFIG to an empty dictionary.

    Side effects:
        - Modifies the global CONFIG variable.
        - Reads from a file on disk.
        - Logs messages regarding the success or failure of the operation.
    """
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
    """
    Checks all hardware devices on the system and logs any devices that do not have a status of 'OK'.
    Devices with a status other than 'OK' are added to a list of warning devices unless they are
    identified as 'Microsoft Basic Display Adapter', which is an expected fallback driver.

    Returns:
        bool: True if all devices are working correctly, False if any device has a warning status.

    Side effects:
        - Logs messages about the device statuses.
    """

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
    """
    Detects the brand of the GPU installed in the system by querying the hardware ID.

    Returns:
        tuple: A tuple containing the brand of the GPU ('nvidia', 'amd', or None) and its hardware ID.
               If the GPU brand is not recognized, both elements of the tuple will be None.
    """

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
    """
    Checks if the appropriate GPU control panel is present for the detected GPU brand and optionally opens it.

    Parameters:
        open_panel (bool): If True, the function will attempt to open the GPU control panel and will prompt
                           the user for confirmation.

    Returns:
        bool: True if the correct GPU control panel is found (and optionally confirmed by the user), False otherwise.

    Side effects:
        - Opens external applications if open_panel is True.
        - Logs messages about the GPU check progress and results.
    """

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
    """
    Checks if the executable for the GPU control panel is present in the specified path and optionally opens it.

    Parameters:
        path (str): The file path where the GPU control panel executable is expected to be located.
        exe_name (str): The name of the control panel executable file.
        control_panel_name (str): The human-readable name of the GPU control panel (e.g., 'AMD', 'Nvidia').
        open_panel (bool): If True, the function will attempt to open the GPU control panel and prompt for user confirmation.

    Returns:
        bool: True if the control panel executable is found (and optionally confirmed by the user), False otherwise.

    Side effects:
        - May open an external application if open_panel is True.
        - Logs messages about the control panel check progress and results.
    """

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
        logging.error(f"{control_panel_name} control panel executable not found.", )
        return False


def check_network_devices():
    """
    Checks if the expected network devices are present in the system based on the global CONFIG variable.

    Returns:
        bool: True if all expected network devices are found, False otherwise.

    Side effects:
        - Logs messages about the network devices check progress and results.
    """

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
        logging.info(f"Found: {', '.join(found_list)}.")
        return True
    elif found_100:
        found_list = sorted(list(expected_names_100 & found_adapters))
        logging.info(f"Found: {', '.join(found_list)}.")
        return True
    else:
        found_list = sorted(list(found_adapters))
        logging.error(f"No complete set of 25Gbit or 100Gbit adapters found. Found: {', '.join(found_list)}.")
        return False


def check_capture_card_devices():
    """
    Checks for the presence of specific capture card devices by their hardware ID.

    Returns:
        bool: True if the expected capture card device is found, False otherwise.

    Side effects:
        - Logs messages about the capture card check progress and results.
    """

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
    """
    Checks for the presence of Deltacast devices by looking for a specific keyword in the device's caption
    and verifies the presence of the dCARE utility.

    Returns:
        bool: True if the Deltacast driver and dCARE utility are detected, False otherwise.

    Side effects:
        - May open the dCARE utility application.
        - Logs messages about the Deltacast device check progress and results.
    """

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
    """
    Checks for the presence of Matrox devices by comparing the list of expected device captions
    against the device captions found in the system.

    Returns:
        bool: True if all expected Matrox devices are found, False otherwise.

    Side effects:
        - Logs messages about the Matrox device check progress and results.
    """

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
    Detects the presence of an audio device by a specific hardware ID.

    Returns:
        bool: True if the audio device with the specified hardware ID is found, False otherwise.
    """
    hardware_id = "PCI\\VEN_1D18&DEV_3FC6"
    c = wmi.WMI()
    for device in c.Win32_PnPEntity():
        if device.PNPDeviceID and hardware_id in device.PNPDeviceID:
            return True
    return False


def check_audio_devices():
    """
    Checks for the presence of expected audio input and output devices based on the global CONFIG variable.

    Returns:
        bool: True if all expected audio devices are found, False otherwise.

    Side effects:
        - Logs messages about the audio devices check progress and results.
    """

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


def open_hammerfall_dsp_settings():
    try:
        app = Application(backend="uia")
        app.connect(title_re=".*Hammerfall DSP Settings.*")  # Adjust the regex according to the actual window title
        hammerfall_window = app.window(title_re=".*Hammerfall DSP Settings.*")
        hammerfall_window.set_focus()
        return hammerfall_window
    except Exception as e:
        logging.error(f"Error opening Hammerfall DSP Settings: {e}")
        return None


def open_totalmix():
    try:
        app = Application(backend="uia")
        app.connect(title_re=".*RME TotalMix FX: HDSP AIO.*")
        totalmix_window = app.window(title_re=".*RME TotalMix FX: HDSP AIO.*")
        totalmix_window.set_focus()
        return totalmix_window
    except Exception as e:
        logging.error(f"Error opening TotalMix: {e}")
        return None


def capture_window_screenshot(window):
    if window.exists():
        window.set_focus()
        screenshot = window.capture_as_image()
        screenshot.save("current_view.png")
        return "current_view.png"
    else:
        return None


def image_match(reference_image_path, current_view_path):
    reference_image = cv2.imread(reference_image_path)
    current_view = cv2.imread(current_view_path)
    difference = cv2.subtract(reference_image, current_view)
    return not np.any(difference)  # If difference is all zeros, images are the same


def check_audio_card_management():
    logging.info("| C62853 | Checking for RME Hammerfall, please wait...")
    hammerfall_window = open_hammerfall_dsp_settings()
    if hammerfall_window is None:
        logging.error("| C62853 | Failed to open Hammerfall DSP settings window.")
        return False

    time.sleep(5)  # wait for the Hammerfall DSP settings window to open

    logging.info("| C62854 | Checking for TotalMix Audio patch, please wait...")
    totalmix_window = open_totalmix()
    if totalmix_window is None:
        logging.error("| C62854 | Failed to open TotalMix window.")
        return False

    # Switch to Matrix View by pressing 'X'
    send_keys('X')
    time.sleep(3)  # wait for the view to switch to Matrix

    # Capture a screenshot of the TotalMix window
    current_view_path = capture_window_screenshot(totalmix_window)
    if current_view_path is None:
        logging.error("| C62854 | Failed to capture screenshot of TotalMix window.")
        return False

    # Compare the screenshot with your reference image
    if image_match('resources/TotalMix.PNG', current_view_path):
        logging.info("| C62854 | TotalMix matrix view matches reference image. Test passed.")
        return True
    else:
        logging.error("| C62854 | TotalMix matrix view does not match reference image. Test failed.")
        return False


def check_media_drives():
    """
    Checks for the presence of expected media drives based on the global CONFIG variable.

    Returns:
        list: A list of dictionaries, each containing details of a media drive found in the system.

    Side effects:
        - Logs messages about the media drives check progress and results.
        - May cause a Windows API call to retrieve volume information.
    """

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
    """
    Detects the presence of a RAID controller in the system based on hardware ID and device name from the global CONFIG variable.

    Returns:
        bool: True if the RAID controller is detected, False otherwise.
    """

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
    """
    Checks for the presence of the RAID controller tool by attempting to open it using the path specified in the global CONFIG variable.

    Side effects:
        - May open an external application (the RAID tool).
        - Logs messages about the RAID tool check progress and results.
    """

    logging.info("| C62856 | Checking for the RAID controller tool, please wait...")

    if not detect_raid_controller():
        logging.error("| C62856 | ERROR: RAID controller not detected on the system.")
        return

    raid_tool_path = CONFIG['raid_controller']['tool_path']
    try:
        subprocess.Popen(raid_tool_path)
        logging.info("| C62856 | RAID controller tool opened successfully.")
    except FileNotFoundError:
        logging.error(f"| C62856 | ERROR: RAID controller tool not found at {raid_tool_path}.")

from utils.logger import logging
import time
import wmi


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
                logging.warning(f"| C62845 | Device {device.caption} has a warning symbol "
                                f"and is not installed correctly")
                warning_devices.append(device)
            else:
                logging.warning(f"| C62845 | Device {device.caption} has a warning symbol but this is expected, "
                                f"skipping.")
                time.sleep(2)

    if not warning_devices:
        logging.info("| C62845 | Device check passed")
        return True
    else:
        logging.error("| C62845 | Device Check Failed, please verify it")
        return False


check_general_devices()

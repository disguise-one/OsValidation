from utils import file_handling, windows_settings, devices, d3_interaction
from utils.logger import logging
import time
import sys

sleep_time = 1


try:
    logging.info("Running Windows Settings Validation, please wait...")
    time.sleep(2)
    windows_settings.check_taskbar_icons()
    time.sleep(sleep_time)
    windows_settings.check_start_menu_tiles()
    time.sleep(sleep_time)
    windows_settings.check_windows_licensing()
    time.sleep(sleep_time)
    windows_settings.check_windows_background_color()
    time.sleep(sleep_time)
    windows_settings.check_machine_name()
    time.sleep(sleep_time)
    windows_settings.check_notifications_disabled()
    time.sleep(sleep_time)
    windows_settings.check_sticky_keys_disabled()
    time.sleep(sleep_time)
    windows_settings.check_windows_firewall_disabled()
    time.sleep(2)
except KeyboardInterrupt:
    logging.info("Keyboard Interrupt received, exiting the program.")
    sys.exit(0)
except Exception as e:
    logging.exception(f"An unexpected error occurred: {e}")


try:
    logging.info("Running File Handling Validation, please wait...")
    time.sleep(2)
    file_handling.check_system_failure_checkboxes()
    time.sleep(sleep_time)
    file_handling.check_dump_file_path()
    time.sleep(sleep_time)
    file_handling.check_file()
except KeyboardInterrupt:
    logging.info("Keyboard Interrupt received, exiting the program.")
    sys.exit(0)
except Exception as e:
    logging.exception(f"An unexpected error occurred: {e}")


try:
    logging.info("Running Devices Validation, please wait...")
    time.sleep(2)
    devices.check_general_devices()
    time.sleep(sleep_time)
    devices.check_gpu_devices()
    time.sleep(sleep_time)
    devices.check_network_devices()
    time.sleep(sleep_time)
    devices.check_deltacast_devices()
    time.sleep(sleep_time)
    devices.check_matrox_devices()
    time.sleep(sleep_time)
    devices.check_audio_devices()
    time.sleep(sleep_time)
    devices.check_audio_card_management()
    time.sleep(sleep_time)
    devices.check_media_drives()
    time.sleep(sleep_time)
    devices.check_raid_tool()
except KeyboardInterrupt:
    logging.info("Keyboard Interrupt received, exiting the program.")
    sys.exit(0)
except Exception as e:
    logging.exception(f"An unexpected error occurred: {e}")


try:
    logging.info("Running d3 interaction validation, please wait...")
    time.sleep(2)
    d3_interaction.check_d3_project()
    time.sleep(sleep_time)
    d3_interaction.check_d3_manager_help()
    time.sleep(sleep_time)
    d3_interaction.check_d3_licences()
    time.sleep(sleep_time)
    d3_interaction.check_OS_image_version()
except KeyboardInterrupt:
    logging.info("Keyboard Interrupt received, exiting the program.")
    sys.exit(0)
except Exception as e:
    logging.exception(f"An unexpected error occurred: {e}")
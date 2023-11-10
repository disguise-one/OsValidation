from utils import file_handling, windows_settings, devices, d3_interaction
from utils.logger import logging
import time
import sys


# try:
#     logging.info("Running Windows Settings Validation, please wait...")
#     windows_settings.check_taskbar_icons()
#     windows_settings.check_start_menu_tiles()
#     windows_settings.check_windows_licensing()
#     windows_settings.check_windows_background_color()
#     windows_settings.check_machine_name()
#     windows_settings.check_notifications_disabled()
#     windows_settings.check_sticky_keys_disabled()
#     windows_settings.check_windows_firewall_disabled()
# except KeyboardInterrupt:
#     logging.info("Keyboard Interrupt received, exiting the program.")
#     sys.exit(0)
# except Exception as e:
#     logging.exception(f"An unexpected error occurred: {e}")
#
#
# try:
#     logging.info("Running File Handling Validation, please wait...")
#     file_handling.check_system_failure_checkboxes()
#     file_handling.check_dump_file_path()
#     file_handling.check_file()
# except KeyboardInterrupt:
#     logging.info("Keyboard Interrupt received, exiting the program.")
#     sys.exit(0)
# except Exception as e:
#     logging.exception(f"An unexpected error occurred: {e}")


try:
    logging.info("Running Devices Validation, please wait...")
    # devices.check_general_devices()
    # devices.detect_gpu_brand()
    # devices.check_gpu_devices()
    # devices.check_network_devices()
    # devices.check_capture_card_devices()
    devices.check_audio_devices()
    devices.check_audio_card_management()
    # devices.check_media_drives()
    # devices.check_raid_tool()
except KeyboardInterrupt:
    logging.info("Keyboard Interrupt received, exiting the program.")
    sys.exit(0)
except Exception as e:
    logging.exception(f"An unexpected error occurred: {e}")


# try:
#     logging.info("Running d3 interaction validation, please wait...")
#     d3_interaction.check_d3_project()
#     d3_interaction.check_d3_manager_help()
#     d3_interaction.check_d3_licences()
#     d3_interaction.check_OS_image_version()
# except KeyboardInterrupt:
#     logging.info("Keyboard Interrupt received, exiting the program.")
#     sys.exit(0)
# except Exception as e:
#     logging.exception(f"An unexpected error occurred: {e}")

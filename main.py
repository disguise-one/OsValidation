from utils import file_handling, windows_settings, devices, d3_interaction
from utils.logger import logging
import sys


def run_validation_group(validation_functions, group_name):
    """
    Executes a group of validation functions and handles common exceptions.

    This function logs the start of each validation group, runs each function
    in the list, and handles keyboard interrupts and unexpected exceptions.

    Args:
        validation_functions (list): A list of functions to be executed.
        group_name (str): Name of the validation group for logging purposes.
    """
    try:
        logging.info(f"Running {group_name}, please wait...")
        for function in validation_functions:
            function()
    except KeyboardInterrupt:
        logging.info("Keyboard Interrupt received, exiting the program.")
        sys.exit(0)
    except Exception as e:
        logging.exception(f"An unexpected error occurred: {e}")


def main():
    """
    Main function to orchestrate various validation checks.

    This function is the entry point of the script. It first loads the configuration,
    then runs different groups of validation functions related to Windows settings,
    file handling, device checks, and d3 interaction.
    """
    # Load the configuration from YAML file
    devices.load_config()

    # Group of functions for validating Windows settings
    windows_validation_functions = [
        windows_settings.check_taskbar_icons,
        windows_settings.check_start_menu_tiles,
        windows_settings.check_windows_licensing,
        windows_settings.check_windows_background_color,
        windows_settings.check_machine_name,
        windows_settings.check_notifications_disabled,
        windows_settings.check_sticky_keys_disabled,
        windows_settings.check_windows_firewall_disabled
    ]
    run_validation_group(windows_validation_functions, "Windows Settings")

    # Group of functions for file handling validation
    file_handling_functions = [
        file_handling.check_system_failure_checkboxes,
        file_handling.check_dump_file_path,
        file_handling.check_file
    ]
    run_validation_group(file_handling_functions, "File Handling")

    # Group of functions for device validation
    device_validation_functions = [
        devices.check_general_devices,
        devices.detect_gpu_brand,
        devices.check_gpu_devices,
        devices.check_network_devices,
        devices.check_capture_card_devices,
        devices.check_audio_devices,
        devices.check_audio_card_management,
        devices.check_media_drives,
        devices.check_raid_tool
    ]
    run_validation_group(device_validation_functions, "Devices Validation")

    # Group of functions for d3 interaction validation
    d3_interaction_functions = [
        d3_interaction.check_d3_project,
        d3_interaction.check_d3_manager_help,
        d3_interaction.check_d3_licences,
        d3_interaction.check_OS_image_version
    ]
    run_validation_group(d3_interaction_functions, "d3 Interaction")


if __name__ == "__main__":
    main()

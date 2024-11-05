import subprocess
import json
from utils.logger import logging


def get_and_log_config_data():
    subprocess_args = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "C:\\OsValidation\\utils\\powershell\\reimage_config.ps1"
    ]

    p = subprocess.run(subprocess_args, capture_output=True, text=True)

    if p.returncode != 0:
        logging.error(f"PowerShell script exited with error code {p.returncode}")
        logging.error(p.stderr)
        return None

    try:
        data = json.loads(p.stdout)
        filter_and_log_data(data)
        return data
    except json.JSONDecodeError as e:
        logging.error(f"Error parsing JSON from PowerShell: {e}")


def filter_and_log_data(data):
    keys_of_interest = [
        'description', 'osHardwarePlatform', 'hasD3Installed', 'requiresNotchLicense',
        'usesCaptureCards', 'AllowedCaptureCardTypes', 'validateGPUModelName',
        'AdapterNames1G', 'AdapterNames10G', 'AdapterNames100G', 'usesHammerfallAudio'
    ]

    nested_keys = ['ProductCode', 'd3Product', 'd3Model']

    for key in keys_of_interest:
        if key in data:
            logging.info(f"{key}: {data[key]}")
        else:
            logging.warning(f"Key '{key}' not found in the data.")

    if 'CodeMeterProductCodes' in data:
        for entry in data['CodeMeterProductCodes']:
            for nested_key in nested_keys:
                if nested_key in entry:
                    logging.info(f"{nested_key}: {entry[nested_key]}")
                else:
                    logging.warning(f"Nested key '{nested_key}' not found in CodeMeterProductCodes.")
    else:
        logging.warning("Key 'CodeMeterProductCodes' not found in the data.")


# Call the function
get_and_log_config_data()

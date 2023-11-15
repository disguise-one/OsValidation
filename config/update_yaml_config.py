import yaml
from utils.powershell.reimage_config import get_and_log_config_data


def yaml_dump(data, stream=None):
    # Custom dumper function to add newlines between top-level keys
    yaml_str = ""
    for key, value in data.items():
        yaml_str += f"\n{key}:\n"
        yaml_str += yaml.dump({key: value}, default_flow_style=False).split('\n', 1)[1]
    if stream:
        stream.write(yaml_str)
    else:
        return yaml_str


def update_yaml_config(data, yaml_file_path):
    # Read the existing YAML file
    with open(yaml_file_path, 'r') as file:
        config = yaml.safe_load(file) or {}

    # Update the hardware_info section
    hardware_keys = ['description', 'osHardwarePlatform', 'hasD3Installed',
                     'requiresNotchLicense', 'usesCaptureCards', 'validateGPUModelName',
                     'usesHammerfallAudio']
    for key in hardware_keys:
        if key in data:
            config['hardware_info'][key] = data[key]

    # Update the adapter_names section
    adapter_keys = ['AdapterNames1G', 'AdapterNames10G', 'AdapterNames100G']
    for key in adapter_keys:
        if key in data:
            config['adapter_names'][key] = data[key]

    # Update the allowed_capture_card_types and product_codes if present
    if 'AllowedCaptureCardTypes' in data:
        config['allowed_capture_card_types'] = data['AllowedCaptureCardTypes']
    if 'CodeMeterProductCodes' in data:
        config['product_codes'] = data['CodeMeterProductCodes']

    # Write the updated configuration back to the YAML file
    with open(yaml_file_path, 'w') as file:
        yaml_dump(config, stream=file)


# Assuming 'all_config_data' contains the data retrieved from the PowerShell script
all_config_data = get_and_log_config_data()
update_yaml_config(all_config_data, 'C:\OsValidation\config\config.yaml')

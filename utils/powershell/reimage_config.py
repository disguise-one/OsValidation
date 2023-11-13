import subprocess
import json


def get_value_from_powershell(key_name, return_value_should_be_array):
    subprocess_args = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "C:/path/to/your/script.ps1",
        key_name
    ]

    if return_value_should_be_array:
        subprocess_args.append("-EnforceReturnValueAsArray")

    p = subprocess.run(subprocess_args, capture_output=True, text=True)

    if p.returncode != 0:
        print(f"PowerShell script exited with error code {p.returncode}")
        print(p.stderr)
        return None

    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError as e:
        print(f"Could not load value [{key_name}] from PowerShell output. Error: {e}")
        print(f"The command ran on the command line was: {' '.join(subprocess_args)}")
        print("The output of the command was:")
        print('---- STDOUT: ----')
        print(p.stdout)
        print('---- STDERR: ----')
        print('\033[91m' + p.stderr + '\033[0m')
        print('---- ------- ----')
        return None


matrox_pin_map_files = get_value_from_powershell("CodeMeterProductCodes", True)
if matrox_pin_map_files is not None:
    print(matrox_pin_map_files)
    try:
        print(matrox_pin_map_files[0]['ProductCode'])
    except (IndexError, TypeError):
        print("The PowerShell output was not in the expected format.")
else:
    print('Nothing to print here')

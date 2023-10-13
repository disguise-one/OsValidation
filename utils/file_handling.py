import subprocess
import socket
import os

machine_name = socket.gethostname()


# Check that the System Failure checkboxes are checked (except "Disable Automatic Deletion of memory dumps")
def check_system_failure_checkboxes():
    result = subprocess.check_output(['powershell', 'Get-ItemPropertyValue -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\CrashControl" -Name "CrashDumpEnabled"']).strip().decode('utf-8')
    if result != '1':
        print("| C62841 | System Failure checkboxes not checked")
    else:
        print("| C62841 | System Failure checkboxes checked")


# Check that the Dump file path field shows "%SystemRoot%\MEMORY.DMP"
def check_dump_file_path():
    result = subprocess.check_output(['powershell', 'Get-ItemPropertyValue -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\CrashControl" -Name "DumpFile"']).strip().decode('utf-8')
    if result != '%SystemRoot%\\MEMORY.DMP':
        print("| C62841 | Dump file path incorrect")
    else:
        print("| C62841 | Dump file path correct")


def check_file():
    machine_name = os.environ['COMPUTERNAME']
    filename = f"{machine_name}_POSTBOOT_time.txt"
    path = os.path.join("C:", "Windows", "logs", filename)
    if os.path.isfile(path):
        try:
            with open(path, "r") as f:
                print(f.read())
            return True
        except FileNotFoundError:
            print(f"| C62843 | File not found: {path}")
            return False
        except PermissionError:
            print(f"| C62843 | Permission error: {path}")
            return False
        except Exception as e:
            print(f"| C62843 | Error opening file {path}: {e}")
            return False
    else:
        print(f"| C62843 | File not found: {path}")
        return False

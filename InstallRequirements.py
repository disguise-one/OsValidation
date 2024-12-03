import pip
import subprocess
import sys

def import_or_install(path):
    print("Checking required packages are installed...")
    requirementsFile = open(path, "r")
    requirementsContents = requirementsFile.read().strip().split()
    for requirement in requirementsContents:
        try:
            print("====================================================")
            print("Attempting to import: [" + requirement + "]")
            __import__(requirement)
            print("Success!")
            print("====================================================")
        except ImportError as e:
            print("Importing [" + requirement + "] failed indicating it is not installed. Attempting to install module")
            try:
                # pip.main(['install', requirement])   
                subprocess.check_call([sys.executable, "-m", "pip", "install", requirement])
                print("====================================================")
            except:
                print("Failure. Please install package: [" + requirement + "] manually using command line comand: ")
                print()
                print("---")
                print(">> py -m pip install " + requirement)
                print("---")
                print()
                print("Or if multiple package installations have failed, please use the command: ")
                print("---")
                print(">> py -m pip install -r ./path/to/requirements.txt")
                print("---")
                print("====================================================")
    print("Finished package checking.")

import_or_install("requirements.txt")
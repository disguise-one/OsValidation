import os
import logging
import logging.handlers
from colorlog import ColoredFormatter

# # Define the directory for the logs relative to the current file
# log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')

# # Create the logs directory if it does not exist
# if not os.path.exists(log_dir):
#     os.makedirs(log_dir)

# # Define the path for the log file within the logs directory
# log_file = os.path.join(log_dir, 'os_test_run.log')

# # Create a logger object
# logger = logging.getLogger()
# logger.setLevel(logging.DEBUG)

# # Create a handler for rotating log files
# file_handler = logging.handlers.RotatingFileHandler(log_file, maxBytes=100000, backupCount=5)
# file_handler.setLevel(logging.DEBUG)

# # Create a console handler with color output
# console_handler = logging.StreamHandler()
# console_handler.setLevel(logging.DEBUG)

# # Create formatters and set them for handlers
# file_formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
# console_formatter = ColoredFormatter(
#     '%(log_color)s%(asctime)s | %(levelname)s | %(message)s%(reset)s',
#     datefmt='%Y-%m-%d %H:%M:%S',
#     log_colors={
#         'DEBUG':    'cyan',
#         'INFO':     'green',
#         'WARNING':  'yellow',
#         'ERROR':    'red',
#         'CRITICAL': 'red,bg_white',
#     }
# )

# file_handler.setFormatter(file_formatter)
# console_handler.setFormatter(console_formatter)

# # Add handlers to the logger
# logger.addHandler(file_handler)
# logger.addHandler(console_handler)

# def change_log_path(newPath):
#     print(f"Changing logging path to [{newPath}]")

#     if os.path.exists(newPath):
#         print(f"Cannot change path to [{newPath}] as a file already exists in that location")
#         return False

#     # we go to the log 
#     logger = logging.getLogger()
#     logger
#     f = open("demofile.txt", "r")



class bespokeLogging:
    log_dir = None
    file_handler = None
    console_handler = None
    file_formatter = None
    log_file = None

    logger = logging.getLogger()
    console_formatter = ColoredFormatter(
        '%(log_color)s%(asctime)s | %(levelname)s | %(message)s%(reset)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        log_colors={
            'DEBUG':    'cyan',
            'INFO':     'green',
            'WARNING':  'yellow',
            'ERROR':    'red',
            'CRITICAL': 'red,bg_white',
        }
    )

    def __init__(self, path, fileName):
        if not path:
            # Define the directory for the logs relative to the current file -> default method
            self.log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
        else:
            self.log_dir = path

        # Create the logs directory if it does not exist
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir)

        # Define the path for the log file within the logs directory
        if not fileName:
            self.log_file = os.path.join(self.log_dir, 'os_test_run.log')
        else:
            self.log_file = os.path.join(self.log_dir, fileName)

        print(f"Creating logging object with path: [{path}] called [{fileName}]...")

        # Create a logger object
        self.logger.setLevel(logging.DEBUG)

        # Create a handler for rotating log files
        self.file_handler = logging.FileHandler(self.log_file)
        self.file_handler.setLevel(logging.DEBUG)

        # Create a console handler with color output
        self.console_handler = logging.StreamHandler()
        self.console_handler.setLevel(logging.DEBUG)

        # Create formatters and set them for handlers
        self.file_formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

        self.file_handler.setFormatter(self.file_formatter)
        self.console_handler.setFormatter(self.console_formatter)

        # Add handlers to the logger
        self.logger.addHandler(self.file_handler)
        self.logger.addHandler(self.console_handler)


    def change_log_path(self, newPath):
        print(f"Changing logging path to [{newPath}]")
        if os.path.exists(newPath):
            print(f"Cannot change path to [{newPath}] as a file already exists in that location")
            return False

        # We need to make a new handler and then
        # we need to strip the handler from the logging object
        # And add the new one
        tempHandler = logging.FileHandler(newPath)
        tempHandler.setLevel(logging.DEBUG)
        tempHandler.setFormatter(self.file_formatter)

        # Close the file
        self.file_handler.close()

        # we go to the log 
        try:
            try:
                logFile = open(self.log_file, "r")
            except Exception as error:
                print(f"Cannot open log file [{self.log_file}]. Log file directory change aborted.")
                print(str(error))

            # Get the content of the log file
            try:
                content = logFile.read()
            except Exception as error:
                print(f"Cannot read log file [{self.log_file}]. Log file directory change aborted.")
                print(str(error))

        except Exception as error:
            print(f"Something went wrong")
            print(str(error))
        
        finally:
            logFile.close()


        try:
            try:
                NewLogFile = open(newPath, "w")
            except Exception as error:
                print(f"Cannot open new log file [{newPath}].")
                print(str(error))

            # Get the content of the log file
            try:
                if not content:
                    print("Cannot write old content to new file")
                else:
                    NewLogFile.write(content)
            except Exception as error:
                print(f"Cannot write old file contents to new log file [{newPath}]")
                print(str(error))

        except Exception as error:
            print(f"Something went wrong")
            print(str(error))
        
        finally:
            NewLogFile.close()

        self.log_file = newPath

        # remove the handler
        self.logger.removeHandler(self.file_handler)

        # Set the self handler to be the temporary handler
        self.file_handler = tempHandler
        
        # Set the new handler
        self.logger.addHandler(self.file_handler)

        

        



            



        
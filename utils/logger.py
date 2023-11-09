import os
import logging
import logging.handlers
from colorlog import ColoredFormatter

# Define the directory for the logs relative to the current file
log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')

# Create the logs directory if it does not exist
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# Define the path for the log file within the logs directory
log_file = os.path.join(log_dir, 'os_test_run.log')

# Create a logger object
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# Create a handler for rotating log files
file_handler = logging.handlers.RotatingFileHandler(log_file, maxBytes=100000, backupCount=5)
file_handler.setLevel(logging.DEBUG)

# Create a console handler with color output
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)

# Create formatters and set them for handlers
file_formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
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

file_handler.setFormatter(file_formatter)
console_handler.setFormatter(console_formatter)

# Add handlers to the logger
logger.addHandler(file_handler)
logger.addHandler(console_handler)


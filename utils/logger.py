import logging.handlers

# Logger setup
log_file = "D:\\code\\OsValidation\\logs\\os_test_run.log"
logging.basicConfig(level=logging.DEBUG, format='| %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
handler = logging.handlers.RotatingFileHandler(log_file, maxBytes=100000, backupCount=5)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
handler.setFormatter(formatter)
logging.getLogger('').addHandler(handler)


def log_and_print(message, level="info"):
    """Logs and prints a message."""
    getattr(logging, level)(message)
    # print(f"| {level.upper()} | {message}")

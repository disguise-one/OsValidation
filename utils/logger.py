import logging
import logging.handlers

# Set up logging
log_file = "C:\\Users\\d3\\PycharmProjects\\os_check_test\\logs\\os_test_run.log"
logging.basicConfig(level=logging.DEBUG, format='| %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
handler = logging.handlers.RotatingFileHandler(log_file, maxBytes=100000, backupCount=5)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
handler.setFormatter(formatter)
logging.getLogger('').addHandler(handler)
logging.shutdown()

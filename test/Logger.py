import datetime, sys

class Logger:
    GREEN   = '\033[92m'
    YELLOW  = '\033[93m'
    RED     = '\033[91m'
    ENDC    = '\033[0m'

    date_format = "%Y/%m/%d %H:%M:%S"

    @staticmethod
    def info(message):
        print(datetime.datetime.now().strftime(Logger.date_format) + " - [" + Logger.GREEN + "INFO" + Logger.ENDC + "]: " + message)

    @staticmethod
    def warn(message):
        print(datetime.datetime.now().strftime(Logger.date_format) + " - [" + Logger.YELLOW + "WARN" + Logger.ENDC + "]: " + message, file=sys.stderr)

    @staticmethod
    def error(message):
        print(datetime.datetime.now().strftime(Logger.date_format) + " - [" + Logger.RED + "ERROR" + Logger.ENDC + "]: " + message, file=sys.stderr)

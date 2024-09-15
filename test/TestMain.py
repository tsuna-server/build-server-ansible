import sys, os, re, socket, unittest
from Config import Config
from glob import glob
from Logger import Logger

class TestMain():

    def __init__(self):
        self.regex_extention_py = re.compile(r"\.py$")

    def run_test_suite(self):
        os.environ["HOSTSPEC_URI"]          = "local://"
        os.environ["PATH_GROUP_VARS_ALL"]   = "../group_vars/all"
        os.environ["PATH_PREFIX_HOST_VARS"] = "../host_vars/"

        hostname = socket.gethostname()
        if re.match('^.*controller[0-9]+$', hostname) != None:
            f_glob_pattern = "cases/**/TestController*.py"
        elif re.match('^.*compute[0-9]+$', hostname) != None:
            f_glob_pattern = "cases/**/TestCompute*.py"
        elif re.match('^.*storage[0-9]+$', hostname) != None:
            f_glob_pattern = "cases/**/TestStorage*.py"
        else:
            print("Nothing to test for the host \"" + hostname + "\".")
            print("It supports hostnames like ^(.*controller[0-9]+|.*compute[0-9]+|.*compute[0-9]+))$.")
            return 0

        suite = unittest.TestSuite()
        for filename in glob(f_glob_pattern, recursive=True):
            Logger.info("Added a test suite \"" + filename + "\"")
            suite.addTests(unittest.TestLoader().loadTestsFromTestCase(self.convert_to_components(filename)))

        print()

        runner = unittest.TextTestRunner(verbosity=2)
        result = runner.run(suite)
        return int(not result.wasSuccessful())

    def convert_to_components(self, filename):
        path_file_without_ext = self.regex_extention_py.sub("", filename)

        splitted_path = path_file_without_ext.split("/")
        mod = __import__(".".join(splitted_path))

        for comp in (splitted_path[1:] + [splitted_path[-1]]):
            mod = getattr(mod, comp)

        return mod

if __name__ == "__main__":
    ret = TestMain().run_test_suite()
    sys.exit(ret)


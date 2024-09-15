from Logger import Logger
import os, yaml, unittest, testinfra

class TestBase(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        Logger.info("Started cases of test in " + cls.__name__ + ".")

        # "cls" here indicates that the subclass of TestBase. Not the TestBase itself.
        cls.host            = testinfra.get_host(os.environ["HOSTSPEC_URI"])
        cls.hostname        = cls.host.check_output('hostname -s')

        if hasattr(cls, "group_vars_all") == False:
            with open(yaml.safe_load(os.environ["PATH_GROUP_VARS_ALL"]), 'r') as f:
                cls.group_vars_all  = yaml.safe_load(f)

        if hasattr(cls, "host_vars") == False:
            with open(os.path.join(os.environ["PATH_PREFIX_HOST_VARS"], cls.hostname) + ".yml", 'r') as f:
                cls.host_vars       = yaml.safe_load(f)


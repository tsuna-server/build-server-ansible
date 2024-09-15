import yaml

class Config:
    #def __init__(self, path_of_group_vars_all):
    #    with open(path_of_group_vars_all, 'r') as yml:
    #        self.group_vars_all = yaml.safe_load(yml)

    def get_hello(self):
        return "Hello World"

    #def get_group_vars_all(self):
    #    return self.group_vars_all


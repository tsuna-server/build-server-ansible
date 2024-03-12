#!/usr/bin/env python

class FilterModule(object):
    def filters(self):
        return {
            'pretty_yaml': self.pretty_yaml,
        }

    def pretry_yaml(self, d, indent=0, result=""):
        for key, value in d.items():
            result += " " * indent + str(key)
            if isinstance(value, dict):
                result = self.pretty(value, indent=(indent + 2), result=result + ":\n")
            else:
                result += ": " + str(value) + "\n"
        return result

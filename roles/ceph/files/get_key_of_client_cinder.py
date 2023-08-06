#!/usr/bin/env python3
import configparser

def main():
    config = configparser.ConfigParser()
    config.read('/etc/ceph/ceph.client.cinder.keyring')
    result_key = config['client.cinder']['key']
    print(result_key)

if __name__ == "__main__":
    main()


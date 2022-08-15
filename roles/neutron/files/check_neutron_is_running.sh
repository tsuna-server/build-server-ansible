#!/usr/bin/env bash

main() {
    local max_attempts=5
    local return_code index

    export PYTHONWARNINGS="ignore"

    for index in $(seq 0 $((max_attempts - 1))); do
        # Attempting 5 times max
        openstack network list
        return_code=$?
        [ $return_code -eq 0 ] && {
            echo "INFO: Neutron is running correctory."
            return 0
        }

        [ $index -ge $(( max_attempts - 1 )) ] && {
            echo "ERROR: A Neutron is NOT running or running inappropriately" >&2
            return 1
        }
        echo "WARNING: A Neutron is NOT running or running inappropriately. Checking will be re-attempting" >&2
        restart_daemons
    done
}

restart_daemons() {
    echo "INFO: Restarting daemons."
    systemctl restart ovsdb-server ovn-ovsdb-server-nb ovn-ovsdb-server-sb neutron-server openvswitch-switch
    sleep 10
}

main "$@"

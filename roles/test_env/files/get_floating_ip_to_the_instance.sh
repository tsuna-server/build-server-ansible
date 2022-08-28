#!/usr/bin/env bash

# This script will create and add floating IP to a instance.
# It will add floating IP only when the instance has 1 IP adress.
# It will NOT add floating IP if the instance has equals or more than 2 IPs.
#
# Output of result
#   Floating IP address that is not used now. It means the floating IP cann attach an instance.
#
# Return code
#   0: Success and this script output new floating IP
#   1: Floating IP is already added at the instance.
#   2: Error
main() {
    local network="$1"
    local instance_id="$2"
    local ret num_of_addresses unused_ip

    export PYTHONWARNINGS="ignore"

    if [ -z "$network" ] || [ -z "$instance_id" ]; then
        echo "Usage: $0 <network>" >&2
        exit 2
    fi

    num_of_addresses=$(jq '.addresses | map(.[]) | length' < <(openstack server show ${instance_id} --format json))
    ret=$?

    if [ $ret -ne 0 ] || [[ ! "$num_of_addresses" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Failed to get number of IP addresses. A command \"openstack server show ${instance_id} --format json\" might be failed." >&2
        exit 2
    fi

    if [ $num_of_addresses -ge 2 ]; then
        # You do NOT have to add a floating IP.
        exit 1
    fi

    unused_ip=$(search_unused_floating_ip "$network")

    if [ -z "$unused_ip" ] || [ "$unused_ip" = null ]; then
        # Creat new floating IP
        unused_ip=$(create_new_floating_ip "$network")
    fi

    [[ ! "$unused_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && {
        echo "ERROR: A format of an unused IP address is wrong. It might be failed to the command \"openstack floating ip list --network ${network} --format json --long\"."
        exit 2
    }

    echo $unused_ip
}

search_unused_floating_ip() {
    local network="$1"
    local unused_floating_ip ret

    unused_floating_ip=$(jq -r '[.[] | select(.Status == "DOWN") | .["Floating IP Address"]][0]' < <(openstack floating ip list --network ${network} --format json --long)) || {
        echo "ERROR: Failed to convert JSON of \"openstack floating ip list --network ${network} --format json --long\"." >&2
        exit 2
    }

    echo ${unused_floating_ip}
}

create_new_floating_ip() {
    local network="$1"
    local new_floating_ip ret

    new_floating_ip=$(jq -r '.floating_ip_address' < <(openstack floating ip create ${network} --format json)) || {
        echo "ERROR: Failed to create floating IP for some reason with a command \"openstack floating ip create ${network} --format json\"." >&2
        exit 2
    }

    echo $new_floating_ip
}

main "$@"

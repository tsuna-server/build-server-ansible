#!/usr/bin/env bash

main() {
    local network_name="$1"
    local return_code network_id

    if [[ ! "$network_name" =~ ^[a-zA-Z_0-9]+$ ]]; then
        echo "ERROR: A acript \"$0\" does not support a network_name \"${network_name}\"." >&2
        return 1
    fi

    network_id=$(jq -r '.[0].ID' <<< $(openstack network list --name "${network_name}" --format json))
    return_code=$?
    if [ "$return_code" -ne 0 ]; then
        echo "ERROR: Failed to execute a command \"openstack network list\" or failed to parse a result of it." >&2
        return 1
    fi

    echo "${network_id}"

    return 0
}

main "$@"

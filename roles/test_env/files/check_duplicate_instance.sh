#!/usr/bin/env bash

# @return 1:
#     An instance is already registered.
# @return 0:
#     An instance is NOT registered.
main() {
    local target_instance_name="$1"
    local output instance_name return_code

    if [[ -z "$target_instance_name" ]]; then
        echo "Usage: $0 <target_instance_name>" >&2
        return 2
    fi

    output=$(jq "[ .[] | select(.Name == \"${target_instance_name}\") | . ] | length" <<< "$(openstack server list --format json)")
    return_code=$?
    [ $return_code -ne 0 ] && {
        echo "ERROR: Failed to parse JSON with jq command." >&2
        return 2
    }

    [[ ! "$output" =~ ^[0-9]+$ ]] && {
        echo "ERROR: Failed to get num of instances." >&2
        return 2
    }

    [ $output -gt 0 ] || {
        echo "INFO: An instance \"${target_instance_name}\" was already registered."
        return 1
    }

    # An instance is NOT registerd
    return 0
}

main "$@"

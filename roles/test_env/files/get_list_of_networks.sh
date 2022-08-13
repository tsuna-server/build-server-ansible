#!/usr/bin/env bash

main() {
    local network_id return_code
    declare -a network_id_list
    declare -a network_names_for_rbac

    network_id_list=($(jq -r '.[].Name' <<< $(openstack network list --format json)))
    return_code=$?
    [ $return_code -ne 0 ] && {
        echo "ERROR: Failed to get list of network with a command \"openstack network list\"." >&2
        return 1
    }

    for network_id in "${network_id_list[@]}"; do
        network_name=$(jq -r 'select(.["router:external"] == false) | .name' <<< openstack network show --format json "${network_id}")
        if [ ! -z "${network_name}" ]; then
            network_names_for_rbac+=("${network_name}")
        fi
    done

    [ ${#network_names_for_rbac[@]} -eq 0 ] && return 0

    printf '%s\n' "${network_names_for_rbac[@]}"
}

main "$@"

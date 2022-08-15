#!/usr/bin/env bash

main() {
    local project_id="$1"
    local network_id="$2"
    local return_code

    openstack network rbac create --target-project "${project_network}" --type network --action access_as_shared "${network_id}"
    return_code=$?
    [ $return_code -ne 0 ] && {
        echo "ERROR: Failed to create RBAC with the command \"openstack network rbac create\"." >&2
        return 1
    }

    return 0
}

main "$@"

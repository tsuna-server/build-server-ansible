#!/usr/bin/env bash

main() {
    local project_name="$1"
    local return_code project_id

    # TODO: Suppress warnings of the command "openstack".
    export PYTHONWARNINGS="ignore"

    if [[ ! "$project_name" =~ ^[a-zA-Z_0-9]+$ ]]; then
        echo "ERROR: A acript \"$0\" does not support a project_name \"${network_name}\"." >&2
        return 1
    fi

    project_id=$(jq -r ".[] | select(.Name == \"${project_name}\") | .ID" <<< $(openstack project list --name "${project_name}" --format json))
    return_code=$?
    [ $return_code -ne 0 ] && {
        echo "ERROR: Failed to run openstack project list" >&2
        return 1
    }

    return 0
}

main "$@"

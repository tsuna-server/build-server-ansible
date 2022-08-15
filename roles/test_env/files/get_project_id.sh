#!/usr/bin/env bash

main() {
    local domain_name="$1"
    local project_name="$2"
    local return_code project_id

    # TODO: Suppress warnings of the command "openstack".
    export PYTHONWARNINGS="ignore"

    [[ ! "$domain_name" =~ ^[a-zA-Z_0-9]+$ ]] && {
        echo "ERROR: A acript \"$0\" does not support a domain_name \"${domain_name}\"." >&2
        return 1
    }

    [[ ! "$project_name" =~ ^[a-zA-Z_0-9]+$ ]] && {
        echo "ERROR: A acript \"$0\" does not support a project_name \"${project_name}\"." >&2
        return 1
    }

    project_id=$(jq -r ".[] | select(.Name == \"${project_name}\") | .ID" <<< $(openstack project list --domain "${domain_name}" --format json))
    return_code=$?
    [ $return_code -ne 0 ] && {
        echo "ERROR: Failed to run openstack project list" >&2
        return 1
    }

    echo "${project_id}"

    return 0
}

main "$@"

#!/usr/bin/env bash

main() {
    local target_security_group_name="$1"
    local target_project="$2"
    local id name project_id target_project_id

    # PROJECT_LIST_CACHE_FILE

    [[ -z "$target_security_group_name" ]] && {
        echo "Usage: $0 <target_security_group_name>"
        return 2
    }
    [[ -z ${PROJECT_LIST_CACHE_FILE} ]] && {
        echo "ERROR: This script requires environment variable \"PROJECT_LIST_CACHE_FILE\" to load where the cache file is in." >&2
        return 2
    }

    # Load a cache of security ID map list.
    source "/tmp/${PROJECT_LIST_CACHE_FILE}"
    [[ "$(declare -p CACHE_OF_PROJECT_LIST 2> /dev/null)" ]] || {
        echo "ERROR: Failed to load variable \"CACHE_OF_PROJECT_LIST\" from the file \"/tmp/${PROJECT_LIST_CACHE_FILE}\"" >&2
        return 2
    }

    # Example output.
    # +--------------------------------------+----------------+------------------------+----------------------------------+------+
    # | ID                                   | Name           | Description            | Project                          | Tags |
    # +--------------------------------------+----------------+------------------------+----------------------------------+------+
    # | ffffffff-ffff-ffff-ffff-ffffffffffff | default        | Default security group |                                  | []   |
    # | eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee | default        | Default security group | ffffffffffffffffffffffffffffffff | []   |
    # | dddddddd-dddd-dddd-dddd-dddddddddddd | permit_all     | Allow all ports        | ffffffffffffffffffffffffffffffff | []   |
    # | cccccccc-cccc-cccc-cccc-cccccccccccc | default        | Default security group | eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee | []   |
    # | bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb | limited_access | Allow base ports       | ffffffffffffffffffffffffffffffff | []   |
    # +--------------------------------------+----------------+------------------------+----------------------------------+------+

    # Get project ID from project name
    target_project_id="${CACHE_OF_PROJECT_LIST[${target_project}]}"
    if [[ -z "$target_project_id" ]]; then
        echo "ERROR: Failed to get project ID from a cache of project list. Please confirm the project is already registerd in your openstack environment by running a command \"openstack project list\"" >&2
        return 2
    fi

    echo "Target project ID is: $target_project_id"

    output="$(openstack security group list)" || {
        echo "ERROR: Failed to get Neutron router" >&2
        return 2
    }

    while read id _ name _ project_id; do
        id="${id%\\n}"
        name="${name%\\n}"
        project_id="${project_id%\\n}"
        echo "security_group_name=${name}, security_group_id=${id}, project_id=${project_id}"
        if [[ "$name" == "$target_security_group_name" ]] && [[ "$project_id" == "$target_project_id" ]]; then
            return 1
        fi
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 2,3,5)

    return 0
}

main "$@"

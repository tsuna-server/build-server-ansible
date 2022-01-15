#!/usr/bin/env bash

main() {

    local id name output
    local cache_file="/tmp/${PROJECT_LIST_CACHE_FILE}"
    # Example output:
    # +----------------------------------+-----------+
    # | ID                               | Name      |
    # +----------------------------------+-----------+
    # | ffffffffffffffffffffffffffffffff | admin     |
    # | eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee | myproject |
    # | dddddddddddddddddddddddddddddddd | service   |
    # +----------------------------------+-----------+
    output="$(openstack project list)" || {
        echo "ERROR: Failed to get project list with a command \"openstack project list\"" >&2
        return 2
    }

    # FIXME: There is a security risk to remove a file by using variable without any checks
    rm -f "/tmp/${PROJECT_LIST_CACHE_FILE}"

    echo -n "declare -A CACHE_OF_PROJECT_LIST=(" >> "${cache_file}"
    while read id _ name; do
        id="${id%\\n}"
        name="${name%\\n}"
        echo -n "[${name}]=${id} " >> "${cache_file}"
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 2,3)
    echo ")" >> "${cache_file}"

    return 0
}

main "$@"

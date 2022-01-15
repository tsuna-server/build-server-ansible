#!/usr/bin/env bash

main() {
    if [[ -z "$SESSION_ID" ]]; then
        echo "ERROR: Failed to create a cache file of project-list due to undefined of an environment variable \"SESSION_ID\". It is empty." >&2
        return 2
    fi

    local id name output
    local cache_file="/tmp/${PREFIX_PROJECT_LIST_FILE}${SESSION_ID}"
    # Example output:
    # +----------------------------------+-----------+
    # | ID                               | Name      |
    # +----------------------------------+-----------+
    # | ffffffffffffffffffffffffffffffff | admin     |
    # | eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee | myproject |
    # | dddddddddddddddddddddddddddddddd | service   |
    # +----------------------------------+-----------+
    output="$(openstack project list)"

    # FIXME: There is a security risk to remove a file by using variable without any checks
    rm -f "/tmp/${PREFIX_PROJECT_LIST_FILE}"*

    echo -n "declare -A CACHE_OF_PROJECT_LIST=(" >> "${cache_file}"
    while read id _ name; do
        id="${id%\\n}"
        name="${name%\\n}"
        echo -n "[${name}]=${id} " >> "${cache_file}"
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 2,3)
    echo ")" >> "${cache_file}"
}

main "$@"

#!/usr/bin/env bash

main() {
    local target_subnet_name="$1"

    local output subnet_name

    if [[ -z "$target_subnet_name" ]]; then
        echo "Usage: $0 <subnet_name>" >&2
        return 2
    fi

    output="$(openstack subnet list)" || {
        echo "ERROR: Failed to get subnet list" >&2
        return 2
    }

    # # Sample output
    # +--------------------------------------+---------------+--------------------------------------+----------------+
    # | ID                                   | Name          | Network                              | Subnet         |
    # +--------------------------------------+---------------+--------------------------------------+----------------+
    # | ffffffff-ffff-ffff-ffff-ffffffffffff | <subnet_name> | eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee | 192.168.1.0/24 |
    # +--------------------------------------+---------------+--------------------------------------+----------------+
    while IFS="|" read -r subnet_name; do
        subnet_name="$(trim "$subnet_name")"

        if [[ "$subnet_name" == "$target_subnet_name" ]]; then
            # The network has already existed
            return 1
        fi
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

main "$@"

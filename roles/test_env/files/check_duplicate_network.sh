#!/usr/bin/env bash

main() {
    local target_network_name="$1"
    local mtu="$2"

    local output network_name

    if [[ -z "$target_network_name" ]]; then
        echo "Usage: $0 <network_name>" >&2
        return 2
    fi

    output="$(openstack network list)" || {
        echo "ERROR: Failed to get network list" >&2
        return 2
    }

    # Example output
    # +--------------------------------------+---------+---------+
    # | ID                                   | Name    | Subnets |
    # +--------------------------------------+---------+---------+
    # | ffffffff-ffff-ffff-ffff-ffffffffffff | foo     |         |
    # +--------------------------------------+---------+---------+

    while IFS="|" read -r network_name; do
        network_name="$(trim "$network_name")"

        if [[ "$network_name" == "$target_network_name" ]]; then
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

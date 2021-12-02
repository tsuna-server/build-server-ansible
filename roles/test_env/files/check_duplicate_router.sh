#!/usr/bin/env bash
#
# This script validates whether the Neutron router is already existed or not
#   return 1: The Neutron router was already existed
#   return 0: The Neutron router was NOT existed
#

main() {
    local target_router_name="$1"
    local router_name

    [[ -z "$target_router_name" ]] && {
        echo "Usage: $0 <target_router_name>"
        return 2
    }

    output="$(glance router list)" || {
        echo "ERROR: Failed to get Neutron router" >&2
        return 2
    }

    # # Sample output
    # +--------------------------------------+---------------+--------+-------+----------------------------------+-------------+-------+
    # | ID                                   | Name          | Status | State | Project                          | Distributed | HA    |
    # +--------------------------------------+---------------+--------+-------+----------------------------------+-------------+-------+
    # | ffffffff-ffff-ffff-ffff-ffffffffffff | <router name> | ACTIVE | UP    | ffffffffffffffffffffffffffffffff | False       | False |
    # +--------------------------------------+---------------+--------+-------+----------------------------------+-------------+-------+
    while read router_name; do
        router_name="${router_name%\\n}"
        [[ "$router_name" == "${target_router_name}" ]] && return 1
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

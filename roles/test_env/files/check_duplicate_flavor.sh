#!/usr/bin/env bash
#
# This script validates whether the Neutron flavor is already existed or not
#   return 1: The Neutron flavor was already existed
#   return 0: The Neutron flavor was NOT existed
#

main() {
    local target_flavor_name="$1"
    local flavor_name

    [[ -z "$target_flavor_name" ]] && {
        echo "Usage: $0 <target_flavor_name>"
        return 2
    }

    output="$(openstack flavor list)" || {
        echo "ERROR: Failed to get Neutron flavor" >&2
        return 2
    }

    # # Sample output
    # +----+---------+-----+------+-----------+-------+-----------+
    # | ID | Name    | RAM | Disk | Ephemeral | VCPUs | Is Public |
    # +----+---------+-----+------+-----------+-------+-----------+
    # | 1  | m1.tiny | 512 |    1 |         0 |     1 | True      |
    # +----+---------+-----+------+-----------+-------+-----------+
    while read flavor_name; do
        flavor_name="${flavor_name%\\n}"
        [[ "$flavor_name" == "${target_flavor_name}" ]] && return 1
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"


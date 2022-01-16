#!/usr/bin/env bash

main() {
    local target_instance_name="$1"
    local output instance_name

    if [[ -z "$target_instance_name" ]]; then
        echo "Usage: $0 <target_instance_name>" >&2
        return 2
    fi

    output="$(openstack server list)" || {
        echo "ERROR: Failed to get instance list with command \"openstack server list\"." >&2
        return 2
    }

    # Example output.
    # +--------------------------------------+----------+--------+-----------------------+--------------+---------+
    # | ID                                   | Name     | Status | Networks              | Image        | Flavor  |
    # +--------------------------------------+----------+--------+-----------------------+--------------+---------+
    # | ffffffff-ffff-ffff-ffff-ffffffffffff | mycirros | ACTIVE | private=192.168.x.x   | Cirros-0.4.0 | m1.tiny |
    # +--------------------------------------+----------+--------+-----------------------+--------------+---------+
    while read instance_name _; do
        instance_name="${instance_name%\\n}"
        if [[ "$target_instance_name" == "$instance_name" ]]; then
            return 1
        fi
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

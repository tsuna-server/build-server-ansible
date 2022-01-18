#!/usr/bin/env bash

main() {
    local target_ssh_key_name="$1"
    local output ssh_key_name

    if [[ -z "$target_ssh_key_name" ]]; then
        echo "Usage: $0 <target_ssh_key_name>" >&2
        return 2
    fi

    output="$(openstack keypair list)" || {
        echo "ERROR: Failed to get keypair list with command \"openstack keypair list\"." >&2
        return 2
    }

    # Example output.
    # +-------+-------------------------------------------------+------+
    # | Name  | Fingerprint                                     | Type |
    # +-------+-------------------------------------------------+------+
    # | admin | ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff | ssh  |
    # +-------+-------------------------------------------------+------+
    while read ssh_key_name _; do
        ssh_key_name="${ssh_key_name%\\n}"
        if [[ "$target_ssh_key_name" == "$ssh_key_name" ]]; then
            return 1
        fi
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 2)

    return 0
}

main "$@"

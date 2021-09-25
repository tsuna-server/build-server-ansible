#!/usr/bin/env bash
#
# This script validates whether the role is already created or not.
#   return 1: The role was already created
#   return 0; The role was NOT already created

main() {
    local target_role="$1"
    local role output

    [[ -z "$target_role" ]] && return 2

    output="$(openstack role list)" || {
        echo "ERROR: Failed to get role list" >&2
        return 2
    }

    while read role; do
        line="${role%\\n}"
        [[ "${role^^}" == "${target_role^^}" ]] && return 1
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

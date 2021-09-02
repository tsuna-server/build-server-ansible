#!/usr/bin/env bash
#
# This script validates whether the role is already created or not.
#   return 1: The role was already created
#   return 0; The role was NOT already created

main() {
    local target_role="$1"
    local role

    [[ -z "$target_role" ]] && return 2

    while read role; do
        line="${role%\\n}"
        [[ "${role^^}" == "${target_role^^}" ]] && return 1
    done < <(openstack role list | tail +4 | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

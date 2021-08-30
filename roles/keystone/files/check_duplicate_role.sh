#!/usr/bin/env bash
#
# This script validates whether the domain is already existed or not.
#   return 1: The domain was already existed
#   return 0; The domain was NOT existed

main() {
    local target_role="$1"
    local role

    [[ -z "$target_role" ]] && return 2

    while read role; do
        # Chomp white spaces
        role="${role%\\n}"
        [[ "${role^^}" == "${target_role^^}" ]] && return 1
    done < <(openstack role list | tail +4 | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

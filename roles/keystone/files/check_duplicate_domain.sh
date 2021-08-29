#!/usr/bin/env bash
#
# This script validates whether the domain is already existed or not.
#   return 1: The domain was already existed
#   return 0; The domain was NOT existed

main() {
    local target_domain="$1"
    local line

    [[ -z "$target_domain" ]] && return 2

    while read line; do
        [[ "${line%\\n}" == "$target_domain" ]] && return 1
    done < <(openstack domain list | tail +4 | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

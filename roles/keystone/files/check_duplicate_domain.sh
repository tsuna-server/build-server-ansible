#!/usr/bin/env bash
#
# This script validates whether the domain is already existed or not.
#   return 1: The domain was already existed
#   return 0; The domain was NOT existed

main() {
    local target_domain="$1"
    local line output

    [[ -z "$target_domain" ]] && return 2

    output="$(openstack domain list)" || {
        echo "ERROR: Failed to get image list from glance-api" >&2
        return 2
    }

    while read line; do
        # Chomp white spaces
        line="${line%\\n}"
        [[ "${line^^}" == "${target_domain^^}" ]] && return 1
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

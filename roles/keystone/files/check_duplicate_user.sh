#!/usr/bin/env bash
#
# This script validates whether the user is already existed in the domain or not.
# And this script assumes the domain was already existed.
#   return 1: The user was already existed
#   return 0; The user was NOT existed

main() {
    local target_domain="$1"
    local target_user="$2"
    local user domain output

    [[ -z "$target_domain" ]] && return 2
    [[ -z "$target_user" ]] && return 2

    output="$(openstack user list --domain $target_domain --long )" || {
        echo "ERROR: Failed to get user list" >&2
        return 2
    }

    while read user _ domain; do
        domain="${domain%\\n}"
        user="${user%\\n}"
        [[ "${domain^^}" == "${target_domain^^}" ]] && [[ ${user^^} == "${target_user^^}" ]] && return 1
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 3,5)

    return 0
}

main "$@"

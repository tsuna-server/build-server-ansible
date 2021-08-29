#!/usr/bin/env bash
#
# This script validates whether the project is already existed in the domain or not.
# And this script assumes the domain was already existed.
#   return 1: The project was already existed
#   return 0; The project was NOT existed

main() {
    local target_domain="$1"
    local target_project="$2"
    local project
    local domain

    [[ -z "$target_domain" ]] && return 2
    [[ -z "$target_domain" ]] && return 2

    while read project _ domain; do
        [[ "${domain%\\n}" == "$target_domain" ]] && [[ ${project%\\n} == "$target_project" ]] && return 1
    done < <(openstack project list --long --domain default | tail +4 | head -n -1 | cut -d '|' -f 3,4)

    return 0
}

main "$@"

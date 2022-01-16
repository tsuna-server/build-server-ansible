#!/usr/bin/env bash
#
# This script validates whether the project is already existed in the domain or not.
# And this script assumes the domain was already existed.
#   return 1: The project was already existed
#   return 0: The project was NOT existed

main() {
    local target_domain="$1"
    local target_project="$2"
    local project domain output

    [[ -z "$target_domain" ]] && return 2
    [[ -z "$target_project" ]] && return 2

    output="$(openstack project list --long --domain ${target_domain})" || {
        echo "ERROR: Failed to get project list" >&2
        return 2
    }

    # Example output:
    # +----------------------------------+-----------+-----------+-----------------------------------------------+---------+
    # | ID                               | Name      | Domain ID | Description                                   | Enabled |
    # +----------------------------------+-----------+-----------+-----------------------------------------------+---------+
    # | ffffffffffffffffffffffffffffffff | admin     | default   | Bootstrap project for initializing the cloud. | True    |
    # | eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee | myproject | default   | Demo Project                                  | True    |
    # | dddddddddddddddddddddddddddddddd | service   | default   | Service Project                               | True    |
    # +----------------------------------+-----------+-----------+-----------------------------------------------+---------+
    while read project _ domain; do
        domain="${domain%\\n}"
        project="${project%\\n}"
        [[ "${domain^^}" == "${target_domain^^}" ]] && [[ ${project^^} == "${target_project^^}" ]] && return 1
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 3,4)

    return 0
}

main "$@"

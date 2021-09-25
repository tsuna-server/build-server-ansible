#!/usr/bin/env bash
#
# This script validates whether the domain is already existed or not.
#   return 1: The domain was already existed
#   return 0; The domain was NOT existed

main() {
    local target_project="$1"
    local target_user="$2"
    local target_role="$3"
    local role user project output

    [[ -z "$target_project" ]] && return 2
    [[ -z "$target_user" ]] && return 2
    [[ -z "$target_role" ]] && return 2

    # Output sample
    #    [role] | [user]         | [project]
    # ----------------------------------------------------
    #    myrole | myuser@Default | myproject@Default
    #    admin  | admin@Default  | admin@Default
    #    admin  | admin@Default  |
    output="$(openstack role assignment list --name)" || {
        echo "ERROR: Failed to get role assignment list" >&2
        return 2
    }

    while read role _ user _ project ; do
        # Chomp white spaces
        project="$(cut -d '@' -f 1 <<< ${project%\\n})"
        user="$(cut -d '@' -f 1 <<< ${user%\\n})"
        role="${role%\\n}"
        [[ "${project^^}" == "${target_project^^}" ]] && [[ "${user^^}" == "${target_user^^}" ]] && [[ "${role^^}" == "${target_role^^}" ]] && return 1
    done < <(tail +4 <<< "$output" | head -n -1 | cut -d '|' -f 2,3,5)

    return 0
}

main "$@"

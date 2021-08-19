#!/usr/bin/env bash

main() {
    local target_user="$1"

    [[ -z "$target_user" ]] && return 1

    while read user; do
        [[ "$target_user" == "$user" ]] && return 0
    done < <(rabbitmqctl list_users | tail +2 | awk '{print $1}')

    return 1
}

main "$@"

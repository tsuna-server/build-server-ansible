#!/usr/bin/env bash
#
# This script validates whether the OpenStack service is already existed or not.
#   return 1: The service was already existed
#   return 0: The service was NOT existed

main() {
    local target_service_name="$1"
    local target_service_type="$2"
    local output service_name service_type

    if [[ -z "$target_service_name" ]] || [[ -z "$target_service_type" ]]; then
        echo "Usage: $0 <service_name> <service_type>"
        return 2
    fi

    # +----------------------------------+-----------+-----------+
    # | ID                               | Name      | Type      |
    # +----------------------------------+-----------+-----------+
    # | 03985ef8998c4aa1b69dfd60dc794d06 | keystone  | identity  |
    # | 2c0a3ed790a3475d943b0acfbec16196 | placement | placement |
    # | cedfeebf6d5245109b79bf7badeb9858 | glance    | image     |
    # +----------------------------------+-----------+-----------+
    output="$(openstack service list)" || {
        echo "ERROR: Failed to get service list" >&2
        return 2
    }

    while read service_name _ service_type _; do
        service_name="${service_name%\\n}"
        service_type="${service_type%\\n}"
        #echo "service_name=\"${service_name}\", service_type=\"${service_type}\""

        if [[ "$service_name" == "$target_service_name" ]] \
                && [[ "$service_type" == "$target_service_type" ]]; then
            echo "INFO: A service \"${target_service_name}\" with type \"${target_servie_type}\" was is already existed."
            return 1
        fi
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3,4,5,7)

    echo "INFO: A service \"${target_service_name}\" with type \"${target_servie_type}\" was NOT existed."
    return 0
}

main "$@"

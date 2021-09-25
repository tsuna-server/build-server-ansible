#!/usr/bin/env bash
#
# This script validates whether the Glance image is already existed or not
#   return 1: The Glance image was already existed
#   return 0: The Glance image was NOT existed
#

main() {
    local target_image_name="$1"
    local image_name
    local output

    [[ -z "$target_image_name" ]] && return 2

    output="$(glance image-list)" || {
        echo "ERROR: Failed to get image list from glance-api" 2>&1
        return 2
    }

    while read image_name _; do
        image_name="${image_name%\\n}"
        [[ "$image_name" == "${target_image_name}" ]] && return 1
    done < <(tail -n +4 <<< "$output" | head -n -1 | cut -d '|' -f 3)

    return 0
}

main "$@"

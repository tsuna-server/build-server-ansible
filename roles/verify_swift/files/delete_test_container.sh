#!/usr/bin/env bash

RET_THE_CONTAINER_EXISTED=99

log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    local container="$1"
    local ret

    is_container_existed "${container}"
    ret=$?

    if [ $ret -eq ${RET_THE_CONTAINER_EXISTED} ]; then
        delete_container "${container}" || return 1
    elif [ $ret -ne 0 ]; then
        # An error log will output in the function delete_container(). Then the instruction returns 1 without any output.
        return 1
    fi

    return 0
}

delete_container() {
    local container="$1"
    openstack container delete "${container}" || {
        log_err "Failed to delete a container \"${container}\" with the command \"openstack container delete ${container}\""
        return 1
    }
    return 0
}

is_container_existed() {
    local container="$1"
    local ret result_output

    result_output=$(jq -r ".[] | select(.Name == \"${container}\") | .Name" < <(openstack container list -f json))
    ret=$?

    [ $ret -ne 0 ] && {
        log_err "Failed to verify whether the contianer \"${container}\" has existed with the command \"openstack container list -f json\"."
        return 1
    }

    [ -n "${result_output}" ] && return ${RET_THE_CONTAINER_EXISTED}
    return 0
}

main "$@"

#!/usr/bin/env bash
log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

main() {
    local type_of_client="$1"
    local cap_mon="$2"
    local cap_osd="$3"

    #echo "cap_mon=${cap_mon}, cap_osd=${cap_osd}"

    if [ ${#@} -ne 3 ]; then
        log_err "Failed to execute $0. It requires 3 arguments type_of_client, cap_mon and cap_osd. (ex: $0 \"client.cinder\" \"allow r, allow command \\\"osd blacklist\\\"\" \"allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images\") "
        return 1
    fi

    is_a_cap_already_exists "$type_of_client" "$cap_mon" "$cap_osd"
}

# Check whether caps "cap_mon" and "cap_osd" have already created.
# Returns:
#   0: Caps have already created.
#   1: Others. Caps have not created yet.
is_a_cap_already_exists() {
    local type_of_client="$1"
    local cap_mon="$2"
    local cap_osd="$3"

    local output=
    local current_cap_mon=
    local current_osd_mon=

    # # An example output
    # [
    #   {
    #     "entity": "client.cinder",
    #     "key": "AQD+HqxkElaeGRAAfNin7ErBmUraSp3olkkwxg==",
    #     "caps": {
    #       "mon": "allow r",
    #       "osd": "allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images"
    #     }
    #   }
    # ]
    output="$(ceph auth get client.cinder --format json 2> /dev/null)"
    current_cap_mon="$(jq '.[0].caps.mon' <<< "$output")" || {
        log_err "Failed to get current_cap_mon. A command \"ceph auth get client.cinder --format json\" might be failed. Actual output is -> ${output}"
        return 1
    }

    current_cap_osd="$(jq '.[0].caps.osd' <<< "$output")" || {

    }



}

main "$@"

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

is_a_cap_client_cinder_already_existed() {
    local type_of_client="$1"
    local cap_mon="$2"
    local cap_osd="$3"

    is_a_cap_already_exists "client.cinder" "$type_of_client" "$cap_mon" "$cap_osd"
}

is_a_cap_mon_already_exists() {
    local type_of_cap="$1"
    local type_of_client="$2"
    local cap_mon="$3"
    local cap_osd="$4"

    is_a_cap_already_exists "$type_of_cap" "$type_of_client" ".[0].caps.mon" "$cap_mon" "$cap_osd"
}

is_a_cap_osd_already_exists() {
    local type_of_cap="$1"
    local type_of_client="$2"
    local cap_mon="$3"
    local cap_osd="$4"

    is_a_cap_already_exists "$type_of_cap" "$type_of_client" ".[0].caps.osd" "$cap_mon" "$cap_osd"
}


# Check whether caps "cap_mon" and "cap_osd" have already created.
# Returns:
#   0: Caps have already created.
#   1: Others. Caps have not created yet.
is_a_cap_already_exists() {
    local type_of_cap="$1"
    local type_of_client="$2"
    local filter_format="$3"
    local cap_mon="$4"
    local cap_osd="$5"

    local output=
    local current_cap=

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
    output="$(ceph auth get ${type_of_cap} --format json 2> /dev/null)" || {
        log_err "Failed to get an output of a command \"ceph auth get ${type_of_cap}\" --format json. A return code of it was non 0."
        return 1
    }


    current_cap="$(jq -r "$filter_format" <<< "$output")" || {
        log_err "Failed to get current_cap_mon. A command \"ceph auth get ${type_of_cap} --format json\" might be failed. Actual output is -> ${output}"
        return 1
    }

    if [ -z "$output" = "allow r, allow command \"osd blacklist\"" ]

    if [ "$output" = "allow r, allow command \"osd blacklist\"" ]; then

    fi

    current_cap_osd="$(jq '.[0].caps.osd' <<< "$output")" || {
        log_err "Failed to parse a JSON. (type_of_cap=${type_of_cap}, type_of_client=${type_of_client}, cap_mon=${cap_mon}, cap_osd=${cap_osd})"
        return 1
    }



}

main "$@"

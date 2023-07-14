#!/usr/bin/env bash
log_err() {
    echo "$(date) - ERROR: $1" >&2
}
log_info() {
    echo "$(date) - INFO: $1"
}

FILTER_FORMAT_MON=".[0]"

# Parameters
#   type_of_client: A type of client. (ex: "client.cinder", "client.cinder-backup", "client.glance")
#   cap_mon=
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
#   1: Caps has NOT already created.
#   others: A something error.
is_a_cap_already_exists() {
    local type_of_client="$1"       # A type of cap. That assumes "client.cinder", "client.cinder-backup" or "client.glance" currently.
    local mon_cap="$2"              # A text of cap for mon. (ex: allow r, allow command "osd blacklist")
    local osd_cap="$3"              # A text of cap for osd. (ex: allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images)

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
    output="$(ceph auth get ${type_of_client} --format json 2> /dev/null)" || {
        log_err "Failed to get an output of a command \"ceph auth get ${type_of_client}\" --format json. A return code of it was non 0."
        return 2
    }


    current_cap="$(jq -r "$filter_format" <<< "$output")" || {
        log_err "Failed to get current_cap_mon. A command \"ceph auth get ${type_of_client} --format json\" might be failed. Actual output is -> ${output}"
        return 2
    }

    if [ -z "$output" ]; then
        log_err "Failed to get an output of current_cap_mon. An output of the command \"jq -r "$filter_format" <<< \\\"$output\\\" \""
        return 2
    fi

    if [ "$output" = "allow r, allow command \"osd blacklist\"" ]; then
        log_info "A cap \"${type_of_client}\" has already set as \"allow r, allow command \\\"osd blacklist\\\"\". An instruction to set a cap will be skipped."
        return 0
    fi

    ceph auth caps "$type_of_client" mon "$mon_cap" osd "$osd_cap" || {
        log_err "Failed to execute a command. (ceph auth caps \"$type_of_client\" mon \"$mon_cap\" osd \"$osd_cap\")"
        return 0
    }

    return 1
}

create_a_cap() {
    local type_of_client="$1"
    local mon_cap="$2"
    local osd_cap="$3"

    ceph auth caps $type_of_client mon "$mon_cap" osd "$osd_cap" || {
        log_err "Failed to execute a command. (ceph auth caps $type_of_client mon \"$mon_cap\" osd \"$osd_cap\")"
        return 1
    }

    log_info "Succeeded adding a cap of ceph. (ceph auth caps \"$type_of_client\" mon \"$mon_cap\" osd \"$osd_cap\")"

    return 0
}


main "$@"

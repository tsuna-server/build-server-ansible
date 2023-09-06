#!/usr/bin/env bash

log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    declare -a target_hosts=($@)
    local clause=""
    local delimiter=""
    local target
    local num_of_record

    if [ ${#target_hosts[@]} -eq 0 ]; then
        log_err "This script requires target hosts that will be added in a cell with \"cell_id == 1\""
        return 1
    fi

    for target in "${target_hosts[@]}"; do
        clause+="${delimiter}\"${target}\""
        delimiter=","
    done

    #mysql -D nova_api <<< 'select id , cell_id, host from host_mappings;'
    num_of_record=$(mysql -N -D nova_api <<< "select host from host_mappings where host in (${clause});" | wc -l)
    echo $num_of_record

    if [[ ! "$num_of_record" =~ ^[0-9]+$ ]]; then
        log_err "Num of records that obtained an SQL query \"select host from host_mappings where host in (${clause}); | wc -l\" might be failed. The result was not a number(actual = \"${num_of_record}\")."
        return 1
    fi

    if [ ${num_of_record} -ne ${#target_hosts[@]} ]; then
        log_err "Num of records that is registered in a cell and num of targets host (that you specified) are difference. [num_of_records_registered_in_a_cell(${num_of_record}), num_of_target_hosts(${#target_hosts[@]})]"
        return 1
    fi

    return 0
}

main "$@"

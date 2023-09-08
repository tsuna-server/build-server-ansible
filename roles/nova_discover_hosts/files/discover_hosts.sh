#!/usr/bin/env bash

log_err() { echo "$(date) - ERROR: $1" >&2; }
log_info() { echo "$(date) - INFO: $1"; }

main() {
    declare -a target_hosts=($@)
    local clause=""
    local delimiter=""
    local target
    local num_of_records=0
    local max_attempts=120
    local current_attempts=0

    if [ ${#target_hosts[@]} -eq 0 ]; then
        log_err "This script requires target hosts that will be added in a cell with \"cell_id == 1\""
        return 1
    fi

    #log_info "${target_hosts[@]}"

    for target in "${target_hosts[@]}"; do
        clause+="${delimiter}\"${target}\""
        delimiter=","
    done

    while [ $num_of_records -ne ${#target_hosts[@]} ]; do
        #mysql -D nova_api <<< 'select id , cell_id, host from host_mappings;'
        num_of_records=$(mysql -N -D nova_api <<< "select count(host) from host_mappings where host in (${clause});")

        if [[ ! "$num_of_records" =~ ^[0-9]+$ ]]; then
            log_err "Num of records that obtained an SQL query \"select host from host_mappings where host in (${clause}); | wc -l\" might be failed. The result was not a number(actual = \"${num_of_records}\")."
            return 1
        fi

        [ $num_of_records -eq ${#target_hosts[@]} ] && break

        # Add compute nodes to the cell
        su -s /bin/sh -c 'nova-manage cell_v2 discover_hosts --verbose' nova || {
            log_err "Failed to run a command (\"nova-manage cell_v2 discover_hosts --verbose=\" nova)"
            return 1
        }

        [ $current_attempts -ge $max_attempts ] && {
            log_err "Failed to register target_hosts even attempting it ${current_attempts} times (max_attempts == ${max_attempts})."
            return 1
        }
        (( ++current_attempts ))

        sleep 2
    done

    [ $current_attempts -ge $max_attempts ] && {
        log_err "Num of records that is registered in a cell and num of targets host (that you specified) are difference. [num_of_records_registered_in_a_cell(${num_of_record}), num_of_target_hosts(${#target_hosts[@]})]"
        return 1
    }

    log_info "Succeeded in registering target_hosts. Target hosts are ... ${target_hosts[@]}"

    return 0
}

main "$@"

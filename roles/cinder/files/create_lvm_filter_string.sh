#!/usr/bin/env bash

# Example output if LVM multi physical volumes are existed
#
# $ pvdisplay
# --- Physical volume ---
# PV Name               /dev/vdb1
# VG Name               cinder-volumes
# PV Size               10.00 GiB / not usable 4.00 MiB
# Allocatable           yes
# PE Size               4.00 MiB
# Total PE              2559
# Free PE               2559
# Allocated PE          0
# PV UUID               StJSa2-0THV-siVB-yWeN-bxlQ-y6j5-lwfPzC
#
# --- Physical volume ---
# PV Name               /dev/vdb2
# VG Name               cinder-volumes
# PV Size               10.00 GiB / not usable 4.00 MiB
# Allocatable           yes
# PE Size               4.00 MiB
# Total PE              2559
# Free PE               2559
# Allocated PE          0
# PV UUID               clV2tA-ttAS-1kKx-0h0n-MXL0-duKb-vYOcMn

main() {
    local line
    declare -a physical_volumes_for_cinder
    local reached_pv_name=1
    local reached_vg_name=1
    local tmp_pv_name tmp_vg_name

    while read line; do
        if [ $reached_pv_name = 1 ] && [ $reached_vg_name = 1 ]; then
            # Continue until a next delimiter was found
            if [ "$line" = "--- Physical volume ---" ]; then
                # Set flags to search pv_name from next loop
                reached_pv_name=0
                reached_vg_name=0
            fi
        elif [ $reached_pv_name = 0 ] || [ $reached_vg_name = 0 ]; then
            # In a section of "Physical volume" and both "PV Name" and "VG Name" are not found yet.
            if [[ "$line" =~ ^PV\ Name\ .*$ ]]; then
                # If "PV Name" was found, save its name temporary.
                tmp_pv_name="$(sed -e 's/^PV Name \+\(.*\)/\1/g' <<< "$line")"
                reached_pv_name=1
            elif [[ "$line" =~ ^VG\ Name\ .*$ ]]; then
                # If "VG Name" was found
                tmp_vg_name="$(sed -e 's/^VG Name \+\(.*\)/\1/g' <<< "$line")"

                if [ "$tmp_vg_name" = "cinder-volumes" ]; then
                    # If the physical volume was belonging in a volume group "cinder-volumes".
                    physical_volumes_for_cinder+=("$tmp_pv_name")
                    reached_vg_name=1
                else
                    # if the physical volume was NOT belonging in a volume group "cinder-volumes",
                    # set flag and continue to proceed next section of the physical volume.
                    reached_vg_name=1
                fi
            fi
        fi
    done < <(pvdisplay)

    if [ ${#physical_volumes_for_cinder[@]} -eq 0 ]; then
        echo "ERROR: Failed to get physical volumes in a volume group \"cinder-volumes\". Failed to create a filter string for LVM." >&2
        exit 1
    elif [ ${#physical_volumes_for_cinder[@]} -gt 1 ]; then
        # TODO: This script only support 1 volumes so far. If you want to make this script supports more 1 volumes, you have to print them all properly.
        echo "ERROR: This script only support 1 volumes so far. This script detects ${#physical_volumes_for_cinder[@]} volumes on this node($(hostname))." >&2
        exit 1
    fi

    echo "[ \"a|${physical_volumes_for_cinder[0]}|\", \"r|.*|\" ]"
}

main "$@"

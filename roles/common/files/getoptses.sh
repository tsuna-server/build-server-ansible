
# Options of main-command
#   command [-H|--help] [-d] [--version] [-C <path>|--workdir <path>]
# Options of sub-command
#   command-subcommand [-H|--help] [-i] [--list] [-F <path>|--file <path>]

function getoptses() {
    local optspec="HdC:-:"

    local optsespec=":o:l:-:"
    local val_of_options
    local val_of_long_options
    declare -A elements_of_short_options
    declare -A elements_of_long_options

    declare -a result_of_short_options
    declare -a result_of_long_options

    declare -a arguments

    local element
    local last_element
    local optchar
    local result_line

    OPTIND=1
    while getopts "$optsespec" optchar; do
        case "$optchar" in
        o )
            val_of_options="${OPTARG}"
            OPTARG="options"
            ;;&
        l )
            val_of_long_options=(${OPTARG//,/ })
            OPTARG="longoptions"
            ;;&
        h )
            OPTARG="help"
            ;;&
        - | o | l | h )
            case "$OPTARG" in
            options )
                [[ -z "$val_of_options" ]] && { val_of_options="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )); }
                [[ -z "$val_of_options" ]] || [[ "${val_of_options:0:1}" == "-" ]] && {
                    echo "There is no value of option \"-o, --options\"" >&2
                    return 1
                }

                while read -r -n1 element; do
                    if [[ "$element" == ":" ]]; then
                        elements_of_short_options[${last_element}]+=":"
                    else
                        elements_of_short_options[${element}]=
                    fi
                    last_element="$element"
                done < <(echo -n "$val_of_options")
                ;;
            long | longoptions )
                [[ -z "$val_of_long_options" ]] && { val_of_long_options=(${!OPTIND//,/ }); OPTIND=$(( $OPTIND + 1 )); }
                [[ -z "$val_of_long_options" ]] || [[ "${val_of_long_options:0:1}" == "-" ]] && {
                    echo "There is no value of option \"-l, --longoptions\"" >&2
                    return 1
                }

                for element in "${val_of_long_options[@]}"; do
                    if [[ "${element: -1}" == ":" ]]; then
                        elements_of_long_options[${element:0:-1}]=":"
                    else
                        elements_of_long_options[${element}]=
                    fi
                done
                ;;
            help )
                echo "Usage: TODO"
                ;;
            - )
                # Options after "--" are as arguments.
                break
                ;;
            * )
                [[ "$OPTERR" == "1" ]] || [[ "${optspec:0:1}" == ":" ]] \
                        && echo "Unknown long option of main command" >&2 && return 1
            esac
            ;;
        ? )
            [[ "$OPTERR" == "1" ]] || [[ "${optspec:0:1}" == ":" ]] \
                    && echo "Unknown short option of main command" >&2 && return 1
            ;;
        esac
    done
    shift $((OPTIND-1))

    [[ "${val_of_options:0:1}" != ":" ]]    && val_of_options=":${val_of_options}"
    [[ "${val_of_options: -2}" != "-:" ]]   && val_of_options+="-:"

    # Parse short options
    while [[ "${#@}" -ne 0 ]]; do
        OPTIND=1
        while getopts "$val_of_options" optchar; do
            element=${OPTARG}
            case "$optchar" in
            - )
                # long option
                result_of_long_options+=("--${element}")
                if [[ "${elements_of_long_options[${element}]+a}" ]]; then
                    if [[ "${elements_of_long_options[${element}]}" == ":" ]]; then
                        [[ -z "${!OPTIND+a}" ]] && {
                            echo "ERROR: Value of the option \"--${element}\" was not specified." >&2
                            return 1
                        }
                        result_of_long_options+=("'$(sed -e "s/'/'\\\\''/g" <<< "${!OPTIND}")'")
                        (( ++OPTIND ))
                    fi
                else
                    echo "ERROR: Unknown option --\"${optchar}\" was specified"
                    return 1
                fi
                ;;
            ? )
                result_of_short_options+=("-${optchar}")

                if [[ "${elements_of_short_options[${optchar}]+a}" ]]; then
                    if [[ "${elements_of_short_options[${optchar}]}" == ":" ]]; then
                        if [[ -z "${OPTARG+a}" ]]; then
                            echo "ERROR: Value of the option \"-${optchar}\" was not specified." >&2
                            return 1
                        fi
                        result_of_short_options+=("'$(sed -e "s/'/'\\\\''/g" <<< "${OPTARG}")'")
                    fi
                else
                    echo "ERROR: Unknown option -\"${optchar}\" was specified"
                    return 1
                fi
                ;;
            esac
        done
        shift $((OPTIND-1))

        while [[ "${#@}" -ne 0 ]]; do
            if [[ "$1" == "--" ]]; then
                shift
                for element in "$@"; do
                    arguments+=("'$(sed -e "s/'/'\\\\''/g" <<< "$element")'")
                done
                break 2
            elif [[ "${1:0:1}" == "-" ]]; then
                #continue 2
                break
            fi
            arguments+=("'$(sed -e "s/'/'\\\\''/g" <<< "$1")'")
            shift
        done
    done

    # Parse long options
    [[ ${#result_of_short_options[@]} -ne 0 ]]  && result_line+="${result_of_short_options[@]} "
    [[ ${#result_of_long_options[@]} -ne 0 ]]   && result_line+="${result_of_long_options[@]} "
    result_line+="--"
    [[ ${#arguments[@]} -ne 0 ]]                && result_line+=" ${arguments[@]}"

    echo -n "$result_line" | sed -e 's/[[:space:]]*$//'
}


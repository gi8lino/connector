#!/bin/bash

VERSION=v1.0.0

function ShowHelp {
    printf "%s\n"  \
           "Usage: connector.sh [PARAMETERS] [-j|--jq-path] [CONTAINER_NAME] | [-h|--help] | [-v|--version]" \
           "" \
           "Search a docker container and do a 'docker exec -it <PARAMETERS> <CONTAINER_NAME> <COMMAND>'." \
           "The default command is '/bin/bash'. If 'bash' is not installed in a container, you can add the label" \
           "'connector.command=<SPECIAL_COMMAND>'." \
           "If you do not want this feature on a specific container, add the label 'connector.enabled=False'." \
           "If more than one container is found, a list to select the correct container will be displayed." \
           "If a container was found or selected, it perform the command 'docker exec -it <PARAMETERS> <CONTAINER_NAME> <COMMAND>'." \
           "" \
           "parameters:" \
	       "-j, --jq-path [PATH]    path to 'jq' if not in '\$PATH' or './jq-linux64' is not at script path (otional)" \
           "-h, --help              display this help and exit" \
           "-v, --version           output version information and exit" \
           "" \
           "All additional [PARAMETERS] will be passt to 'docker exec'!" \
           "" \
           "created by gi8lino (2020)"
    exit 0
}

shopt -s nocasematch  # set string compare to not case senstive

# count start arguments
counter=0
read -ra arr <<< "$@"
args="${#arr[@]}"

# read start parameter
while [[ $# -gt 0 ]];do
    key="$1"
    case $key in
        -j|--path-jq)
        JQ="$2"
        counter=$((counter+2))
        shift # past argument
        shift # past value
        ;;        
        -v|--version)
        printf "version: ${VERSION}\n"
        exit 0
        ;;
        -h|--help)
        ShowHelp
        ;;
        *)
        counter=$((counter+1))

        if (($counter == $args)); then
            SEARCH="$1"
        else
            PARAMS="${PARAMS}$1"
        fi
        shift
        ;;
    esac
done

containers=()

if [ ! -z "${JQ}" ]; then
    if [ ! -f "${JQ}" ]; then
	    echo -e "path to jq '${JQ}' does not exists"
	    exit 1
    fi
else
    if [ -x "$(command -v jq)" ]; then
        JQ="jq"
    elif [ -f "./jq-linux64" ]; then
        JQ="./jq-linux64"
    else
        echo -e "'jq' is not installed! please install 'jq' or download binary and add the path as start parameter (-j|--jq-path)"
        exit 1
    fi
fi

# collect possible containers
containers=()
counter=0
for container in $(docker ps -a --format '{{.Names}}'); do
    [[ $container != *"$SEARCH"* ]] && continue

    read -r enabled command< <(echo $(docker inspect $container | ${JQ} -r '.[].Config.Labels | ."connector.enabled", ."connector.command"'))
    # if enabled or enabled not set but commmand set
    if [ "${enabled,,}" == "true" ] || [ -z "$enabled" ] && [ ! -z "$command" ] ; then
        counter=$((counter+1))        
        [ -z "$command" ] || [ "$command" = "null" ] && command="/bin/bash"
        containers+=("$(printf "%-4s %-20s %-15s\n" $counter $container $command)")
    fi
done

# evaluate possible conntainers
if [ "${#containers[@]}" = 0 ]; then
    echo -e "\033[91mcontainer '$SEARCH' not found\033[0m"
    exit 1
elif [ "${#containers[@]}" = 1 ]; then  # only one container found
    num=0
elif [ "${#containers[@]}" > 1 ]; then
    len=${#containers[@]}
    re='^[0-9]+$'

    while true; do
        printf "\e[4m%-4s %-20s %-15s\e[0m\n" "#" "container" "command"  # title
        (IFS='\n'; printf "%s\n" "${containers[@]}")  # print selection again
        printf "\n"
        read -p 'select container to connect: ' num

        if [[ ! $num =~ $re ]] ; then  # response is not a number
            echo -e "\033[91minput must be a number!\033[0m\n\n"
        elif (($num > $len)); then  # response number is bigger than possible max
            echo -e "\033[91minput number must be less than $len!\033[0m\n\n"
        elif [ $num = 0 ]; then  # response number is 0 and not possible
            echo -e "\033[91minput number cannot be 0!\033[0m\n\n"
        else  # response number is valid
            break
        fi

    done
else
    printf "\033[91munknown error. exit\033[0m\n"
    exit 1
fi

# connect to container
[[ $num != 0 ]] && num=$((num-1))  # subtract 1 because arrays are null based

IFS=' ' read -r nr container command <<<"${containers[$num]}"  # extract variables from array

printf "execute command \033[0;35mdocker exec -it $PARAMS $container $command\033[0m\n"

eval "docker exec -it $PARAMS $container $command"

exit 0
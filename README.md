# connector

Search a docker container and do a `docker exec -it <PARAMETERS> <CONTAINER_NAME> <COMMAND>`.  
The default command is `/bin/bash`. If `bash` is not installed in a container, you can add the label  
`connector.command=<SPECIAL_COMMAND>`.  
If you do not want this feature on a specific container, add the label `connector.enabled=False`.  
If more than one container is found, a list to select the correct container will be displayed.  
If a container was found or selected, it perform the command `docker exec -it <PARAMETERS> <CONTAINER_NAME> <COMMAND>`.  
If you do not want to set a label for each container to enable this feature, pass the argument `-a|--all`.  
Container with the label `connector.enabled=False` will be ignored.

## usage

`Usage: connector.sh [PARAMETERS] [-j|--jq-path] [CONTAINER_NAME] | [-h|--help] | [-v|--version]`

## parameters

* `-j, --jq-path [PATH]` - path to `jq` if not in `$PATH` or `./jq-linux64` is not at script path (otional)
* `-a, --all` - Search thru all containers, except those with label `connector.enabled=false`
* `-h, --help` - display this help and exit
* `-v, --version` - output version information and exit

All additional `[PARAMETERS]` will be past to `docker exec`!

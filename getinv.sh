#!/bin/bash

# Script Arguments
readonly ARGS="$*"
readonly ARGA=("$@")

# Configurable variables
PUPPET_URL='http://yy-puppetdb02.us-midwest-1.nexcess.net:8080/pdb/query/v4'
INV_PATH="${HOME}/ansible/inventories"
CLUSTER_REGEX='^(wce|ece|mce|gpc)'
PREFIX_REGEX='^[a-z]{3}([a-z]{2,3})?\d{3}'
MASTER_LIST="${HOME}/all_cluster_servers.txt"

# Necessary global variables
ALL_NODES=()
PROD_NODES=()
DEV_NODES=()
ALLWEB_NODES=()
WEBFRONT_NODES=()
ADMIN_NODES=()
DB_NODES=()
ES_NODES=()
FS_NODES=()
LB_NODES=()
CACHE_NODES=()
CRON_NODES=()

# PATH aliases
CURL='/usr/bin/curl'
GREP='/usr/bin/grep'
JQ='/usr/bin/jq'
SORT='/usr/bin/sort'
TR='/usr/bin/tr'
UNIQ='/usr/bin/uniq'

_getList () {

    $CURL   \
    --location \
    --silent \
    --get \
    $PUPPET_URL \
    --data-urlencode "query=facts[value]{ name=\"fqdn\" and value~\"$CLUSTER_REGEX\" and nodes{ deactivated is null } }" \
    | $JQ -r '.[].value'

}

_sortResults () {

    local servers="$@"

    for server in $servers; do
	ALL_NODES+=("$server")
	
	if [[ $server =~ -node([0-9]+)?\.[a-z] ]]; then
	    ALLWEB_NODES+=("$server")
	    WEBFRONT_NODES+=("$server")
	fi

	if [[ $server =~ -admin[0-9] ]]; then
	    ALLWEB_NODES+=("$server")
	    ADMIN_NODES+=("$server")
	fi

	if [[ $server =~ -db([0-9]+)?\.[a-z] ]]; then
	    DB_NODES+=("$server")
	fi

	if [[ $server =~ -fs([0-9]+)?\.[a-z] ]]; then
	    FS_NODES+=("$server")
	fi

	if [[ $server =~ -lb([0-9]+)?\.[a-z] ]]; then
	    LB_NODES+=("$server")
	fi

	if [[ $server =~ -dev([0-9]+)?\.[a-z] ]]; then
	    DEV_NODES+=("$server")
	else
	    PROD_NODES+=("$server")
	fi

	if [[ $server =~ -es[0-9] ]]; then
	    ES_NODES+=("$server")
	fi

	if [[ $server =~ -cache[0-9] ]]; then
	    CACHE_NODES+=("$server")
	fi

	if [[ $server =~ -cron[0-9] ]]; then
	    CRON_NODES+=("$server")
	fi
    done 

}

_writeIni () {

    echo -e "\n[prod]"
    echo ${PROD_NODES[*]} | $TR " " "\n" | $SORT

    if [[ ${#DEV_NODES[*]} -gt 0 ]]; then
        echo -e "\n[dev]"
        echo ${DEV_NODES[*]} | $TR " " "\n" | $SORT
    fi

    if [[ ${#ALLWEB_NODES[*]} -gt 0 ]]; then
        echo -e "\n[web]"
        echo ${ALLWEB_NODES[*]} | $TR " " "\n" | $SORT
	echo -e "\n[webfront]"
        echo ${WEBFRONT_NODES[*]} | $TR " " "\n" | $SORT
    fi 

    if [[ ${#ADMIN_NODES[*]}  -gt 0 ]]; then
	echo -e "\n[admin]"
        echo ${ADMIN_NODES[*]} | $TR " " "\n" | $SORT
    fi

    if [[ ${#DB_NODES[*]} -gt 0 ]]; then
	echo -e "\n[db]"
        echo ${DB_NODES[*]} | $TR " " "\n" | $SORT
    fi

    if [[ ${#LB_NODES[*]} -gt 0 ]]; then
	echo -e "\n[lb]"
        echo ${LB_NODES[*]} | $TR " " "\n" | $SORT
    fi

    if [[ ${#ES_NODES[*]} -gt 0 ]]; then
	echo -e "\n[es]"
        echo ${ES_NODES[*]} | $TR " " "\n" | $SORT
    fi

    if [[ ${#FS_NODES[*]} -gt 0 ]]; then
	echo -e "\n[fs]"
        echo ${FS_NODES[*]} | $TR " " "\n" | $SORT
    fi

    if [[ ${#CACHE_NODES[*]} -gt 0 ]]; then
	echo -e "\n[cache]"
        echo ${CACHE_NODES[*]} | $TR " " "\n" | $SORT
    fi
    
    if [[ ${#CRON_NODES[*]} -gt 0 ]]; then
	echo -e "\n[cron]"
        echo ${CRON_NODES[*]} | $TR " " "\n" | $SORT
    fi

}

_main () {

    local server_list prefix prefixes

    _getList > $MASTER_LIST

    prefixes=$($GREP -Po $PREFIX_REGEX $MASTER_LIST | $SORT | $UNIQ)

    for prefix in $prefixes; do
	unset ALL_NODES PROD_NODES DEV_NODES ALLWEB_NODES WEBFRONT_NODES ADMIN_NODES DB_NODES ES_NODES FS_NODES LB_NODES CACHE_NODES CRON_NODES
	declare -a ALL_NODES PROD_NODES DEV_NODES ALLWEB_NODES WEBFRONT_NODES ADMIN_NODES DB_NODES ES_NODES FS_NODES LB_NODES CACHE_NODES CRON_NODES
	server_list=$($GREP "^$prefix" $MASTER_LIST | $SORT | $UNIQ)
        _sortResults "$server_list"
        _writeIni > ${INV_PATH}/${prefix}
    done


}

_main

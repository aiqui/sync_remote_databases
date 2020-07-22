#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
prog=$( basename "${0}" )

CONFIG_FILE=dump_rds_database.config

function errorMsg {
   echo "${1}" 1>&2
   exit -1
}

[ -f ${CONFIG_FILE} ] || errorMsg "Error: please define the config file: ${CONFIG_FILE}"

. ${CONFIG_FILE} || errorMsg "Error: failure in config file: ${CONFIG_FILE}"

[ "${SSH_ORIGINAL_COMMAND}" != "" ] && cmd="${SSH_ORIGINAL_COMMAND}" || cmd="${1}"

export MYSQL_PWD="${mysql_pw}" 

# Build the complete list of databases - needed to test for validity
n=0
alldbs=
for db in "${databases[@]}"; do
    if [[ "${db}" =~ SQL: ]]; then
	match="$( echo $db | perl -pe 's/SQL: //' )"
	match_dbs=$( mysql -N -u "${mysql_user}" -h "${mysql_host}" -e "SHOW DATABASES ${match}" )
	alldbs="${alldbs} ${match_dbs}"
    else
	alldbs="${alldbs} ${db}"
    fi
done

# Provide the list of databases
if [ "${cmd}" = "list" ]; then
    for db in ${alldbs}; do echo $db; done
    exit 0
fi

[[ "${cmd}" =~ [a-z] ]] || errorMsg "Error: please supply a database to dump"

# Dump any matching database
for db in ${alldbs}; do 
    if [ "${cmd}" = "${db}" ] ; then
	mysqldump ${mysqldump_opts} "${db}" -u "${mysql_user}" -h "${mysql_host}" | gzip -cn
	exit 0
    fi
done

errorMsg "Error: no permission to dump database: ${cmd}"
    


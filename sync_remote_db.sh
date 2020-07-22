#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
prog=$( basename "${0}" )

CONFIG_FILE=sync_remote_db.config
KEY_FILE=sync_remote_db_key
TMP_FILE=/tmp/sync_remote_db.tmp

function errorMsg {
   echo "${1}" 1>&2
   exit -1
}

[ -f ${CONFIG_FILE} ] || errorMsg "Error: please define the config file: ${CONFIG_FILE}"

. ${CONFIG_FILE} || errorMsg "Error: failure in config file: ${CONFIG_FILE}"

[ -f ${KEY_FILE} ] || errorMsg "Error: private key file must exist: ${KEY_FILE} - please create a key pair
and place the public key on the remote server as defined in the documentation"

[ "$( stat -f ${KEY_FILE} )" = "600" ] || \
    chmod 0600 ${KEY_FILE} || errorMsg "Error: unable to change permission of key file: ${KEY_FILE}"


function cleanUp {
    [ -f ${TMP_FILE} ] && rm ${TMP_FILE}
}

function catch-interupt {
   cleanUp
   exit -1
}

function errorMsg {
   echo "${1}" 1>&2
   cleanUp
   exit -1
}

function format {
    errorMsg "Format: ${prog} [-o] [-d DATABASE] [-l DATABASE] [-p DB-PASSWORD]
 -o             - output the compressed database dump to standard output
 -d DATABASE    - select the remote database 
 -l DATABASE    - select the local database 
 -p DB-PASSWORD - provide the local database password
"
}

database=
local_db=
sql_pw=
to_stdout=0
while getopts "d:l:p:oh" FLAG; do
  case "${FLAG}" in
    d)
        database="${OPTARG}";;
    l)
        local_db="${OPTARG}";;
    p)
        sql_pw="${OPTARG}";;
    o)
	to_stdout=1;;
    *)
        format;;
  esac
done

# Catch CTRL-C for cleanup
trap catch-interupt SIGINT

# Get the remote database
if [ "${database}" != "" ] ; then
    found=0
    for db in ${ALL_DATABASES}; do [ "${db}" = "${database}" ] && found=1; done
    [ ${found} -eq 0 ] && errorMsg "Error: attempting to download a database that is not configured: ${database}"
else
    n=0
    echo "Remote databases:"
    databases=
    for db in ${ALL_DATABASES}; do 
	echo "  $(( ++n )): ${db}"
	databases[$n]="${db}"
    done

    echo
    read -p "Select a remote database: " index
    [[ "${index}" =~ ^[0-9]+$ ]] && [ ${index} -gt 0 -a ${index} -le $n ] || errorMsg "Exiting..."
    database="${databases[ ${index} ]}"
fi

# Get the local database
[ "${local_db}" == "" ] && read -p "Local target database (default: ${database}): " local_db
[ "${local_db}" = "" ] && local_db="${database}"
[[ "${local_db}" =~ ^[a-zA-Z0-9_]+$ ]] || errorMsg "Invalid local database: ${local_db}"

# Get the database credentials before the DB transfer
[ "${sql_pw}" == "" ] && read -sp "Local MySQL root password: " sql_pw
export MYSQL_PWD="${sql_pw}"
echo
mysql -u root -e 'SHOW TABLES' "${local_db}" 1> /dev/null || \
    errorMsg "Error: invalid credentials"

# Attempt to download the database using the forced command and SSH key
echo
echo "Downloading remote database ${database} starting, please wait..."

ssh -i ${KEY_FILE} ${SSH_OPTS} ${SSH_USER}@${SSH_HOST} ${database} > "${TMP_FILE}"

[ $? != 0 ] && errorMsg "Remote database dump appeared to fail"

echo "Downloading complete, rebuilding database"
gunzip -c "${TMP_FILE}" | mysql -u root "${local_db}" || errorMsg "Rebuild failed"

echo "Rebuild complete"
cleanUp

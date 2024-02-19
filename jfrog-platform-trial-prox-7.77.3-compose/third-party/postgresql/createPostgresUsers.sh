#!/bin/bash

#This content is copied from _logger.sh in the commons repo. - START

# REF https://misc.flogisoft.com/bash/tip_colors_and_formatting
cClear="\e[0m"
cBlue="\e[38;5;69m"
cRedDull="\e[1;31m"
cYellow="\e[1;33m"
cRedBright="\e[38;5;197m"
cBold="\e[1m"


_loggerGetModeRaw() {
    local MODE="$1"
    case $MODE in
    INFO)
        printf ""
    ;;
    DEBUG)
        printf "%s" "[${MODE}] "
    ;;
    WARN)
        printf "${cRedDull}%s%s${cClear}" "[" "${MODE}" "] "
    ;;
    ERROR)
        printf "${cRedBright}%s%s${cClear}" "[" "${MODE}" "] "
    ;;
    esac
}


_loggerGetMode() {
    local MODE="$1"
    case $MODE in
    INFO)
        printf "${cBlue}%s%-5s%s${cClear}" "[" "${MODE}" "]"
    ;;
    DEBUG)
        printf "%-7s" "[${MODE}]"
    ;;
    WARN)
        printf "${cRedDull}%s%-5s%s${cClear}" "[" "${MODE}" "]"
    ;;
    ERROR)
        printf "${cRedBright}%s%-5s%s${cClear}" "[" "${MODE}" "]"
    ;;
    esac
}

# Capitalises the first letter of the message
_loggerGetMessage() {
    local originalMessage="$*"
    local firstChar=$(echo "${originalMessage:0:1}" | awk '{ print toupper($0) }')
    local resetOfMessage="${originalMessage:1}"
    echo "$firstChar$resetOfMessage"
}

# The spec also says content should be left-trimmed but this is not necessary in our case. We don't reach the limit.
_loggerGetStackTrace() {
    printf "%s%-30s%s" "[" "$1:$2" "]"
}

_loggerGetThread() {
    printf "%s" "[main]"
}

_loggerGetServiceType() {
    printf "%s%-5s%s" "[" "shell" "]"
}

#Trace ID is not applicable to scripts
_loggerGetTraceID() {
    printf "%s" "[]"
}

logRaw() {
    echo ""
    printf "$1"
    echo ""
}

logBold(){
    echo ""
    printf "${cBold}$1${cClear}"
    echo ""
}

# The date binary works differently based on whether it is GNU/BSD
is_date_supported=0
date --version > /dev/null 2>&1 || is_date_supported=1
IS_GNU=$(echo $is_date_supported)

_loggerGetTimestamp() {
    if [ "${IS_GNU}" == "0" ]; then
        echo -n $(date -u +%FT%T.%3NZ)
    else
        echo -n $(date -u +%FT%T.000Z)
    fi
}

# https://www.shellscript.sh/tips/spinner/
_spin()
{
  spinner="/|\\-/|\\-"
  while :
  do
    for i in `seq 0 7`
    do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 1
    done
  done
}

showSpinner() {
    # Start the Spinner:
    _spin &
    # Make a note of its Process ID (PID):
    SPIN_PID=$!
    # Kill the spinner on any signal, including our own exit.
    trap "kill -9 $SPIN_PID" `seq 0 15` &> /dev/null || return 0
}

stopSpinner() {
    local occurrences=$(ps -ef | grep -wc "${SPIN_PID}")
    let "occurrences+=0"
    # validate that it is present (2 since this search itself will show up in the results)
    if [ $occurrences -gt 1 ]; then
        kill -9 $SPIN_PID &>/dev/null || return 0
        wait $SPIN_ID &>/dev/null
    fi
}

_getEffectiveMessage(){
    local MESSAGE="$1"
    local MODE=${2-"INFO"}

    if [ -z "$CONTEXT" ]; then
        CONTEXT=$(caller)
    fi

    _EFFECTIVE_MESSAGE=
    if [ -z "$LOG_BEHAVIOR_ADD_META" ]; then
        _EFFECTIVE_MESSAGE="$(_loggerGetModeRaw $MODE)$(_loggerGetMessage $MESSAGE)"
    else
        local SERVICE_TYPE="script"
        local TRACE_ID=""
        local THREAD="main"
        
        local CONTEXT_LINE=$(echo "$CONTEXT" | awk '{print $1}')
        local CONTEXT_FILE=$(echo "$CONTEXT" | awk -F"/" '{print $NF}')
        
        _EFFECTIVE_MESSAGE="$(_loggerGetTimestamp) $(_loggerGetServiceType) $(_loggerGetMode $MODE) $(_loggerGetTraceID) $(_loggerGetStackTrace $CONTEXT_FILE $CONTEXT_LINE) $(_loggerGetThread) - $(_loggerGetMessage $MESSAGE)"
    fi
    CONTEXT=
}

# Important - don't call any log method from this method. Will become an infinite loop. Use echo to debug
_logToFile() {
    local MODE=${1-"INFO"}
    local targetFile="$LOG_BEHAVIOR_ADD_REDIRECTION"
    # IF the file isn't passed, abort
    if [ -z "$targetFile" ]; then
        return
    fi
    # IF this is not being run in verbose mode and mode is debug or lower, abort
    if [ "${VERBOSE_MODE}" != "$FLAG_Y" ] && [ "${VERBOSE_MODE}" != "true" ] && [ "${VERBOSE_MODE}" != "debug" ]; then
        if [ "$MODE" == "DEBUG" ] || [ "$MODE" == "SILLY" ]; then
            return
        fi
    fi

    # Create the file if it doesn't exist
    if [ ! -f "${targetFile}" ]; then
        return
        # touch $targetFile > /dev/null 2>&1 || true
    fi
    # # Make it readable
    # chmod 640 $targetFile > /dev/null 2>&1 || true

    # Log contents
    printf "%s\n" "$_EFFECTIVE_MESSAGE" >> "$targetFile" || true
}

logger() {
    if [ "$LOG_BEHAVIOR_ADD_NEW_LINE" == "$FLAG_Y" ]; then
        echo ""
    fi
    CONTEXT=$(caller)
    _getEffectiveMessage "$@"
    local MODE=${2-"INFO"}
    printf "%s\n" "$_EFFECTIVE_MESSAGE"
    _logToFile "$MODE"
}

logDebug(){
    VERBOSE_MODE=${VERBOSE_MODE-"false"}
    CONTEXT=$(caller)
    if [ "${VERBOSE_MODE}" == "$FLAG_Y" ] || [ "${VERBOSE_MODE}" == "true" ] || [ "${VERBOSE_MODE}" == "debug" ];then
        logger "$1" "DEBUG"
    else
        logger "$1" "DEBUG" >&6
    fi
    CONTEXT=
}

logSilly(){
    VERBOSE_MODE=${VERBOSE_MODE-"false"}
    CONTEXT=$(caller)
    if [ "${VERBOSE_MODE}" == "silly" ];then
        logger "$1" "DEBUG"
    else
        logger "$1" "DEBUG" >&6
    fi
    CONTEXT=
}

logError() {
    CONTEXT=$(caller)
    logger "$1" "ERROR"
    CONTEXT=
}

errorExit () {
    CONTEXT=$(caller)
    logger "$1" "ERROR"
    CONTEXT=
    exit 1
}

warn () {
    CONTEXT=$(caller)
    logger "$1" "WARN"
    CONTEXT=
}

note () {
    CONTEXT=$(caller)
    logger "$1" "NOTE"
    CONTEXT=
}

bannerStart() {
    title=$1
    echo
    echo -e "\033[1m${title}\033[0m"
    echo
}

bannerSection() {
    title=$1
    echo
    echo -e "******************************** ${title} ********************************"
    echo
}

bannerSubSection() {
    title=$1
    echo
    echo -e "************** ${title} *******************"
    echo
}

bannerMessge() {
    title=$1
    echo
    echo -e "********************************"
    echo -e "${title}"
    echo -e "********************************"
    echo
}

setRed () {
    local input="$1"
    echo -e \\033[31m${input}\\033[0m
}
setGreen () {
    local input="$1"
    echo -e \\033[32m${input}\\033[0m
}
setYellow () {
    local input="$1"
    echo -e \\033[33m${input}\\033[0m
}

logger_addLinebreak () {
    echo -e "---\n"
}

bannerImportant() {
    title=$1
    local bold="\033[1m"
    local noColour="\033[0m"
    echo
    echo -e "${bold}######################################## IMPORTANT ########################################${noColour}"
    echo -e "${bold}${title}${noColour}"
    echo -e "${bold}###########################################################################################${noColour}"
    echo
}

bannerEnd() {
    #TODO pass a title and calculate length dynamically so that start and end look alike
    echo
    echo "*****************************************************************************"
    echo
}

banner() {
    title=$1
    content=$2
    bannerStart "${title}"
    echo -e "$content"
}

# The logic below helps us redirect content we'd normally hide to the log file. 
    #
    # We have several commands which clutter the console with output and so use 
    # `cmd > /dev/null` - this redirects the command's output to null.
    # 
    # However, the information we just hid maybe useful for support. Using the code pattern
    # `cmd >&6` (instead of `cmd> >/dev/null` ), the command's output is hidden from the console 
    # but redirected to the installation log file
    # 

#Default value of 6 is just null
exec 6>>/dev/null
redirectLogsToFile() {
    echo ""
    # local file=$1

    # [ ! -z "${file}" ] || return 0

    # local logDir=$(dirname "$file")

    # if [ ! -f "${file}" ]; then
    #     [ -d "${logDir}" ] || mkdir -p ${logDir} || \
    #     ( echo "WARNING : Could not create parent directory (${logDir}) to redirect console log : ${file}" ; return 0 )
    # fi

    # #6 now points to the log file
    # exec 6>>${file}
    # #reference https://unix.stackexchange.com/questions/145651/using-exec-and-tee-to-redirect-logs-to-stdout-and-a-log-file-in-the-same-time
    # exec 2>&1 > >(tee -a "${file}")
}

# Check if a give key contains any sensitive string as part of it
# Based on the result, the caller can decide its value can be displayed or not
#   Sample usage : isKeySensitive "${key}" && displayValue="******" || displayValue=${value}
isKeySensitive(){
    local key=$1
    # keep all the sensitive keys in lower case
    local sensitiveKeys="password|secret|key|token|extrajavaopts|database\.url"

    if [ -z "${key}" ]; then
        return 1
    else
        local lowercaseKey=$(echo "${key}" | tr '[:upper:]' '[:lower:]' 2>/dev/null)
        [[ "${lowercaseKey}" =~ ${sensitiveKeys} ]] && return 0 || return 1
    fi
}

getPrintableValueOfKey(){
    local displayValue=
    local key="$1"
    if [ -z "$key" ]; then
        # This is actually an incorrect usage of this method but any logging will cause unexpected content in the caller
        echo -n ""
        return
    fi

    local value="$2"
    isKeySensitive "${key}" && displayValue="$SENSITIVE_KEY_VALUE" || displayValue="${value}"
    echo -n $displayValue
}

_createConsoleLog(){
    if [ -z "${JF_PRODUCT_HOME}" ]; then
        return
    fi
    local targetFile="${JF_PRODUCT_HOME}/var/log/console.log"
    mkdir -p "${JF_PRODUCT_HOME}/var/log" || true
    if [ ! -f ${targetFile} ]; then
        touch $targetFile > /dev/null 2>&1 || true
    fi
    chmod 640 $targetFile > /dev/null 2>&1 || true
}

# Output from application's logs are piped to this method. It checks a configuration variable to determine if content should be logged to 
# the common console.log file
redirectServiceLogsToFile() {

    local result="0"
    local SKIP="${FLAG_N}"
    local targetFile=

    # check if the function getSystemValue exists
    LC_ALL=C type getSystemValue > /dev/null 2>&1 || result="$?"
    if [[ "$result" != "0" ]]; then
        warn "Couldn't find the systemYamlHelper. Skipping log redirection"
        SKIP="${FLAG_Y}"
    fi

    getSystemValue "shared.logging.consoleLog.enabled" "NOT_SET"
    if [[ "${SKIP}" == "${FLAG_N}" && "${YAML_VALUE}" == "false" ]]; then
        logger "Redirection is set to false. Skipping log redirection"
        SKIP="${FLAG_Y}"
    fi

    if [[ "${SKIP}" == "${FLAG_N}" && -z "${JF_PRODUCT_HOME}" || "${JF_PRODUCT_HOME}" == "" ]]; then
        warn "JF_PRODUCT_HOME is unavailable. Skipping log redirection"
        SKIP="${FLAG_Y}"
    fi

    if [[ "${SKIP}" == "${FLAG_Y}" ]]; then
        targetFile="/dev/null"
    else
        targetFile="${JF_PRODUCT_HOME}/var/log/console.log"
        _createConsoleLog
    fi

    while read -r line; do
        printf '%s\n' "${line}" >> $targetFile || return 0 # Don't want to log anything - might clutter the screen
    done
}

## Display environment variables starting with JF_ along with its value
## Value of sensitive keys will be displayed as "******"
##
## Sample Display :
##
## ========================
## JF Environment variables
## ========================
##
## JF_SHARED_NODE_ID                   : locahost
## JF_SHARED_JOINKEY                   : ******
##
##
displayEnv() {
    local JFEnv=$(printenv | grep ^JF_ 2>/dev/null)
    local key=
    local value=

    if [ -z "${JFEnv}" ]; then
        return
    fi

    cat << ENV_START_MESSAGE

========================
JF Environment variables
========================
ENV_START_MESSAGE

    for entry in ${JFEnv}; do
        key=$(echo "${entry}" | awk -F'=' '{print $1}')
        value=$(echo "${entry}" | cut -d '=' -f2-)

        isKeySensitive "${key}" && value="******" || value=${value}
        
        printf "\n%-35s%s" "${key}" " : ${value}"
    done
    echo;
}

_addLogRotateConfiguration() {
    logDebug "Method ${FUNCNAME[0]} Caller:$(caller)"
    # mandatory inputs
    local confFile="$1"
    local logFile="$2"

    # Method available in _ioOperations.sh
    LC_ALL=C type io_setYQPath > /dev/null 2>&1 || return 1

    io_setYQPath

    # Method available in _systemYamlHelper.sh
    LC_ALL=C type getSystemValue > /dev/null 2>&1 || return 1

    local frequency="daily"
    local archiveFolder="archived"

    local compressLogFiles=
    getSystemValue "shared.logging.rotation.compress" "true"
    if [[ "${YAML_VALUE}" == "true" ]]; then
        compressLogFiles="compress"
    fi

    getSystemValue "shared.logging.rotation.maxFiles" "10"
    local noOfBackupFiles="${YAML_VALUE}"

    getSystemValue "shared.logging.rotation.maxSizeMb" "25"
    local sizeOfFile="${YAML_VALUE}M"

    logDebug "Adding logrotate configuration for [$logFile] to [$confFile]"

    # Add configuration to file
    local confContent=$(cat << LOGROTATECONF
$logFile {
    $frequency
    missingok
    rotate $noOfBackupFiles
    $compressLogFiles
    notifempty
    olddir $archiveFolder
    dateext
    extension .log
    dateformat -%Y-%m-%d-%s
    size ${sizeOfFile}
}
LOGROTATECONF
) 
    echo "${confContent}" > ${confFile} || return 1
}

_operationIsBySameUser() {
    local targetUser="$1"
    local currentUserID=$(id -u)
    local currentUserName=$(id -un)

    if [ $currentUserID == $targetUser ] || [ $currentUserName == $targetUser ]; then
        echo -n "yes"
    else   
        echo -n "no"
    fi
}

_addCronJobForLogrotate() {
    logDebug "Method ${FUNCNAME[0]} Caller:$(caller)"
    
    # Abort if logrotate is not available
    [ "$(io_commandExists 'crontab')" != "yes" ] && warn "cron is not available" && return 1

    # mandatory inputs
    local productHome="$1"
    local confFile="$2"
    local cronJobOwner="$3"

    # We want to use our binary if possible. It may be more recent than the one in the OS
    local logrotateBinary="$productHome/app/third-party/logrotate/logrotate"

    if [ ! -f "$logrotateBinary" ]; then
        logrotateBinary="logrotate"
        [ "$(io_commandExists 'logrotate')" != "yes" ] && warn "logrotate is not available" && return 1
    fi
    local cmd="$logrotateBinary ${confFile} --state $productHome/var/etc/logrotate/logrotate-state" #--verbose

    id -u $cronJobOwner > /dev/null 2>&1 || { warn "User $cronJobOwner does not exist. Aborting logrotate configuration" && return 1; }
    
    # Remove the existing line
    removeLogRotation "$productHome" "$cronJobOwner" || true

    # Run logrotate daily at the 55th minute of every hour
    local cronInterval="55 * * * * $cmd"

    local standaloneMode=$(_operationIsBySameUser "$cronJobOwner")

    # If this is standalone mode, we cannot use -u - the user running this process may not have the necessary privileges
    if [ "$standaloneMode" == "no" ]; then
        (crontab -l -u $cronJobOwner 2>/dev/null; echo "$cronInterval") | crontab -u $cronJobOwner -
    else
        (crontab -l 2>/dev/null; echo "$cronInterval") | crontab -
    fi
}

## Configure logrotate for a product
## Failure conditions:
## If logrotation could not be setup for some reason
## Parameters:
## $1: The product name
## $2: The product home
## Depends on global: none
## Updates global: none
## Returns: NA

configureLogRotation() {
    logDebug "Method ${FUNCNAME[0]} Caller:$(caller)"
    

    # mandatory inputs
    local productName="$1"
    if [ -z $productName ]; then
        warn "Incorrect usage. A product name is necessary for configuring log rotation" && return 1
    fi
    
    local productHome="$2"
    if [ -z $productHome ]; then
        warn "Incorrect usage. A product home folder is necessary for configuring log rotation" && return 1
    fi

    local logFile="${productHome}/var/log/console.log"
    if [[ $(uname) == "Darwin" ]]; then
        logger "Log rotation for [$logFile] has not been configured. Please setup manually"
        return 0
    fi
    
    local userID="$3"
    if [ -z $userID ]; then
        warn "Incorrect usage. A userID is necessary for configuring log rotation" && return 1
    fi

    local groupID=${4:-$userID}
    local logConfigOwner=${5:-$userID}

    logDebug "Configuring log rotation as user [$userID], group [$groupID], effective cron User [$logConfigOwner]"
    
    local errorMessage="Could not configure logrotate. Please configure log rotation of the file: [$logFile] manually"

    local confFile="${productHome}/var/etc/logrotate/logrotate.conf"

    # TODO move to recursive method
    createDir "${productHome}" "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }
    createDir "${productHome}/var" "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }
    createDir "${productHome}/var/log" "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }
    createDir "${productHome}/var/log/archived" "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }
    
    # TODO move to recursive method
    createDir "${productHome}/var/etc"  "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }
    createDir "${productHome}/var/etc/logrotate" "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }

    # conf file should be owned by the user running the script
    createFile "${confFile}" "$userID" "$groupID" || { warn "Could not create configuration file [$confFile]" return 1; }

    _addLogRotateConfiguration "${confFile}" "${logFile}" "$userID" "$groupID" || { warn "${errorMessage}" && return 1; }
    _addCronJobForLogrotate "${productHome}" "${confFile}" "${logConfigOwner}" || { warn "${errorMessage}" && return 1; }
}

_pauseExecution() {
    if [ "${VERBOSE_MODE}" == "debug" ]; then
      
        local breakPoint="$1"
        if [ ! -z "$breakPoint" ]; then
            printf "${cBlue}Breakpoint${cClear} [$breakPoint] "
            echo ""
        fi
        printf "${cBlue}Press enter once you are ready to continue${cClear}"
        read -s choice
        echo ""
    fi
}

# removeLogRotation "$productHome" "$cronJobOwner" || true
removeLogRotation() {
    logDebug "Method ${FUNCNAME[0]} Caller:$(caller)"
    if [[ $(uname) == "Darwin" ]]; then
        logDebug "Not implemented for Darwin."
        return 0
    fi
    local productHome="$1"
    local cronJobOwner="$2"
    local standaloneMode=$(_operationIsBySameUser "$cronJobOwner")

    local confFile="${productHome}/var/etc/logrotate/logrotate.conf"
    
    if [ "$standaloneMode" == "no" ]; then
        crontab -l -u $cronJobOwner 2>/dev/null | grep -v "$confFile" | crontab -u $cronJobOwner -
    else
        crontab -l 2>/dev/null | grep -v "$confFile" | crontab -
    fi
}

# NOTE: This method does not check the configuration to see if redirection is necessary.
# This is intentional. If we don't redirect, tomcat logs might get redirected to a folder/file
# that does not exist, causing the service itself to not start
setupTomcatRedirection() {
    logDebug "Method ${FUNCNAME[0]} Caller:$(caller)"
    local consoleLog="${JF_PRODUCT_HOME}/var/log/console.log"
    _createConsoleLog
    
    getSystemValue "shared.logging.consoleLog.enabled" "NOT_SET" "false"
    if [[ "${YAML_VALUE}" == "false" ]]; then
        export CATALINA_OUT="/dev/null"
        logger "Redirection is set to false. Skipping catalina log redirection"
        return 0;
    else
        export CATALINA_OUT="${consoleLog}"
    fi
}

setupScriptLogsRedirection() {
    logDebug "Method ${FUNCNAME[0]} Caller:$(caller)"
    if [ -z "${JF_PRODUCT_HOME}" ]; then
        logDebug "No JF_PRODUCT_HOME. Returning"
        return
    fi
    # Create the console.log file if it is not already present
    # _createConsoleLog || true
    # # Ensure any logs (logger/logError/warn) also get redirected to the console.log
    # # Using installer.log as a temparory fix. Please change this to console.log once INST-291 is fixed
    export LOG_BEHAVIOR_ADD_REDIRECTION="${JF_PRODUCT_HOME}/var/log/console.log"
    export LOG_BEHAVIOR_ADD_META="$FLAG_Y"
}

# Returns Y if this method is run inside a container
isRunningInsideAContainer() {
    if [ -f "/.dockerenv" ]; then
        echo -n "$FLAG_Y"
    else
        echo -n "$FLAG_N"
    fi 
}

_messageBeforePrompt() {
    if [ "$DONT_PROMPT_USE_DEFAULTS" != "$FLAG_Y" ];then
        logRaw "$1"
    fi
}

#This content is copied from _logger.sh in the commons repo. - END

# This can be used to create user, database, schema and grant the required permissions.
# This script can handle multiple execution and not with "already exists" error. An entity will get created only if it does not exist.
# NOTE : 1. This expects current linux user to be admin user in postgreSQL (this is the case with 'postgres' user)
#        2. Execute this by logging as postgres or any other user with similar privilege
#        3. This files needs be executed from a location which postgres (or the admin user which will be used) has access to. (/opt can be used)
#
#        su postgres -c "POSTGRES_PATH=/path/to/postgres/bin PGPASSWORD=postgres bash ./createPostgresUsers.sh"

POSTGRES_LABEL="Postgres"

# Create user if it does not exist
createUser(){
    local user=$1
    local pass=$2

    [ ! -z ${user} ] || errorExit "user is empty"
    [ ! -z ${pass} ] || errorExit "password is empty"

    ${PSQL} $POSTGRES_OPTIONS -tAc "SELECT 1 FROM pg_roles WHERE rolname='${user}'" | grep -q 1 1>/dev/null || \
    ${PSQL} $POSTGRES_OPTIONS -c "CREATE USER ${user} WITH PASSWORD '${pass}';" 1>/dev/null || \
    errorExit "Failed creating user ${user} on PostgreSQL"
}

# Create database if it does not exist
createDB(){
    local db=$1
    local user=$2

    [ ! -z ${db}   ] || errorExit "db is empty"
    [ ! -z ${user} ] || errorExit "user is empty"

    if ! ${PSQL} $POSTGRES_OPTIONS -lqt | cut -d \| -f 1 | grep -qw ${db} 1>/dev/null; then
        ${PSQL} $POSTGRES_OPTIONS -c "CREATE DATABASE ${db} WITH ENCODING='UTF8' TABLESPACE=${DB_TABLESPACE} template template0;" 1>/dev/null || errorExit "Failed creating db ${db} on PostgreSQL"
    fi
}

# Create schema if it does not exist
createSchema(){
    local schema=$1
    local db=$2
    local user=$3

    [ ! -z ${schema} ] || errorExit "schema is empty"
    [ ! -z ${db}     ] || errorExit "db is empty"
    [ ! -z ${user}   ] || errorExit "user is empty"

    PGOPTIONS='--client-min-messages=warning' ${PSQL} $POSTGRES_OPTIONS --dbname="${db}" -qc "CREATE SCHEMA IF NOT EXISTS ${schema} AUTHORIZATION ${user}" 1>/dev/null
}

postgresIsNotReady() {
    attempt_number=${attempt_number:-0}
	${PSQL} $POSTGRES_OPTIONS --version > /dev/null 2>&1
    outcome1=$?

    # Execute a simple db function to verify if mongo is up and running
    ${PSQL} $POSTGRES_OPTIONS -l > /dev/null 2>&1
    outcome2=$?
    if [[ $outcome1 -eq 0 ]] && [[ $outcome2 -eq 0  ]]; then
        return 0
    fi

    if [ $attempt_number -gt 10 ]; then
        errorExit "Unable to proceed. $POSTGRES_LABEL is not reachable. This can occur if the service is not running \
or the port is not accepting requests at $DB_PORT (host : $DB_HOST). Gave up after $attempt_number attempts"
    fi

    let "attempt_number=attempt_number+1"
    return 1
}

init(){
    if [[ -z $POSTGRES_PATH ]]; then
        ${PSQL} --version 2>/dev/null || { echo >&2 "\"${PSQL}\" is not installed or not available in path"; exit 1; }
    fi

    logger "Waiting for $POSTGRES_LABEL to get ready using the commands: \"${PSQL} $POSTGRES_OPTIONS --version\" & \"${PSQL} $POSTGRES_OPTIONS -l\""
    attempt_number=0
    while ! postgresIsNotReady
    do
            sleep 5
            echo -n '.'
    done
    echo ""
    logger "$POSTGRES_LABEL is ready. Executing commands"
}

setupDB(){
    local user=$1
    local pass=$2
    local db=$3
    local schema=$4

    createUser "${user}" "${pass}"    
    createDB "${db}" "${user}"
    
    ${PSQL} $POSTGRES_OPTIONS -c "GRANT ALL ON DATABASE ${db} TO ${user}" 1>/dev/null;

    if [ ! -z "${schema}" ]; then
        createSchema "${schema}" "${db}" "${user}"
        ${PSQL} $POSTGRES_OPTIONS -c "GRANT ALL ON SCHEMA ${schema} TO ${user}" --dbname="${db}" 1>/dev/null;
    fi
}

### Following are the postgres details being setup for each service.
##  Common details
: ${DB_PORT:=5432}
: ${DB_NAME_RT:="artifactory"}
: ${DB_NAME_XRAY:="xraydb"}
: ${DB_SSLMODE:="false"}
: ${DB_TABLESPACE:="pg_default"}
: ${DB_HOST:="localhost"}
: ${DB_USERNAME_RT:="artifactory"}
: ${DB_USERNAME_XRAY:="xray"}
: ${DB_PASSWORD:="password"}

# If DB_HOST is set to container name, set it as localhost as this script is expected to run within the container
if [[ $DB_HOST == "postgres" ]]; then
    DB_HOST="localhost"
fi

[[ -z "${POSTGRES_PATH}" ]] && PSQL=psql || PSQL=${POSTGRES_PATH}/psql
POSTGRES_OPTIONS="--host=${DB_HOST} --port=${DB_PORT}"

init
setupDB "${DB_USERNAME_RT}" "${DB_PASSWORD}" "${DB_NAME_RT}"
setupDB "${DB_USERNAME_XRAY}" "${DB_PASSWORD}" "${DB_NAME_XRAY}"
logger "$POSTGRES_LABEL setup is now complete"

exit 0
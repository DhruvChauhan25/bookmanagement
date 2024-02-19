# #!/bin/bash

# #Fail immediately on any error
# #set -e

# # This file is for preparing all the needed files and directories on the host.
# # These directories are mounted into the docker containers.

# SCRIPT_DIR=$(dirname $0)
# SCRIPT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# THIRDPARTY_HOME="${SCRIPT_HOME}/third-party"
# COMPOSE_HOME="$(cd ${SCRIPT_HOME} && pwd)"
# ENV="${COMPOSE_HOME}/.env"

# source "${ENV}"

# JF_PROJECT_NAME="trial-prox"

# . ${SCRIPT_HOME}/bin/systemYamlHelper.sh
# . ${SCRIPT_HOME}/bin/dockerComposeHelper.sh #Important that this be included second - overwrites some methods

# # Variables used for validations
# RPM_DEB_RECOMMENDED_MIN_RAM=4718592           # 4.5G Total RAM => 4.5*1024*1024k=4718592
# RPM_DEB_RECOMMENDED_MAX_USED_STORAGE=90       # needs more than 10% available storage
# RPM_DEB_RECOMMENDED_MIN_CPU=3                 # needs more than 3 CPU Cores

# PRODUCT_NAME="${RT_XRAY_TRIAL_LABEL}"
# IS_POSTGRES_REQUIRED="$FLAG_Y"

# # Rabbitmq cookie value. (shared.rabbitMq.erlangCookie.value)
# JF_SHARED_RABBITMQ_ERLANGCOOKIE_VALUE=JFXR_RABBITMQ_COOKIE

#!/bin/bash

#Fail immediately on any error
#set -e

# This file is for preparing all the needed files and directories on the host.
# These directories are mounted into the docker containers.

SCRIPT_DIR=$(dirname $0)
SCRIPT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRDPARTY_HOME="${SCRIPT_HOME}/third-party"
COMPOSE_HOME="$(cd ${SCRIPT_HOME} && pwd)"
ENV="${COMPOSE_HOME}/.env"

source "${ENV}"

JF_PROJECT_NAME="trial-prox"

. ${SCRIPT_HOME}/bin/systemYamlHelper.sh
. ${SCRIPT_HOME}/bin/dockerComposeHelper.sh #Important that this be included second - overwrites some methods

# Variables used for validations
RPM_DEB_RECOMMENDED_MIN_RAM=4718592           # 4.5G Total RAM => 4.5*1024*1024k=4718592
RPM_DEB_RECOMMENDED_MAX_USED_STORAGE=90       # needs more than 10% available storage
RPM_DEB_RECOMMENDED_MIN_CPU=3                 # needs more than 3 CPU Cores

PRODUCT_NAME="${RT_XRAY_TRIAL_LABEL}"
IS_POSTGRES_REQUIRED="$FLAG_Y"

# Kafka configuration variables
JF_SHARED_KAFKA_BROKER_LIST="kafka:9092"  # Update with your Kafka broker list
JF_SHARED_KAFKA_ZOOKEEPER="zookeeper:2181"  # Update with your Zookeeper server

# ... (rest of the script remains unchanged)


_isMongoNotNeeded(){
  docker_getSystemValue "shared.mongo" "JF_SHARED_MONGO" "${SYSTEM_YAML_FILE_XRAY}"
  if [ -z "${YAML_VALUE}" ]; then
    return 0;
  fi
  return 1;
}

_setMongoDataRoot() {
  if _isMongoNotNeeded; then
    unset MONGODB_DATA_ROOT
  else
    MONGODB_DATA_ROOT="${JF_ROOT_DATA_DIR_XRAY}${THIRDPARTY_DATA_ROOT}/mongodb"
  fi
}

docker_hook_setDirInfo(){
  logDebug "Method ${FUNCNAME[0]}"

  # Rabbitmq
  RABBITMQ_DATA_ROOT="${JF_ROOT_DATA_DIR_XRAY}${THIRDPARTY_DATA_ROOT}/rabbitmq"
  # PostgreSQL
  POSTGRESQL_DATA_ROOT="${JF_ROOT_DATA_DIR_RT}${THIRDPARTY_DATA_ROOT}/postgres"
  # Nginx
  NGINX_DATA_ROOT="${JF_ROOT_DATA_DIR_RT}${THIRDPARTY_DATA_ROOT}/nginx"
  _setMongoDataRoot
}

_createRabbitMQConf() {
  # create configuration file. This is necessary
  local configFile="$1"
  local confFile="${COMPOSE_HOME}/third-party/rabbitmq/rabbitmq.conf"

  if [ ! -f "$confFile" ]; then
    confFile="${SCRIPT_HOME}/rabbitmq/rabbitmq.conf"
  fi

  [ -f "$confFile" ] || { warn "Could not find the file: [rabbitmq.conf]" && return; }

  cp "$confFile" "$rabbitMQScriptFolder" || errorExit "Could not copy rabbitmq configuration."
}

setupRabbitMQCluster() {
  logDebug "Method ${FUNCNAME[0]}"

  # Copy the rabbitmq clustering script to the app folder
  local rabbitMQScriptFolder="${JF_ROOT_DATA_DIR_XRAY}/app/third-party/rabbitmq"
  mkdir -p $rabbitMQScriptFolder || errorExit "Setting ownership of [${rabbitMQScriptFolder}] to [${RABBITMQ_USER}:${RABBITMQ_USER}] failed"
  local scriptFile="${COMPOSE_HOME}/third-party/rabbitmq/setRabbitCluster.sh"
  if [ ! -f "$scriptFile" ]; then
    scriptFile="${SCRIPT_HOME}/rabbitmq/setRabbitCluster.sh"
  fi
  [ -f "$scriptFile" ] || { warn "Could not find the file: [setRabbitCluster.sh]" && return; }

  cp "$scriptFile" "$rabbitMQScriptFolder" || errorExit "Could not copy setRabbitCluster.sh to the destination folder"

  # Get the shared.rabbitMq.active.node.name. If this exists, this is a secondary node being setup
  _getYamlValueAndUpdateEnv "shared.rabbitMq.active.node.name" "JF_SHARED_RABBITMQ_ACTIVE_NODE_NAME" "$SYSTEM_YAML_FILE_XRAY"

  local configFile="$rabbitMQScriptFolder/rabbitmq.conf"
  _createRabbitMQConf "$configFile"

  # Add or override rabbitmq configurations
  transformPropertiesToFile "${configFile}" "${SYS_KEY_RABBITMQ_NODE_RABBITMQCONF}" "${SYSTEM_YAML_FILE_XRAY}" "${IGNORE_RABBITMQ_CONFIGS}"

  if [ ! -z "${JF_SHARED_RABBITMQ_ACTIVE_NODE_NAME}" ] && [ "${JF_SHARED_RABBITMQ_ACTIVE_NODE_NAME}" != "None" ]; then
    logDebug "Method ${FUNCNAME[0]} - slave node configuration"

    _getYamlValueAndUpdateEnv "shared.rabbitMq.active.node.ip" "JF_SHARED_RABBITMQ_ACTIVE_NODE_IP" "$SYSTEM_YAML_FILE_XRAY"

    # If node ID or IP are not available, warn and abort
    if [ -z "${JF_SHARED_RABBITMQ_ACTIVE_NODE_NAME}" ] || [ -z "${JF_SHARED_RABBITMQ_ACTIVE_NODE_IP}" ]; then
      warn "Missing configuration [shared.rabbitMq.active.node] in [$SYSTEM_YAML_FILE_XRAY]. RabbitMQ HA setup is incomplete. Please setup manually"
      return
    fi

    echo -e "\ncluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config" >> "$configFile"
    echo -e "\ncluster_formation.classic_config.nodes.1 = rabbit@$JF_SHARED_RABBITMQ_ACTIVE_NODE_NAME" >> "$configFile"
    
    if [[ $(uname) != "Darwin" ]]; then
      chown ${RABBITMQ_USER}:${RABBITMQ_USER} "${configFile}"
      chmod u+rw "${configFile}"
      chmod go-rwx "${configFile}"
    fi
  fi

  io_setOwnership  "${rabbitMQScriptFolder}" "${RABBITMQ_USER}" "${RABBITMQ_USER}" || errorExit "Setting ownership of [${rabbitMQScriptFolder}] to [${RABBITMQ_USER}:${RABBITMQ_USER}] failed" 
}

createErlangCookie() {
  logDebug "Method ${FUNCNAME[0]}"
  local cookieFile=${RABBITMQ_DATA_ROOT}/.erlang.cookie

  if [ -f "${cookieFile}" ]; then
    logDebug "Erlang cookie (${cookieFile}) already exists, skipping its creation"
    return
  fi
  
  logDebug "Creating erlang cookie [$cookieFile] as [$JF_SHARED_RABBITMQ_ERLANGCOOKIE_VALUE]"
  echo "$JF_SHARED_RABBITMQ_ERLANGCOOKIE_VALUE" > "${cookieFile}"

  # The cookie should be owned & readable only by the rabbit mq user
  if [[ $(uname) != "Darwin" ]]; then
    chown ${RABBITMQ_USER}:${RABBITMQ_USER} "${cookieFile}"
    chmod u+rw "${cookieFile}"
    chmod go-rwx "${cookieFile}"
  fi
}

docker_hook_setupThirdParty() {
  logDebug "Method ${FUNCNAME[0]}"

  # Update the env with this host's name
  docker_addToEnvFile "HOST_ID" "$(io_getPublicHostID)"

  # Create an erlang cookie
  createErlangCookie

  setupRabbitMQCluster
  _transformRabbitMqPasswordToConfFile
}

docker_hook_updateFromYaml() {
  logDebug "Method ${FUNCNAME[0]}"
  _getYamlValueAndUpdateEnv "shared.rabbitMq.erlangCookie.value" "JF_SHARED_RABBITMQ_ERLANGCOOKIE_VALUE" "$1"
  _getYamlValueAndUpdateEnv "shared.rabbitMq.active.node.name" "JF_SHARED_RABBITMQ_ACTIVE_NODE_NAME" "$1"
  _getYamlValueAndUpdateEnv "shared.rabbitMq.active.node.ip" "JF_SHARED_RABBITMQ_ACTIVE_NODE_IP" "$1"
  _getYamlValueAndUpdateEnv "shared.rabbitMq.clean" "JF_SHARED_RABBITMQ_CLEAN" "$1"
}

docker_hook_postSystemYamlCreation() {
  logDebug "Method ${FUNCNAME[0]}"
  
  if [[ "${DOCKER_DESKTOP_SETUP}" == "$FLAG_Y" ]]; then
     # Update the env with Bind IP
     docker_addToEnvFile "JF_THIRD_PARTY_BIND_IP" "0.0.0.0"
     docker_setSystemValue "shared.jfrogUrl" "http://${JFROG_HOST_DOCKER_INTERNAL}:8082" "${SYSTEM_YAML_FILE_XRAY}"
     docker_setSystemValue "shared.rabbitMq.url" "amqp://${JFROG_HOST_DOCKER_INTERNAL}:5672/" "${SYSTEM_YAML_FILE_XRAY}"
  else
     # Update the env with Bind IP
     docker_addToEnvFile "JF_THIRD_PARTY_BIND_IP" "${JF_SHARED_NODE_IP:-127.0.0.1}"
     docker_setSystemValue "shared.jfrogUrl" "http://$(wrapper_getHostIP):8082" "${SYSTEM_YAML_FILE_XRAY}"
     docker_setSystemValue "shared.rabbitMq.url" "amqp://$(wrapper_getHostIP):5672/" "${SYSTEM_YAML_FILE_XRAY}"
  fi

  if [ "$IS_POSTGRES_REQUIRED" == "$FLAG_Y" ]; then
      if [[ "${DOCKER_DESKTOP_SETUP}" == "$FLAG_Y" ]]; then
        docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_URL" "jdbc:postgresql://${JFROG_HOST_DOCKER_INTERNAL}:5432/artifactory" "${SYSTEM_YAML_FILE_RT}"
        docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_URL" "postgres://${JFROG_HOST_DOCKER_INTERNAL}:5432/xraydb?sslmode=disable" "${SYSTEM_YAML_FILE_XRAY}"
      else
        docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_URL" "jdbc:postgresql://$(wrapper_getHostIP):5432/artifactory" "${SYSTEM_YAML_FILE_RT}"
        docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_URL" "postgres://$(wrapper_getHostIP):5432/xraydb?sslmode=disable" "${SYSTEM_YAML_FILE_XRAY}"
      fi
    docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_USERNAME" "artifactory" "${SYSTEM_YAML_FILE_RT}"
    docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_USERNAME" "xray" "${SYSTEM_YAML_FILE_XRAY}"
    docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_PASSWORD" "${JF_SHARED_DATABASE_PASSWORD}" "${SYSTEM_YAML_FILE_RT}"
    docker_setSystemValue "$SYS_KEY_SHARED_DATABASE_PASSWORD" "${JF_SHARED_DATABASE_PASSWORD}" "${SYSTEM_YAML_FILE_XRAY}"
  fi
}

docker_hook_copyComposeFile() {
  logDebug "Method ${FUNCNAME[0]}"
  docker_setUpPostgresCompose

  local sourceFile="$COMPOSE_TEMPLATES/docker-compose.yaml"
  local targetFile="$COMPOSE_HOME/docker-compose.yaml"
  logDebug "Copying [$sourceFile] as [$targetFile]"
  cp "$sourceFile" "$targetFile"

  logDebug "Copying [$COMPOSE_TEMPLATES/$JFROG_RABBITMQ_COMPOSE_FILE] as [$COMPOSE_HOME/$JFROG_RABBITMQ_COMPOSE_FILE]"
  cp -f "${COMPOSE_TEMPLATES}/${JFROG_RABBITMQ_COMPOSE_FILE}" "${COMPOSE_HOME}/${JFROG_RABBITMQ_COMPOSE_FILE}"

  if [[ "${DOCKER_DESKTOP_SETUP}" == "$FLAG_Y" && "$(uname)" == "Darwin" ]]; then
      local sourceMountPath="xray/var/data/rabbitmq:/var/lib/rabbitmq"
      local expectedMountPath="${sourceMountPath}/mnesia"
      replacePath "${COMPOSE_HOME}/${JFROG_RABBITMQ_COMPOSE_FILE}" "${sourceMountPath}" "${expectedMountPath}"
  fi

  if _isMongoNotNeeded; then
    logDebug "Mongo entry does not exist. Removing mongo container"
    docker_removeSystemValue "services.mongodb" "$targetFile"
  fi
}

replacePath(){
    local file="${1}"
    local sourcePath="${2}"
    local expectedPath="${3}"

    if [[ -f "${file}" ]] && \
        ! ( cat "${file}" | grep "${expectedPath}" >/dev/null 2>&1 ) \
            && ( cat "${file}" | grep "${sourcePath}" >/dev/null 2>&1 ) \
                && [[ "$(uname)" == "Darwin" ]]; then
                    sed -i ' ' -e "s,${sourcePath},${expectedPath},g" "${file}" || true

    fi
}

docker_hook_productSpecificComposeHelp(){
    case "${PRODUCT_NAME}" in
        $RT_XRAY_TRIAL_LABEL)
        if [ ! -z ${JFROG_RABBITMQ_COMPOSE_FILE} ]; then
cat << END_USAGE

Rabbitmq is a dependent service which needs to be started once after install. This needs to be running before start of xray services.

start rabbitmq:      docker-compose -p ${JF_PROJECT_NAME}-rabbitmq -f ${JFROG_RABBITMQ_COMPOSE_FILE} up -d
END_USAGE
        fi
        ;;
    esac
}

docker_updateYamlValue() {
    local ymlFile="${1}"
    local path="${2}"
    local value="${3}"
    path=$(appendDotToKeyPath "$path")
    initYQ
    # TODO Add a method in systemYaml helper and use it from there.
    ${YQ} eval -i "${path} = \"${value}\"" "${ymlFile}" || errorExit "Failed to set value for the path"
}

docker_hook_preUserInputs() {
  if [[ ! -d "${COMPOSE_HOME}/templates/xray" ]]; then
    logger "Downloading JFrog xray and its dependencies (this may take several minutes)..."
    curl -Ls --max-time 180 https://releases.jfrog.io/artifactory/jfrog-xray/xray-compose/${XRAY_VERSION}/jfrog-xray-${XRAY_VERSION}-compose.tar.gz -o ${COMPOSE_HOME}/jfrog-xray-${XRAY_VERSION}-compose.tar.gz
    cd ${COMPOSE_HOME} && tar -xf jfrog-xray-${XRAY_VERSION}-compose.tar.gz
    mkdir -p ${COMPOSE_HOME}/templates/xray
    mkdir -p ${COMPOSE_HOME}/third-party/rabbitmq
    cp -f jfrog-xray-${XRAY_VERSION}-compose/templates/system.full-template.yaml ${COMPOSE_HOME}/templates/xray/
    cp -f jfrog-xray-${XRAY_VERSION}-compose/templates/system.basic-template.yaml ${COMPOSE_HOME}/templates/xray/
    cp -rf jfrog-xray-${XRAY_VERSION}-compose/third-party/rabbitmq/** ${COMPOSE_HOME}/third-party/rabbitmq/
    ROUTER_VERSION=$(cat jfrog-xray-${XRAY_VERSION}-compose/.env | grep "ROUTER_VERSION" | awk -F"=" '{print $2}')
    OBSERVABILITY_VERSION=$(cat jfrog-xray-${XRAY_VERSION}-compose/.env | grep "OBSERVABILITY_VERSION" | awk -F"=" '{print $2}')
    replaceText "ROUTER_VERSION=.*" "ROUTER_VERSION=${ROUTER_VERSION}" "${COMPOSE_HOME}/.env"
    replaceText "OBSERVABILITY_VERSION=.*" "OBSERVABILITY_VERSION=${OBSERVABILITY_VERSION}" "${COMPOSE_HOME}/.env"
    
    local postgresComposeYamlFile="${COMPOSE_HOME}/jfrog-xray-${XRAY_VERSION}-compose/templates/docker-compose-postgres.yaml"
    local postgresVersion=$(cat ${postgresComposeYamlFile} | grep "alpine" | awk -F":" '{print $3}')
    docker_updateYamlValue "${COMPOSE_HOME}/templates/docker-compose-postgres.yaml" "services.postgres.image" "\${DOCKER_REGISTRY}/postgres:${postgresVersion}"
    docker_updateYamlValue "${COMPOSE_HOME}/templates/docker-compose-all.yaml" "services.postgres.image" "\${DOCKER_REGISTRY}/postgres:${postgresVersion}"
    
    local rabbitmqComposeYamlFile="${COMPOSE_HOME}/jfrog-xray-${XRAY_VERSION}-compose/templates/docker-compose-rabbitmq.yaml"
    local rabbitmqVersion=$(cat ${rabbitmqComposeYamlFile} | grep "management" | awk -F":" '{print $3}')
    docker_updateYamlValue "${COMPOSE_HOME}/templates/docker-compose-rabbitmq.yaml" "services.rabbitmq.image" "\${DOCKER_REGISTRY}/jfrog/xray-rabbitmq:${rabbitmqVersion}"
    docker_updateYamlValue "${COMPOSE_HOME}/templates/docker-compose-all.yaml" "services.postgres.image" "\${DOCKER_REGISTRY}/jfrog/xray-rabbitmq:${rabbitmqVersion}"

    rm -rf ${COMPOSE_HOME}/jfrog-xray-${XRAY_VERSION}-compose.tar.gz
    rm -rf jfrog-xray-${XRAY_VERSION}-compose
  fi
}

if [[ "${JFROG_WINDOWS_TRIAL}" == "$FLAG_Y" || "$(uname)" == "Darwin" ]]; then
    export DOCKER_DESKTOP_SETUP="$FLAG_Y"
fi

FEATURE_FLAG_USE_WRAPPER="$FLAG_Y"
if [[ "${DOCKER_DESKTOP_SETUP}" == "$FLAG_Y" ]]; then
  SERVER_URL="http://${JFROG_HOST_DOCKER_INTERNAL}:${JF_ROUTER_ENTRYPOINTS_EXTERNALPORT}"
else
  SERVER_URL="http://$(wrapper_getHostIP):${JF_ROUTER_ENTRYPOINTS_EXTERNALPORT}"
fi
if [[ "${DOCKER_DESKTOP_SETUP}" == "$FLAG_Y" && "$(uname)" == "Darwin" ]]; then
      sourcePath="/root/.jfrog"
      expectedPath="${COMPOSE_HOME}"
      replacePath "${COMPOSE_HOME}/.env" "${sourcePath}" "${expectedPath}"
      source "${COMPOSE_HOME}/.env"
fi

SERVER_URL="http://$(wrapper_getHostIP):${JF_ROUTER_ENTRYPOINTS_EXTERNALPORT}"
PROJECT_ROOT_FOLDER_RT="artifactory"
PROJECT_ROOT_FOLDER_XRAY="xray"
EXTERNAL_DATABASES="$DATABASE_POSTGRES"
FLAG_MULTIPLE_DB_SUPPORT="$FLAG_N"
SUPPORTED_DATABASE_TYPES="$SYS_KEY_SHARED_DATABASE_TYPE_VALUE_POSTGRES"
CLUSTER_DATABASES="$DATABASE_RABBITMQ"
DOCKER_USER_XRAY=${XRAY_USER}
DOCKER_USER_RT=${ARTIFACTORY_USER}
MIGRATION_SUPPORTED="$FLAG_N"
JFROG_RABBITMQ_COMPOSE_FILE="docker-compose-rabbitmq.yaml"
SKIP_POSTGRES_SETUP="$FLAG_Y"
TRIAL_FLOW="$FLAG_Y"

docker_main $*
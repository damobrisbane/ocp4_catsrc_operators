#!/bin/sh

OPM_BINARY='/usr/local/bin/opm'
OC_BINARY='/usr/local/bin/oc'
DOCKER_BINARY='/usr/bin/docker'
AUTH_FILE="merged_pullsecret.json"
DOCKER_RUNTIME=docker
LOGBASE=/tmp/mirror-$$

FN_CATSRC=${1:-"catsrc-packages.json"}
STAGING_REGISTRY=${2:-"registry.internal.lan"}
DRYRUN=${DRYRUN:-"n"}
PRUNE=${PRUNE:-"y"}
PUSH=${PUSH:-"y"}
MIRROR=${MIRROR:-"y"}

function d1() {
  date +%Y%m%d
}

function catsrc_config() {
  local _J0=$1
  local -a L1
  oIFS=$IFS IFS=$'\n' 
  REGISTRY_FOLDER=$(echo $_J0 | jq -r '.registry_folder')
  VERSION=$(echo $_J0 | jq -r '.version')
  PUBLISHER=$(echo $_J0 | jq -r '.publisher')
  IFS=$oIFS
}

function create_idx_image() {
  echo -ne "\n==== ..Creating Index Image: ====\n" |tee $LOGFILE 
  CMD="$OPM_BINARY index prune -c $DOCKER_RUNTIME -f $INDEX_UPSTREAM -p $PACKAGES -t $INDEX_TAG"
  echo -ne "\n.. $CMD\n\n" |tee -a $LOGFILE 
  [[ $DRYRUN == "n" ]] && eval $CMD |tee -a $LOGFILE
}

function push_image() {
  echo -ne "\n==== ..Push Image: ====\n" |tee $LOGFILE
  CMD="$DOCKER_BINARY push $INDEX_TAG"
  echo -ne "\n.. $CMD\n\n" |tee -a $LOGFILE
  eval $CMD
  [[ $DRYRUN == "n" ]] && eval $CMD |tee -a $LOGFILE
}

function mirror_manifests() {
  echo -ne "\n==== ..Mirror Manifests:\n" |tee $LOGFILE
  CMD="$OC_BINARY adm catalog mirror $INDEX_TAG $MIRROR_TARGET --max-components=5 --insecure=true --index-filter-by-os=\"linux/amd64\" --to-manifests=${LOGDIR}"
  echo -ne "\n.. $CMD\n\n" |tee -a $LOGFILE
  [[ $DRYRUN == "n" ]] && eval $CMD |tee -a $LOGFILE
}

IFS=$'\n' J0=$(cat $FN_CATSRC | jq -c 2>/dev/null)
if [[ $J0 == "" ]]; then
  echo "Error parsing $FN_CATSRC" && exit 1
fi

declare -a L_PACKAGES

catsrc_config $J0



echo -ne "\n=========== Mirroring $VERSION Manifests ===========\n"

for _J_REG in $(echo $J0 | jq -rc '.registries[]'); do

  REG_NAME=$(echo $_J_REG | jq -r '.name')
  REG_LABEL=$(echo $_J_REG | jq -r '.label')
  PACKAGES=($(echo $_J_REG | jq -rc '.packages[]'))

  if [[ ${#PACKAGES[@]} -gt 0 ]]; then

    echo -ne "\n******* Mirror $REG_NAME ******\n"

    LOGDIR=$LOGBASE/$REGISTRY_FOLDER/$REG_LABEL
    [[ ! -d $LOGDIR ]] && mkdir -p $LOGDIR
    LOGFILE=$LOGDIR/$REGISTRY_FOLDER/$REG_LABEL-$(d1).log

    echo "cp $FN_CATSRC to $LOGDIR" |tee -a $LOGFILE
    [[ $DRYRUN == "n" ]] && cp $FN_CATSRC $LOGDIR

    echo "tail $LOGFILE for progress"

    VERSION_DNSFORMAT=$(echo "$VERSION" | sed -r 's/[.]+/-/g')
    TARGET_FOLDER=${REGISTRY_FOLDER}/prunedindex-${REG_LABEL}-${VERSION_DNSFORMAT}
    INDEX_TAG="${STAGING_REGISTRY}/${REGISTRY_FOLDER}/prunedindex-${REG_LABEL}:${VERSION_DNSFORMAT}"
    INDEX_UPSTREAM="${REG_NAME}:${VERSION}"

    [[ $PRUNE == "y" ]] && create_idx_image

    MIRROR_TARGET="${STAGING_REGISTRY}/${REGISTRY_FOLDER}"

    [[ $PUSH == "y" ]] && push_image
    [[ $MIRROR == "y" ]] && mirror_manifests
  fi
done

echo

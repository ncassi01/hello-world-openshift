#!/bin/bash

#required environment variables
#export NAMESPACE=<an existing namespace>
#export CLUSTER=<npe || ppe || prod>
#export BITBUCKET_USER=<Your LAN ID>
#export OCP_PWD=<Your Openshift Password>

# set -ex

CLUSTER=$(echo $CLUSTER)
NAMESPACE=$(echo $NAMESPACE)

echo "Sealing database secrets for $NAMESPACE namespace..."
echo "Press ENTER or 'y' to proceed || 'n' to quit || Type <NAMESPACE> eg 'agimei01-dev' "

read YES_NO_ENV

if [[ $YES_NO_ENV == "n" || $YES_NO_ENV == "no" ]]; then
  echo "Ok.. goodbye"
  exit 1
elif [[ $YES_NO_ENV == "y" || $YES_NO_ENV == "yes" ||  -z $YES_NO_ENV  ]]; then
  echo "ok, sealing for $NAMESPACE"
else
  NAMESPACE=$YES_NO_ENV
fi

if [[ -z "${NAMESPACE}" ]]; then
  echo "must export OR Enter NAMESPACE=<NAMESPACE eg agimei01-dev>"
  exit 1
fi

if [[ -z "${CLUSTER}" ]]; then
  echo "must export CLUSTER=<cluster> eg npe>"
  exit 1
fi

FILES=./secrets/files/*

#######################################
## Function to create sealed secrtes ##
#######################################
process () {
  
  echo "the current context..."

  oc config current-context

  echo "the current sealed secret public key in that cluster..."

  kubeseal --fetch-cert --controller-namespace sealed-secrets

  
  for FILE in $FILES; do
      
    if [[ -f "$FILE" ]]; then

      FILENAME="$(basename $FILE)"
      
      echo "Sealing secrets $FILENAME for namespace=$NAMESPACE in cluster=$CLUSTER"
   
      oc create secret generic $FILENAME --dry-run=client --from-file=$FILE -o yaml -n ${NAMESPACE} >/tmp/mysecret.yaml

      kubeseal -o yaml --controller-namespace sealed-secrets </tmp/mysecret.yaml >sealedsecrets/sealedsecret-$FILENAME.yaml

    fi 
      
  done
  
}


# Login to correct OCP environment
if [[ $CLUSTER == "npe" ]]; then
  
  oc login https://api.npek8s.bsc.bscal.com:6443 -u ${BITBUCKET_USER} -p ${OCP_PWD}

fi


if [[ $CLUSTER == "ppe"  ]]; then
  
  oc login https://api.ppe02k8s.bsc.bscal.com:6443 -u ${BITBUCKET_USER} -p ${OCP_PWD}

fi

if [[ $CLUSTER == "prod" ]]; then

  oc login https://api.prodk8s.bsc.bscal.com:6443 -u ${BITBUCKET_USER} -p ${OCP_PWD}

fi

# create sealed secrets
process


exit 0

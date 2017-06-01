#!/bin/bash

refresh_ecr_secrets(){
  local LABEL_SELECTOR=$1

  # Find the newly created secrets
  ECR_SECRETS=$(oc get secret -l "$LABEL_SELECTOR" --all-namespaces \
              --template='{{range .items}}{{.metadata.namespace}}#{{.metadata.name}}#{{.metadata.creationTimestamp}} {{end}}')

  for ECR_SECRET in $ECR_SECRETS
  do
    PROJECT=$(echo $ECR_SECRET|cut -d'#' -f1)
    SECRET=$(echo $ECR_SECRET|cut -d'#' -f2)

    if [[ -z $PROJECT ]] || [[ -z $SECRET ]]; then
      echo "Unrecognized input: $ECR_SECRET. Skipping..."
      continue
    fi

    echo "Updating secret $SECRET in project $PROJECT."
    oc delete secret "$SECRET" -n "$PROJECT"
    oc secrets new-dockercfg "$SECRET" -n "$PROJECT" \
                             --docker-server="$REGISTRY" \
                             --docker-username="$USERNAME" \
                             --docker-password="$PASSWORD" \
                             --docker-email="$DOCKER_LOGIN_EMAIL"
    oc label secret "$SECRET" "$REFRESHED_LABEL_KEY"=yes -n "$PROJECT"
  done
}

# Exit if the secret that contains aws credentials file is not mounted to /.aws folder
if [[ ! -f $HOME/.aws/credentials ]]; then
  echo "AWS credentials (access key id & secret key) must be provided as a kubernetes secret and must be mounted onto /.aws"
  sleep 10
  exit 1
fi

# Set scan frequency to 60 seconds if it's not defined already
if [[ -z $SCAN_FREQUENCY ]]; then
  SCAN_FREQUENCY=60
fi

# Set label selector of all secrets to ecr=yes, if it's not defined already
if [[ -z $SECRET_LABEL_SELECTOR ]]; then
  SECRET_LABEL_SELECTOR='ecr=yes'
fi

# Set label key for refreshed secrets to "valid", if it's not defined already
if [[ -z $REFRESHED_LABEL_KEY ]]; then
  REFRESHED_LABEL_KEY='valid'
fi

# Set the docker email to openshift@example.com, if it's not defined already
if [[ -z $DOCKER_LOGIN_EMAIL ]]; then
  DOCKER_LOGIN_EMAIL='openshift@example.com'
fi

# Amazon ECR tokens are valid only for 12 hours. So we will refresh token ever 11hrs 50min
REFRESH_INTERVAL=$[(11 * 3600) + (50 * 60)]
DOCKER_LOGIN_REGEX="^docker\s+login\s+-u\s+(\S+)\s+-p\s+(\S+)\s+-e\s+\S+\s+(\S+)$"

NEXT_REFRESH_TIME=0

while true
do
  NOW=$(date +%s)

  if [[ $NEXT_REFRESH_TIME -le $NOW ]]; then
    echo "It's time to refresh ECR token and refresh all ecr secrets in all projects."

    DOCKER_LOGIN=$(aws ecr get-login)
    if [[ ! $DOCKER_LOGIN =~ $DOCKER_LOGIN_REGEX ]]; then
      echo "Error. Unrecognized response from 'aws ecr get-login': $DOCKER_LOGIN."
      exit 1
    fi

    USERNAME=${BASH_REMATCH[1]}
    PASSWORD=${BASH_REMATCH[2]}
    REGISTRY=${BASH_REMATCH[3]}

    NEXT_REFRESH_TIME=$[$NOW + $REFRESH_INTERVAL]
    refresh_ecr_secrets $SECRET_LABEL_SELECTOR
  else
    # Find and update only newly created secrets
    # Newly created secrets should not have the refreshed label key
    refresh_ecr_secrets "$SECRET_LABEL_SELECTOR,!$REFRESHED_LABEL_KEY"
  fi

  sleep $SCAN_FREQUENCY
done

#!/bin/bash

if ! command -v jq &> /dev/null
then
    echo "jq is required, but could not be found."
    exit 2
fi

pagerduty_token=$(eval echo "\$$PARAM_PAGERDUTY_TOKEN")
PARAM_MAINTENANCE_WINDOW_ID=$(eval echo "\$$PARAM_MAINTENANCE_WINDOW_ID")

if [ -z "${PARAM_MAINTENANCE_WINDOW_ID}" ]
then
  echo "WARNING: Maintenance window does not exist. Ignoring, if the maintenance window creation did not fail, make sure to check your pipeline is built as expected!"
else
  echo "Maintenance window found, ending it."
  curl --request DELETE \
    --url "https://api.pagerduty.com/maintenance_windows/${PARAM_MAINTENANCE_WINDOW_ID}" \
    --header 'Accept: application/vnd.pagerduty+json;version=2' \
    --header "Authorization: Token token=${pagerduty_token}" \
    --header 'Content-Type: application/json' | jq
fi

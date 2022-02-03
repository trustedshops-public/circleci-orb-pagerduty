#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq is required, but could not be found."
    exit 2
fi

# Join all arguments by given separator
function join_by {
    local IFS="$1";
    shift;
    echo "$*";
}

# Escape string for json
function json_escape() {
    jq -R -s '.' <<< "$1"
}

# date format to use for pagerduty
date_format='%Y-%m-%dT%H:%M:%S-00:00'
pagerduty_token=$(eval echo "\$$PARAM_PAGERDUTY_TOKEN")

# Build service list with json objects
IFS=","
services_json=()
for service in ${PARAM_SERVICES}
do
    services_json+=('{"id": "'"${service}"'", "type": "service_reference"}')
done

# Create maintenance
response=$(curl --request POST \
  --fail-with-body \
  --url "https://api.pagerduty.com/maintenance_windows" \
  --header 'Accept: application/vnd.pagerduty+json;version=2' \
  --header "Authorization: Token token=${pagerduty_token}" \
  --header 'Content-Type: application/json' \
  --header "From: ${PARAM_PAGERDUTY_MAIL}" \
  --data @- <<TEXT
    {
        "maintenance_window": {
            "type": "maintenance_window",
            "start_time": "$(date -u +${date_format})",
            "end_time": "$(date -u -d "+ ${PARAM_DURATION_MINUTES} minutes" +${date_format})",
            "description": $(json_escape "${PARAM_DESCRIPTION}"),
            "services": [$(join_by "," "${services_json[@]}")]
        }
    }
TEXT
)

# Extract and set env var
id=$(echo "$response" | jq -r ".maintenance_window.id")
export PAGERDUTY_MAINTENANCE_WINDOW_ID="${id}"
echo "export PAGERDUTY_MAINTENANCE_WINDOW_ID='${id}'" >> "$BASH_ENV"

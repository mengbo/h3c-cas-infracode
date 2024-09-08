#!/bin/bash

source ./cas-clitool.sh

vm_deploy() {
  local method=POST
  local url="${SERVICE}/cas/casrs/vm/deploy"
  local data=$(eval "echo \"$(cat ${deploy_json_file}| sed 's/"/\\"/g')\"")
  cas_api_request "$method" "$url" "$data"
}

source "$1"
vm_deploy


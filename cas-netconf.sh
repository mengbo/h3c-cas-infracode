#!/bin/bash

source ./cas-clitool.sh

vm_exec() {
  local method=POST
  local vmid=$1
  local url="${SERVICE}/cas/casrs/vm/$vmid/executeCmd"
  local data="{\"command\": \"$(eval "echo \"${2//\"/\\\\\\\"}\"")\"}"
  cas_api_request "$method" "$url" "$data"
}

source "$1"

id=$(vm_find_id $vm_name)

netconf='{"execute": "guest-exec", "arguments": {"path": "/usr/local/bin/linux-virt-netconf.sh", "arg": ["$vm_name", "$ip", "$mask", "$gate", "$dns1", "$dns2"], "capture-output": true}}'

vm_exec "$id" "$netconf"


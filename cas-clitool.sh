#!/bin/bash

source ./cvm.cfg

cas_api_request() {
  local method=$1
  local url="$2"
  local data="$3"
  http --auth "$USER":"$PASS" --auth-type=digest --verify=no \
    "$method" "$url" \
    Accept:"application/json; charset=UTF-8" \
    Content-Type:"application/json; charset=UTF-8" <<< "$data"
}

host_list() {
  local method=GET
  local url="${SERVICE}/cas/casrs/host"
  local data=""
  cas_api_request "$method" "$url" "$data"
}

template_list() {
  local method=GET
  local url="${SERVICE}/cas/casrs/vmTemplate/all"
  local data=""
  cas_api_request "$method" "$url" "$data"
}

vm_list() {
  local method=GET
  local url="${SERVICE}/cas/casrs/vm/vmList"
  local data=""
  cas_api_request "$method" "$url" "$data"
}

vm_find_id() {
  vm_list | jq -r ".domain[] | select(.name == \"$1\") | .id"
}

vm_detail() {
  local method=GET
  local url="${SERVICE}/cas/casrs/vm/detail/$1"
  local data=""
  cas_api_request "$method" "$url" "$data"
}

vm_start() {
  local method=PUT
  local url="${SERVICE}/cas/casrs/vm/start/$1"
  local data=""
  cas_api_request "$method" "$url" "$data"
}

vm_stop() {
  local method=PUT
  local url="${SERVICE}/cas/casrs/vm/stop/$1"
  local data=""
  cas_api_request "$method" "$url" "$data"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  command=$1
  shift
  case $command in
    host_list|template_list|vm_list|\
      vm_find_id|vm_detail|vm_start|vm_stop)
          $command "$@"
          ;;
        *)
          echo "Invalid method: $1"
          echo "Supported methods:"
          echo "  host_list"
          echo "  template_list"
          echo "  vm_list"
          echo "  vm_find_id <name>"
          echo "  vm_detail <id>"
          echo "  vm_start <id>"
          echo "  vm_stop <id>"
          exit 1
          ;;
      esac
fi

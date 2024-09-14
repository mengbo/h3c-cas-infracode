#!/bin/bash

vm_name=$1
ip=$2
mask=$3
gate=$4
dns1=$5
dns2=$6

cidr=0
IFS=. read -r a b c d <<< "$mask"
for octet in $a $b $c $d; do
  while [ $octet -gt 0 ]; do
    cidr=$((cidr + (octet % 2)))
    octet=$((octet / 2))
  done
done

connection=$(nmcli -t -f NAME connection show --active | grep -v lo | head -n 1)

hostnamectl set-hostname "$vm_name"
nmcli connection modify "$connection" ipv4.addresses "$ip/$cidr"
nmcli connection modify "$connection" ipv4.gateway "$gate"
nmcli connection modify "$connection" ipv4.dns "$dns1 $dns2"
nmcli connection modify "$connection" ipv4.method manual
nmcli connection up "$connection"


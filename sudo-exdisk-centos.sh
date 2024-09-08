#!/bin/sh -v

parted /dev/vdb mktable gpt
sleep 10
parted /dev/vdb mkpart primary 0% 100%
sleep 10
pvcreate /dev/vdb1
sleep 10
vgextend centos /dev/vdb1
sleep 10
lvextend -l +100%FREE /dev/mapper/centos-root
sleep 10
xfs_growfs /dev/mapper/centos-root

# parted /dev/vdb print
# vgdisplay
# lvdisplay /dev/centos/root
df -h

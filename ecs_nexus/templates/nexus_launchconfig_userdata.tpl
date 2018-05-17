#!/bin/bash
# install nfs-utils so we can mount EFS
sudo yum install -y nfs-utils
# create a directory to mount EFS to
sudo mkdir -p ${mountpoint}
# mount the efs volume
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${efs_dnsname}:/ ${mountpoint}
# create fstab entry to ensure automount on reboots
echo "${efs_dnsname}:/ ${mountpoint} nfs defaults,vers=4.1 0 0" >> /etc/fstab
# create the nexus storage folder and make sure Nexus has permissions on it
sudo mkdir -p ${storagedir}
sudo chown -R 200:200 ${storagedir}
# join the cluster
echo ECS_CLUSTER=${clustername} >> /etc/ecs/ecs.config
sudo yum update -y ecs-init
# update limits
echo "root - nofile 65536" >> /etc/security/limits.conf

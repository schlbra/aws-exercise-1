#!/bin/bash

# Install and Start Docker
yum install -y docker
service docker start

# Configure docker to start on boot
sudo systemctl enable docker.service

# Create a partition table with a single partition that takes the whole disk
echo 'type=83' | sudo sfdisk /dev/xvdh

# Create file system on attached EBS volume
mkfs -t ext4 /dev/xvdh1

# Setup local webroot directory
mkdir /webroot
chmod 777 /webroot

# Ensure filesystem on EBS volume is mounted automatically on reboot
cat << EOF >> /etc/fstab
/dev/xvdh1   /webroot          ext4 defaults             0 2
EOF

# Mount the entry we defined in fstab
sudo mount -a

# Add index file and link to terraform code
cat << EOF > /webroot/index.html
<h1>Hello AWS World</h1>
<a href="https://github.com/schlbra/aws-exercise-1">terraform source code</a>
EOF

# Run NGINX container to host index page
docker run -d --name awsexercise1 -v /webroot:/usr/share/nginx/html:ro -p 80:80 --restart always nginx
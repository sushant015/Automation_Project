#!/bin/bash

sudo apt update -y

name='apache2'
echo "Checking ${name} installed or not?"
dpkg -s $name &> /dev/null 

if [ $? -ne 0 ]
then
    echo "${name} installing"
    sudo apt-get update
    sudo apt-get install $name
else
    echo "${name} service already installed"
fi 

echo "Checking ${name} service status?"
service apache2 status

if [ $? -ne 0 ]
then
    echo "Starting ${name} service"  
    sudo service apache2 start
else
    echo "${name} service already started"
fi

echo "Checking ${name} service enabled?"
systemctl is-enabled apache2

if [ $? -ne 0 ]
then
    echo "Enabling ${name} service"  
    systemctl enable apache2
else
    echo "${name} service already enabled"
fi

myname='sushant'
s3_bucket='upgrad-sushant'
timestamp=$(date '+%d%m%Y-%H%M%S') 
tar -cf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log
size=$(wc -c "/tmp/${myname}-httpd-logs-${timestamp}.tar" | awk '{print $1/1024 K}')

name='awscli'
echo "Checking ${name} installed or not?"
dpkg -s $name &> /dev/null 

if [ $? -ne 0 ]
then
    echo "${name} installing"  
    sudo apt-get update
    sudo apt install awscli
fi 



aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

#bookkeeping
sudo chmod 777 /var/www/html -R
if [ ! -f /var/www/html/inventory.html ]
then
cat <<EOF > /var/www/html/inventory.html
<html>
<body>
<table>
  <tr>
    <th>Log Type</th>
    <th>Time Created</th>
    <th>Type</th>
    <th>Size</th>
  </tr>
  <tr></tr>
</table>
</body>
</html>
EOF
fi

#append new info
sudo sed -i "s!<tr></tr>!<tr><td>httpd-logs</td><td>${timestamp}</td><td>tar</td><td>${size}</td></tr><tr></tr>!" /var/www/html/inventory.html

#create cron job run on daily basis
if [ ! -f /etc/cron.d/automation ]
then
    echo 'Schedule cron job for automation'
    sudo echo '0 0 * * * /root/Automation_Project/automation.sh' > /tmp/automation
    sudo cp /tmp/automation /etc/cron.d/automation
fi

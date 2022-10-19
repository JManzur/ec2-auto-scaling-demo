#!/bin/bash
yum update -y
yum install jq -y
amazon-linux-extras install epel -y
yum install stress -y
amazon-linux-extras install docker -y
service docker start
usermod -aG docker ec2-user
sleep 15
InstanceID=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .instanceId)
OSVersion=$(cat /etc/os-release | grep PRETTY_NAME= | sed -r 's/PRETTY_NAME=//g' | sed -r 's/"//g')
# aws ec2 create-tags --resources $InstanceID --tags '[{"Key":"Name","Value":"${name_prefix}-'$InstanceID'"}]' --region ${aws_region}
aws ec2 create-tags --resources $InstanceID --tags '[{"Key":"OS","Value":"'"$OSVersion"'"}]' --region ${aws_region}
docker pull jmanzur/demo-lb-app:v1.2
docker run -e HOSTNAME=$InstanceID -e APP_VERSION=V1.0 --restart=always -d -p ${app_port}:${app_port} --name DEMO-LB-APP $(docker images --filter 'reference=jmanzur/demo-lb-app' --format '{{.ID}}')
echo '#!/bin/bash' >> /opt/update_app.sh
echo 'if [ $# -eq 0 ]; then echo "[ERROR] The new version variable is needed."; exit 1; fi'  >> /opt/update_app.sh
echo 'docker stop DEMO-LB-APP' >> /opt/update_app.sh
echo 'docker rm DEMO-LB-APP' >> /opt/update_app.sh
echo 'VERSION=$1'  >> /opt/update_app.sh
echo 'InstanceID=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .instanceId)' >> /opt/update_app.sh
echo 'docker run -e HOSTNAME=$InstanceID -e APP_VERSION=$VERSION --restart=always -d -p ${app_port}:${app_port} --name DEMO-LB-APP $(docker images --filter 'reference=jmanzur/demo-lb-app' --format '{{.ID}}')' >> /opt/update_app.sh
chmod +x /opt/update_app.sh
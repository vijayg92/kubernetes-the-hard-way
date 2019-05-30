#!/bin/bash
set -e

#count=0
#for controller in  CONTROL_PLANES_IPS[*]; do
#	export "KUBE_CONTROLLER_$COUNT=$controller"
#	((count++))
#done

function __installNginx() {
  echo ""
  echo "Checking if Nginx is Already Installed!!"
  rpm --query nginx || yum install -y nginx
  echo ""
}

function __configureNginx() {

	if [ ! -f /etc/nginx/tcpconf.d ]; then
  	grep -i "include /etc/nginx/tcpconf.d/*;" /etc/nginx/nginx.conf || echo "include /etc/nginx/tcpconf.d/*;" > /etc/nginx/nginx.conf

		cat <<-EOF | tee /etc/nginx/tcpconf.d/kubernetes.conf
		stream {
			upstream kubernetes {
				server ${KUBE_MASTER01_IP}:6443;
				server ${KUBE_MASTER02_IP}:6443;
			}

			server {
				listen 6443;
				listen 443;
				proxy_pass kubernetes;
			}
		}
		EOF
	fi
	systemctl enable nginx
	systemctl start nginx
}

function __validateLoadBalancer(){

	STATUS=$(curl -I -k https://localhost:6443/version)
	echo ""
	if [ ${STATUS} -ne "200" ]; then
		echo ""
		exit 1
	fi
	echo "Kubernetes API LB is Configured Sucessfully!!!"
	echo ""
}

### Main Function ###
if [ $# -eq 0 ]; then
    echo ""
    echo "Please Provide Valid Arguments!!"
    echo ""
    echo "Usage: bootstrapAPILoadBalancer.sh KUBE_MASTER01_IP KUBE_MASTER02_IP"
    exit 1
fi
__installNginx
__configureNginx
__validateLoadBalancer

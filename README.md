# OpenShift Container Platform 4.7 installation on bare metal

![image](https://user-images.githubusercontent.com/20621916/110881401-45014980-831b-11eb-86f9-305b24eedd76.png)

![image](https://user-images.githubusercontent.com/20621916/110803087-cd4f0280-82b9-11eb-8772-615f6b978524.png)

![image](https://user-images.githubusercontent.com/20621916/110800131-dbe7ea80-82b6-11eb-9529-f5fe780a4b97.png)

**Infra Server Setup ( ose-infra-server & workstation ):**


**Step 1**: ( ose-infra-server & Workstation - CentOS 8 Minimal Installation ) - https://www.centos.org/download/
	
	Install the required binaries: 
        
		dnf -y install net-tools telnet curl wget traceroute nmap-ncat git  httpd-tools jq  nfs-utils
	 
	Stop & disable firewalld :
	
        	systemctl stop firewalld && systemctl disable firewalld
	
	Stop & disable Selinux :
        
        	sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config && setenforce 0
        
	Clone the git repo:
	
        	cd ~ && git clone https://github.com/thomas6m/OpenShift-4.7_bare_metal_installation.git
	


![image](https://user-images.githubusercontent.com/20621916/110881091-b391d780-831a-11eb-81a7-e10a56969739.png)

	Plumb all the required virtual IPs. 
	
		sample config :
	
		cat ~/OpenShift-4.7_bare_metal_installation/infra-setup/ifcfg-ens32:0 
	 
	 	vi /etc/sysconfig/network-scripts/ifcfg-ens33:X
		
	Disable Ipv6:
	
		cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/70-ipv6.conf /etc/sysctl.d/70-ipv6.conf
	
        	sysctl --load /etc/sysctl.d/70-ipv6.conf
	
	Install the latest Patches:
	
		dnf install -y epel-release && dnf update -y && reboot
		

**Infra Services Setup:**

**Step 2: Install & Configure DNS server**

	dnf -y install bind bind-utils

	cp -p /etc/named.conf /etc/named.conf-bkp

	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/named.conf  /etc/named.conf 

	cp  ~/OpenShift-4.7_bare_metal_installation/infra-setup/named.conf.local  /etc/named/named.conf.local

	mkdir /etc/named/zones

	cp  ~/OpenShift-4.7_bare_metal_installation/infra-setup/db.example.com /etc/named/zones/db.example.com

	cp  ~/OpenShift-4.7_bare_metal_installation/infra-setup/db.192.168.1  /etc/named/zones/db.192.168.1

	systemctl enable named && systemctl start named && systemctl status named

**Step 3: Install & Configure HAPROXY**

	dnf install haproxy -y
	
	ln -s /usr/sbin/haproxy /usr/sbin/api-haproxy
	
	ln -s /usr/sbin/haproxy /usr/sbin/app-ingress-haproxy
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy  /etc/sysconfig/api-haproxy 
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/app-ingress-haproxy  /etc/sysconfig/app-ingress-haproxy
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy.service  /usr/lib/systemd/system/api-haproxy.service

       	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy.service  /usr/lib/systemd/system/app-ingress-haproxy.service
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy.cfg  /etc/api-haproxy/api-haproxy.cfg
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/app-ingress-haproxy.cfg  /etc/api-haproxy/app-ingress-haproxy.cfg
	
	
	

![image](https://user-images.githubusercontent.com/20621916/110803927-a80ec400-82ba-11eb-81d3-6411a691e2fa.png)


![image](https://user-images.githubusercontent.com/20621916/110801837-93c9c780-82b8-11eb-9e8d-0d66abe8f2a7.png)



![image](https://user-images.githubusercontent.com/20621916/110802813-8234ef80-82b9-11eb-9dbb-8172f6a35643.png)


![image](https://user-images.githubusercontent.com/20621916/110803468-30409980-82ba-11eb-8c4d-2e662df261a0.png)





**RHCOS latest image** :

https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-live.x86_64.iso 

**Openshift-install latest binary:**

https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz

**Oc Client & Kubectl latest binary** :

https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz

**Login to workstation:**

cd ~ && wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz

cd ~ && wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz

tar -zxvf openshift-install-linux.tar.gz

tar -zxvf openshift-client-linux.tar.gz

mv kubectl oc openshift-install /usr/local/bin/

oc version

openshift-install version

ssh-keygen

cd ~ &&  git clone https://github.com/thomas6m/OpenShift-4.7_bare_metal_installation.git

mkdir ~/ose-install

cat ~/.ssh/id_rsa.pub

cp ~/OpenShift-4.7_bare_metal_installation/ocp-4.7/install-config.yaml  ~/ose-install/

add ssh public key & pull secret in  ~/ose-install/install-config.yaml

openshift-install create manifests --dir=ose-install/

openshift-install create ignition-configs --dir=ose-install/

tar -cvf ose-install.tar ose-install

scp ose-install.tar root@ose-infra-server:/tmp/

**Login to ose-infra-server** 

cd ~ ; tar -xvf /tmp/ose-install.tar

mkdir /var/www/html/ose

cp -R ~/ose-install/* /var/www/html/ose/

chown -R apache: /var/www/html/

chmod -R 755 /var/www/html/

Boot the bootstrap, master & worker VMs from rhcos live iso image

From console execute the below command as root 

**Bootstrap VM:**

coreos-installer install --ignition-url=http://http-server.example.com:8080/ose/bootstrap.ign /dev/sda --insecure-ignition

**Master VMs:**

coreos-installer install --ignition-url=http://http-server.example.com:8080/ose/master.ign /dev/sda --insecure-ignition

**Worker VMs:**

coreos-installer install --ignition-url=http://http-server.example.com:8080/ose/worker.ign /dev/sda --insecure-ignition

Once file copy completed, reboot the VMs. 

**Monitor the installation status**

openshift-install --dir ~/ose-install wait-for bootstrap-complete --log-level=debug

http://api-lb.example.com:9000/

openshift-install --dir ~/ose-install wait-for install-complete

Once bootstrap complete. Remove the bootstrap entry from api-load balancer.

**Login to ose-infra server**

sed -i.bak '/ bootstrap / s/^\(.*\)$/#\1/g' /etc/api-haproxy/api-haproxy.cfg

systemctl restart api-haproxy

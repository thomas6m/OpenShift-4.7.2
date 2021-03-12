# OpenShift 4.7 installation on bare metal using UPI method:

![image](https://user-images.githubusercontent.com/20621916/110904378-d71d4800-8343-11eb-9af8-697bd0e84aef.png)

Install Vmware workstation 16 pro on Highend Workstation.

Vmware workstation 16pro setup :

1. Create a hostonly network with 192.168.1.0/24  -- Name : VM-OSE

2. Create VMs with the below specs.

	1. pfsense VM ( act as router & dhcp )
	
	    	
		Guest Operation system : Other -> FreeBSD 12 64-bit
		
                Memory : 2 GB /Cpu: 2/Disk : 512GB
		
                Network Adapter : 1 from Bridged  &  1 from VM-OSE
		
	   	OS image - https://www.pfsense.org/download/     --> AMD64(64-bit) & DVD Image (ISO) installer
		
                Boot the server & accept all the default options
		
                Once server is up, login to console  https://192.168.1.1  & complete the initial setup
		
                User: admin / Password: pfsense



	2.  ose-infra-server & workstation  ( Centos8  with Minimal Installation)
 		
		Memory : 2 GB /Cpu: 2/Disk : 512GB
		
	        Network Adapter : 1 from VM-OSE
		
		OS image : https://www.centos.org/download/
		

	3. bootstrap, master1, master2, worker1 & worker2
	
		Guest Operation system : Linux -> Other Linux5.x and later kernel 64-bit
		
                Memory : 32 GB /Cpu: 16/Disk : 1024TB
		
                Network Adapter :  1 from VM-OSE
		
		RHCOS latest image : https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-live.x86_64.iso
		
		
	4. Configure DHCP server

		https://192.168.1.1/  --> Services --> DHCP Server --> Select Enable --> Range ( 192.168.1.50  - 192.168.1.60)
		
		DNS server : 192.168.1.4 & 8.8.8.8
		
		Gateway : 192.168.1.1
		
		Domain name : example.com
		
		Domain search list : example.com;ose.example.com
		
		DHCP Static Mappings for this Interface : ( Get the MAC address of VM-OSE interface from all the newly create VM & update here )
		
		

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
	
![image](https://user-images.githubusercontent.com/20621916/110901269-07161c80-833f-11eb-9790-203d0197b7b4.png)



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

![image](https://user-images.githubusercontent.com/20621916/110803927-a80ec400-82ba-11eb-81d3-6411a691e2fa.png)

	dnf -y install bind bind-utils

	cp -p /etc/named.conf /etc/named.conf-bkp

	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/named.conf  /etc/named.conf 

	cp  ~/OpenShift-4.7_bare_metal_installation/infra-setup/named.conf.local  /etc/named/named.conf.local

	mkdir /etc/named/zones

	cp  ~/OpenShift-4.7_bare_metal_installation/infra-setup/db.example.com /etc/named/zones/db.example.com

	cp  ~/OpenShift-4.7_bare_metal_installation/infra-setup/db.192.168.1  /etc/named/zones/db.192.168.1

	systemctl enable named && systemctl start named && systemctl status named

**Step 3: Install & Configure HAPROXY**

![image](https://user-images.githubusercontent.com/20621916/110801837-93c9c780-82b8-11eb-9e8d-0d66abe8f2a7.png)

	dnf install haproxy -y
	
	ln -s /usr/sbin/haproxy /usr/sbin/api-haproxy
	
	ln -s /usr/sbin/haproxy /usr/sbin/app-ingress-haproxy
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy  /etc/sysconfig/api-haproxy 
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/app-ingress-haproxy  /etc/sysconfig/app-ingress-haproxy
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy.service  /usr/lib/systemd/system/api-haproxy.service
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy.service  /usr/lib/systemd/system/app-ingress-haproxy.service
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/api-haproxy.cfg  /etc/api-haproxy/api-haproxy.cfg
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/app-ingress-haproxy.cfg  /etc/api-haproxy/app-ingress-haproxy.cfg
	
	systemctl enable api-haproxy && systemctl start api-haproxy && systemctl status api-haproxy
	
	systemctl enable app-ingress-haproxy && systemctl start app-ingress-haproxy && systemctl status app-ingress-haproxy
	
	Validation:
	
	http://api-lb.example.com:9000/
	
	http://app-ingress-lb.example.com:9000/


**Step 4: Install & Configure HTTPD Server**

	dnf install -y httpd
	
	cp -p /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf-bkp
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/httpd.conf /etc/httpd/conf/httpd.conf
   	
	mkdir -p /etc/systemd/system/httpd.service.d
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/override.conf  /etc/systemd/system/httpd.service.d/override.conf 
	
	systemctl enable httpd && systemctl start httpd && systemctl status httpd
	
	Validation:
	
  	http://http-server.example.com:8080/
        
**Step 5: Install & Configure NFS Server**

	dnf install -y nfs-utils
	
	mkdir -p /var/nfsshare/registry
	
	chmod -R 777 /var/nfsshare
	
	chown -R nobody:nobody /var/nfsshare
	
	cp ~/OpenShift-4.7_bare_metal_installation/infra-setup/exports /etc/exports
	
	systemctl enable nfs-server rpcbind && systemctl start nfs-server rpcbind
	
	showmount -e nfs-server
	
	

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

Create login id in https://cloud.redhat.com/openshift   -->  Create Cluster --> Datacenter  --> Bare Metal --> User-provisioned infrastructure --> Copy pull secret 

![image](https://user-images.githubusercontent.com/20621916/110893983-fd39ec80-8331-11eb-8d30-fef351a9f098.png)


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


**Login to workstation** 

export KUBECONFIG=~/ose-install/auth/kubeconfig

oc whoami

oc get nodes

oc get csr

Approve all the pending CSR

oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve

oc get csr

Keep checking & approving the pending CSR.  Stop once all nodes( master & worker ) are in ready state. 

Wait till the console operator & other are fully up. 

watch -n5 oc get clusteroperators


Default Kubeadmin password 

cat ~/ose-install/auth/kubeadmin-password

**Update  your workstation network interface card's  primary dns to 192.168.1.4 & secondary dns to google ( 8.8.8.8 or your network dns.  Otherwise we will endup manually updating the window's host file for each wildcard entry**

![image](https://user-images.githubusercontent.com/20621916/110895988-a6cead00-8335-11eb-9879-6dabbf7838d5.png)



 Window's host file location:	C:\Windows\System32\drivers\etc\hosts


https://console-openshift-console.apps.ose.example.com/


**Gracefull shutdown of cluster**

https://docs.openshift.com/container-platform/4.7/backup_and_restore/graceful-cluster-shutdown.html


nodes=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')


for node in ${nodes[@]}

do

    echo "==== Shut down $node ===="
    
    ssh core@$node sudo shutdown -h 1
    
done

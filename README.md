# OpenShift 4.7 Installation on Bare Metal using UPI method:


![image](https://user-images.githubusercontent.com/20621916/111890054-0a856400-8a21-11eb-995c-f8ac8c9dd97d.png)


![image](https://user-images.githubusercontent.com/20621916/111890102-7c5dad80-8a21-11eb-82bb-1e1331f19fc4.png)


![image](https://user-images.githubusercontent.com/20621916/111868634-096b1d00-89b6-11eb-9f94-625fefea2d89.png)

Install Vmware workstation 16 pro on Highend Workstation.

Vmware workstation 16pro setup :

1. Create a hostonly network with 192.168.1.0/24  -- Name : OSEnet

2. Create VMs with the below specs.

	1. pfsense VM ( act as router & dhcp )
	
	    	
		Guest Operation system : Other -> FreeBSD 12 64-bit
		
                Memory : 2 GB /Cpu: 2/Disk : 512GB
		
                Network Adapter : 1 from Bridged  &  1 from OSEnet
		
	   	OS image - https://www.pfsense.org/download/     --> AMD64(64-bit) & DVD Image (ISO) installer
		
                Boot the server & accept all the default options
		
                Once server is up, login to console  https://192.168.1.1  & complete the initial setup
		
                User: admin / Password: pfsense



	2.  ose-infra-server & workstation  ( Centos8  with Minimal Installation)
 		
		Memory : 2 GB /Cpu: 2/Disk : 512GB
		
	        Network Adapter : 1 from OSEnet
		
		OS image : https://www.centos.org/download/
		

	3. bootstrap, master1, master2, worker1 & worker2
	
		Guest Operation system : Linux -> Other Linux5.x and later kernel 64-bit
		
                Memory : 32 GB /Cpu: 16/Disk : 1024TB
		
                Network Adapter :  1 from OSEnet
		
		RHCOS latest image : https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-live.x86_64.iso
		
		
	4. Configure DHCP server

		https://192.168.1.1/  --> Services --> DHCP Server --> Select Enable --> Range ( 192.168.1.50  - 192.168.1.60)
		
		DNS server : 192.168.1.4 & 8.8.8.8
		
		Gateway : 192.168.1.1
		
		Domain name : example.com
		
		Domain search list : example.com;ose.example.com
		
		DHCP Static Mappings for this Interface : ( Get the MAC address of OSEnet interface from all the newly create VM & update here )
		
		![image](https://user-images.githubusercontent.com/20621916/111874323-b1d9ab00-89cf-11eb-8fc2-150ca98f4652.png)




**Infra Server Setup ( ose-infra-server & workstation ):**


**Step 1**: ( ose-infra-server & Workstation - CentOS 8 Minimal Installation ) - https://www.centos.org/download/
	
	Install the required binaries: 
        
		dnf -y install net-tools telnet curl wget traceroute nmap-ncat git  httpd-tools jq  nfs-utils
	 
	Stop & disable firewalld :
	
        	systemctl stop firewalld && systemctl disable firewalld
	
	Stop & disable Selinux :
        
        	sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config && setenforce 0
        
	Clone the git repo:
	
        	cd ~ && git  clone https://github.com/thomas6m/OpenShift-4.7.2.git
	
![image](https://user-images.githubusercontent.com/20621916/111868329-4d5d2280-89b4-11eb-87bb-d2136174ed25.png)



	Plumb all the required virtual IPs. 
	
		Change the interface name as per your server's naming convention:
	
		cp  ~/OpenShift-4.7.2/infra-setup/ifcfg-ens32*  /etc/sysconfig/network-scripts/
	 
		
	Disable Ipv6:
	
		cp ~/OpenShift-4.7.2/infra-setup/70-ipv6.conf /etc/sysctl.d/70-ipv6.conf
	
        	sysctl --load /etc/sysctl.d/70-ipv6.conf
	
	Install the latest Patches:
	
		dnf install -y epel-release && dnf update -y && reboot
		

**Infra Services Setup:**

**Step 2: Install & Configure DNS server**

![image](https://user-images.githubusercontent.com/20621916/110803927-a80ec400-82ba-11eb-81d3-6411a691e2fa.png)

	dnf -y install bind bind-utils

	cp -p /etc/named.conf /etc/named.conf-bkp

	cp ~/OpenShift-4.7.2/infra-setup/named.conf  /etc/named.conf 

Note: Replace 192.168.86.0/24 with your WAN network subnet in /etc/named.conf 
      This will allow dns query from your desktop. 

**allow-query     { localhost; 192.168.86.0/24; 192.168.1.0/24; };**



	cp  ~/OpenShift-4.7.2/infra-setup/named.conf.local  /etc/named/named.conf.local

	mkdir /etc/named/zones

	cp  ~/OpenShift-4.7.2/infra-setup/db.example.com /etc/named/zones/db.example.com

	cp  ~/OpenShift-4.7.2/infra-setup/db.192.168.1  /etc/named/zones/db.192.168.1

	systemctl enable named && systemctl start named && systemctl status named

**Step 3: Install & Configure HAPROXY**

![image](https://user-images.githubusercontent.com/20621916/110801837-93c9c780-82b8-11eb-9e8d-0d66abe8f2a7.png)

	dnf install haproxy -y
	

	ln -s /usr/sbin/haproxy /usr/sbin/api-haproxy

	cp ~/OpenShift-4.7.2/infra-setup/api-haproxy  /etc/sysconfig/api-haproxy 

	cp ~/OpenShift-4.7.2/infra-setup/api-haproxy.service  /usr/lib/systemd/system/api-haproxy.service

	cp ~/OpenShift-4.7.2/infra-setup/api-haproxy.cfg  /etc/api-haproxy/api-haproxy.cfg

	systemctl enable api-haproxy && systemctl start api-haproxy && systemctl status api-haproxy


	Validation:
	
	http://192.168.1.7:9000/    		or   	http://api-lb.example.com:9000/


	
	ln -s /usr/sbin/haproxy /usr/sbin/app-ingress-haproxy
	
	cp ~/OpenShift-4.7.2/infra-setup/app-ingress-haproxy  /etc/sysconfig/app-ingress-haproxy
	
	cp ~/OpenShift-4.7.2/infra-setup/app-ingress-haproxy.service  /usr/lib/systemd/system/app-ingress-haproxy.service
	
	cp ~/OpenShift-4.7.2/infra-setup/app-ingress-haproxy.cfg  /etc/api-haproxy/app-ingress-haproxy.cfg
	
	systemctl enable app-ingress-haproxy && systemctl start app-ingress-haproxy && systemctl status app-ingress-haproxy
	
	Validation:
	
	http://192.168.1.8:9000/     		or 	http://app-ingress-lb.example.com:9000/
	


**Step 4: Install & Configure HTTPD Server**

	dnf install -y httpd
	
	cp -p /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf-bkp
	
	cp ~/OpenShift-4.7.2/infra-setup/httpd.conf /etc/httpd/conf/httpd.conf
   	
	mkdir -p /etc/systemd/system/httpd.service.d
	
	cp ~/OpenShift-4.7.2/infra-setup/override.conf  /etc/systemd/system/httpd.service.d/override.conf 
	
	systemctl enable httpd && systemctl start httpd && systemctl status httpd
	
	Validation:
	
  	http://http-server.example.com:8080/
        
**Step 5: Install & Configure NFS Server**

	dnf install -y nfs-utils
	
	mkdir -p /var/nfsshare/registry
	
	chmod -R 777 /var/nfsshare
	
	chown -R nobody:nobody /var/nfsshare
	
	cp ~/OpenShift-4.7.2/infra-setup/exports /etc/exports
	
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

cd ~ &&  git clone https://github.com/thomas6m/OpenShift-4.7.2.git

![image](https://user-images.githubusercontent.com/20621916/111888980-639ec900-8a1c-11eb-8426-a51f9ecc0a90.png)


**1. Create Installation Folder**


mkdir ~/ose-install

cat ~/.ssh/id_rsa.pub



Create login id in https://cloud.redhat.com/openshift   -->  Create Cluster --> Datacenter  --> Bare Metal --> User-provisioned infrastructure --> Copy pull secret 

![image](https://user-images.githubusercontent.com/20621916/110893983-fd39ec80-8331-11eb-8d30-fef351a9f098.png)

**2. Create Install-config yaml file**

cp ~/OpenShift-4.7.2/ocp-4.7/install-config.yaml  ~/ose-install/


add ssh public key & pull secret in  ~/ose-install/install-config.yaml

**3. Generate Kubernetes manifests**

openshift-install create manifests --dir=ose-install/

**4. Generate RHCOS ignition config files**


openshift-install create ignition-configs --dir=ose-install/

tar -cvf ose-install.tar ose-install

scp ose-install.tar root@ose-infra-server:/tmp/

**Login to ose-infra-server** 

cd ~ ; tar -xvf /tmp/ose-install.tar

mkdir /var/www/html/ose

cp -R ~/ose-install/* /var/www/html/ose/

chown -R apache: /var/www/html/

chmod -R 755 /var/www/html/

**5. Start the Installation** 

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

cp ~/OpenShift-4.7.2/infra-setup/api-haproxy.cfg-without-bootstrap  /etc/api-haproxy/api-haproxy.cfg

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

Wait till the console operator & other operators are fully up. 

![image](https://user-images.githubusercontent.com/20621916/111869070-826b7400-89b8-11eb-9d9f-526ad2374ef8.png)


watch -n 0.1 oc get clusteroperators

![image](https://user-images.githubusercontent.com/20621916/111870896-3a514f00-89c2-11eb-9b59-1e1beac0a8a6.png)


Default Kubeadmin password 

cat ~/ose-install/auth/kubeadmin-password

**Update  your workstation network interface card's  primary dns to 192.168.1.4 & secondary dns to google ( 8.8.8.8 or your network dns.  Otherwise we will endup manually updating the window's host file for each wildcard entry**

![image](https://user-images.githubusercontent.com/20621916/110895988-a6cead00-8335-11eb-9879-6dabbf7838d5.png)



 Window's host file location:	C:\Windows\System32\drivers\etc\hosts


https://console-openshift-console.apps.ose.example.com/

**Image registry removed during installation :**

On platforms that do not provide shareable object storage, the OpenShift Image Registry Operator bootstraps itself as Removed. 
This allows openshift-installer to complete installations on these platform types.

After installation, we must edit the Image Registry Operator configuration to switch the managementState from Removed to Managed.


**Image registry storage configuration:**


oc get pod -n openshift-image-registry


![image](https://user-images.githubusercontent.com/20621916/111872517-cc5c5600-89c8-11eb-8775-da704553e5b0.png)


showmount -e nfs-server.example.com



![image](https://user-images.githubusercontent.com/20621916/111871992-e9445980-89c7-11eb-8e83-04129e0bc607.png)


oc get pv



![image](https://user-images.githubusercontent.com/20621916/111871999-f3feee80-89c7-11eb-8140-d7f9002dbb61.png)


cd /root/OpenShift-4.7.2/ocp-4.7

cat registry_pv.yaml

oc create -f registry_pv.yaml

![image](https://user-images.githubusercontent.com/20621916/111872007-02e5a100-89c8-11eb-872d-e0e7214a0e13.png)




oc get pv

oc edit configs.imageregistry.operator.openshift.io

![image](https://user-images.githubusercontent.com/20621916/111871879-51467000-89c7-11eb-8327-95fa2c042202.png)

Change the managmentState: from Removed to Managed. 

Under storage: add the pvc: and claim: blank to attach the PV and save your changes

![image](https://user-images.githubusercontent.com/20621916/111871933-a08ca080-89c7-11eb-8ea3-6b5c8ad8beac.png)


oc get pv

![image](https://user-images.githubusercontent.com/20621916/111872186-b64e9580-89c8-11eb-9814-5180e7d3086b.png)



![image](https://user-images.githubusercontent.com/20621916/111873237-548f2b00-89ca-11eb-8bd9-03e645e736a2.png)


**Configuring an HTPasswd identity provider:**


To define an HTPasswd identity provider we must perform the following steps:

1. Create an htpasswd file to store the user and password information.

cd /root/OpenShift-4.7.2/ocp-4.7

cat my_htpasswd_provider.yaml

htpasswd -c -B -b </path/to/users.htpasswd> <user_name> <password>

htpasswd -c -B -b  users.htpasswd  user1  password1

![image](https://user-images.githubusercontent.com/20621916/111873810-2828de00-89cd-11eb-956a-b76654ac08a0.png)


2. Create an OpenShift Container Platform secret to represent the htpasswd file.

oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config

![image](https://user-images.githubusercontent.com/20621916/111873826-3676fa00-89cd-11eb-871e-10fb09df79f6.png)


3. Define the HTPasswd identity provider resource.

cat my_htpasswd_provider.yaml

![image](https://user-images.githubusercontent.com/20621916/111873793-147d7780-89cd-11eb-9510-99b885dcfc94.png)


4. Apply the resource to the default OAuth configuration.

oc apply -f my_htpasswd_provider.yaml


oc adm policy add-cluster-role-to-user cluster-admin <username>

oc adm policy add-cluster-role-to-user cluster-admin user1

![image](https://user-images.githubusercontent.com/20621916/111873939-c2892180-89cd-11eb-91da-00d73bac7367.png)


Login to the console with new user

https://console-openshift-console.apps.ose.example.com/

![image](https://user-images.githubusercontent.com/20621916/111873871-7807a500-89cd-11eb-9468-08decec35d3c.png)


![image](https://user-images.githubusercontent.com/20621916/111873979-f7957400-89cd-11eb-862e-ea8a889e6196.png)



**Gracefull shutdown of cluster**


Execute the below command from workstation server

export KUBECONFIG=~/ose-install/auth/kubeconfig

nodes=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')

for node in ${nodes[@]}

do

    echo "==== Shut down $node ===="
    
    ssh core@$node sudo shutdown -h 1
    
done

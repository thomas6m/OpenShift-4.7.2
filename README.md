# OpenShift Container Platform 4.7 installation on bare metal
OpenShift Container Platform 4.7 installation on bare metal


![image](https://user-images.githubusercontent.com/20621916/110802174-e7d4ac00-82b8-11eb-9201-2b50f9cb8a0d.png)

![image](https://user-images.githubusercontent.com/20621916/110803087-cd4f0280-82b9-11eb-8772-615f6b978524.png)

![image](https://user-images.githubusercontent.com/20621916/110800131-dbe7ea80-82b6-11eb-9529-f5fe780a4b97.png)

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

**Monitor the installation status **

openshift-install --dir ~/ose-install wait-for bootstrap-complete --log-level=debug

http://api-lb.example.com:9000/

openshift-install --dir ~/ose-install wait-for install-complete

Once bootstrap complete. Remove the bootstrap entry from api-load balancer.

**Login to ose-infra server**

sed -i.bak '/ bootstrap / s/^\(.*\)$/#\1/g' /etc/api-haproxy/api-haproxy.cfg

systemctl restart api-haproxy

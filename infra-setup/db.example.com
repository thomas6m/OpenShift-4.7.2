$TTL    604800
@       IN      SOA     dns-server.example.com. admin.example.com. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Negative Cache TTL
)

; name servers - NS records
    IN      NS      dns-server

; name servers - A records
dns-server.example.com.         IN      A       192.168.1.4

; INFRA - A records
pfsense.example.com.            IN      A       192.168.1.1
ose-infra-server.example.com.   IN      A       192.168.1.3
nfs-server.example.com.         IN      A       192.168.1.5
http-server.example.com.        IN      A       192.168.1.6
api-lb.example.com.             IN      A       192.168.1.7
app-ingress-lb.example.com.     IN      A       192.168.1.8
workstation.example.com.        IN      A       192.168.1.9

; OSE - A records
bootstrap.ose.example.com.      IN      A       192.168.1.200
master1.ose.example.com.        IN      A       192.168.1.201
master2.ose.example.com.        IN      A       192.168.1.202
master3.ose.example.com.        IN      A       192.168.1.203
worker1.ose.example.com.        IN      A       192.168.1.204
worker2.ose.example.com.        IN      A       192.168.1.205

; OpenShift internal cluster IPs - A records
api.ose.example.com.           IN       A       192.168.1.7
api-int.ose.example.com.       IN       A       192.168.1.7
*.apps.ose.example.com.        IN       A       192.168.1.8
etcd-0.ose.example.com.        IN       A       192.168.1.201
etcd-1.ose.example.com.        IN       A       192.168.1.202
etcd-2.ose.example.com.        IN       A       192.168.1.203

; OpenShift internal cluster IPs - SRV records
_etcd-server-ssl._tcp.ose.example.com.    86400     IN    SRV     0    10    2380    etcd-0.ose
_etcd-server-ssl._tcp.ose.example.com.    86400     IN    SRV     0    10    2380    etcd-1.ose
_etcd-server-ssl._tcp.ose.example.com.    86400     IN    SRV     0    10    2380    etcd-2.ose

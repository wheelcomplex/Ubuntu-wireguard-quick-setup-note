
# wireguard
# https://securityespresso.org/tutorials/2019/03/22/vpn-server-using-wireguard-on-ubuntu/

#
# NOTE: please use your own keys, created by wg genkey
#       all client side traffic will route to server by vpn
#       Mobile client also works with this server

# everything is done by root

# sudo -s

apt install -y software-properties-common

add-apt-repository ppa:wireguard/wireguard
apt update

apt install -y wireguard
modprobe -v wireguard
lsmod | grep wireguard

cat << EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
sysctl -p

# server (wireguardserver.example.com) side setup
# replace wireguardserver.example.com with your own hostname or IP

# all private key should create locally and offer the pub key to remote
# get pubkey by: echo <PRIKEY> | wg pubkey

cat << EOF > /etc/wireguard/wg0.conf 
[Interface]
# get prikey by: wg genkey
PrivateKey = MM55jiuicoantGu4FEjS0NZb+hJ9Gv+aCm9Vp11yeHI=
# get pubkey by: echo MM55jiuicoantGu4FEjS0NZb+hJ9Gv+aCm9Vp11yeHI= | wg pubkey
# pubkey: zGWeQ+8a4b3dyawYuV+aNZLzS0ED/NxS1nWMkDqm+VQ=
Address = 10.0.0.1/24
SaveConfig = false
PostUp = /etc/wireguard/wg0.up.sh
PostDown = /etc/wireguard/wg0.down.sh
ListenPort = 51000

[Peer]
PublicKey = SSV3rVjv0CuE7qNkY2NaNIi1oWvojxoCYfJk8LASc1E=
AllowedIPs = 10.0.0.2/32

[Peer]
PublicKey = AwWn5bSg0QNC10JOVK2AOfxNDHcHzWqDBlxo7QGjRhQ=
AllowedIPs = 10.0.0.3/32
# add more [Peer] section if you want more client/peer.
EOF

# eth0 is your WAN interface
cat << EOF > /etc/wireguard/wg0.up.sh 
#!/bin/sh
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -A FORWARD -i wg0 -j ACCEPT
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# for virtual server on peer host
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 60002 -j DNAT --to-destination 10.0.0.2
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 60003 -j DNAT --to-destination 10.0.0.3

EOF

cat << EOF > /etc/wireguard/wg0.down.sh 
#!/bin/sh
iptables -D FORWARD -i wg0 -j ACCEPT
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ip6tables -D FORWARD -i wg0 -j ACCEPT
ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 60002 -j DNAT --to-destination 10.0.0.2
iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 60003 -j DNAT --to-destination 10.0.0.3
EOF

chmod -R 0700 /etc/wireguard/*.*

cat /etc/wireguard/wg0.conf

systemctl stop wg-quick@wg0

wg-quick down wg0

wg-quick up wg0

wg show

# on boot
systemctl enable wg-quick@wg0

wg-quick down wg0

systemctl stop wg-quick@wg0

systemctl start wg-quick@wg0

wg show

systemctl status wg-quick@wg0

# end of server setup

#### client setup

apt install -y software-properties-common
add-apt-repository ppa:wireguard/wireguard
apt update

apt install -y wireguard
modprobe -v wireguard
lsmod | grep wireguard

mkdir -p /etc/wireguard/

cat << EOF >/etc/wireguard/wg0.conf
[Interface]
# get prikey by: wg genkey
PrivateKey = EGBeezHFZ5TCXQh8pVEu9/IqRDdU9YyJd0t9J16RTlI=
# get pubkey by: echo EGBeezHFZ5TCXQh8pVEu9/IqRDdU9YyJd0t9J16RTlI= | wg pubkey
# PublicKey = DdeerVjv0CuE7qNkY2NaNIi1oWvojxoCYfJk8LASc1E=
Address = 10.0.0.2/24

[Peer]
# the pub key of server
PublicKey = zGWeQ+eeZb3dyawYuV+aNZLzS0ED/NxS2nWMkDqm+VQ=
Endpoint = wireguardserver.example.com:51000
AllowedIPs = 0.0.0.0/0
EOF

systemctl stop wg-quick@wg0

wg-quick down wg0

wg-quick up wg0

wg show

# on boot
systemctl enable wg-quick@wg0

wg-quick down wg0

systemctl stop wg-quick@wg0

systemctl start wg-quick@wg0

wg show

systemctl status wg-quick@wg0

wg show

ping -c 5 -t 5 10.0.0.1

# TODO: client updown script


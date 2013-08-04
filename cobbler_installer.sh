#!/usr/bin/env bash
#*********************************************************#
# @@ScriptName: cobbler_installer.sh
# @@Author: zhenyu<fjctlzy@gmail.com>
# @@Create Date: 2013-08-04 17:22:12
# @@Modify Date: 2013-08-04 17:22:29
# @@Function:
#*********************************************************#


if [[ `id -u` -ne 0 ]]; then
     echo "The script should be run using Root"
     exit 1
fi

root_password=$1
if [[ -z "root_password" ]]; then
     echo "Root Password is required, Usage: cobbler_installer your_root_password"
     exit 1
fi

rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y cobbler dhcp httpd rsync tftp-server xinetd pykickstart debmirror cman cobbler-web
service httpd start
service cobblerd start
service xinetd start
chkconfig httpd on
chkconfig cobblerd on
chkconfig dhcpd on
chkconfig xinetd on
chkconfig tftp on

#turn off iptables
chkconfig iptables off
service iptables stop

#turn off selinux
sed -i 's;SELINUX=enforcing;SELINUX=disabled;g' /etc/sysconfig/selinux
setenforce 0


#replace all spaces to one space
sed -i 's/^[[:space:]]\+/ /' /etc/cobbler/settings
sed -i -e  "s;manage_dhcp: 0;manage_dhcp: 1;g" -e "s;manage_rsync: 0;manage_rsync: 1;g" -e "s;allow_dynamic_settings: 0;allow_dynamic_settings: 1;g" /etc/cobbler/settings


#install loaders
cobbler get-loaders

#replace dhcp.template
ip=`ifconfig  eth0 | grep "inet addr"  | awk -F: '{print $2}' | awk '{print $1}'`
gateway=`netstat -r | grep default  | awk '{print $2}'`
mask=`ifconfig  eth0 | grep "Mask" | awk -F: '{print $NF}'`
A=`echo $mask | awk -F. '{print $1}'`
B=`echo $mask | awk -F. '{print $2}'`
C=`echo $mask | awk -F. '{print $3}'`
D=`echo $mask | awk -F. '{print $4}'`
a=`echo $ip| awk -F. '{print $1}'`
b=`echo $ip| awk -F. '{print $2}'`
c=`echo $ip | awk -F. '{print $3}'`
d=`echo $ip | awk -F. '{print $4}'`
subnet=`echo $(($a&$A))"."$(($b&$B))"."$(($c&$C))"."$(($d&$D))`

sed -i 's;subnet.*netmask.*;subnet '$subnet' netmask '$mask' {;g' /etc/cobbler/dhcp.template
#option routers
sed -i 's;option routers.*;option routers             '$gateway'\;;g' /etc/cobbler/dhcp.template
#subnet-mask
sed -i 's;option subnet-mask.*;option subnet-mask '$mask'\;;g' /etc/cobbler/dhcp.template

#ip range
sed -i 's/range dynamic-bootp.*/range dynamic-bootp '"$a.$b.$c.10 $a.$b.$c.254"';/g' /etc/cobbler/dhcp.template

#generate default password
cobbler_salt_result=`openssl passwd -1 -salt 'random-phrase-here' "$root_password"`
sed -i 's;default_password_crypted:.*;default_password_crypted: "'${cobbler_salt_result}'";g' /etc/cobbler/settings

#config debmirror
sed -i -e 's;^@dists=;#@dists;g' -e 's;^@arches;#@arches;g' /etc/debmirror.conf

#tftp enable
sed -i 's;disable.*;disable = no;g' /etc/xinetd.d/rsync

#update next_server and server
sed -i 's;next_server.*;next_server: '"$ip"' ;g'  /etc/cobbler/settings
sed -i 's;server:[[:space:]]\+127.0.0.1;server: '"$ip"';g'  /etc/cobbler/settings

#restart the cobbler to make settings work
service cobblerd restart
cobbler sync
cobbler check



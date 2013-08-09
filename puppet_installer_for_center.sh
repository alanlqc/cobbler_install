#!/usr/bin/env bash
#*********************************************************#
# @@ScriptName: puppet_installer_for_center.sh
# @@Author: zhenyu<fjctlzy@gmail.com>
# @@Create Date: 2013-08-09 08:23:25
# @@Modify Date: 2013-08-09 16:19:17
# @@Function:
#*********************************************************##!/usr/bin/env bash
#*********************************************************#
# @@ScriptName: puppet_installer_for_center.sh
# @@Author: zhenyu<fjctlzy@gmail.com>
# @@Create Date: 2013-08-09 08:23:17
# @@Modify Date: 2013-08-09 15:59:54
# @@Function:
#*********************************************************#

hostname = `awk -F= '/hostname/ {print $2}' config`

#add puppetlabs repo
cobbler repo add --mirror=http://yum.puppetlabs.com/el/6/products/x86_64/ --name=puppetlabs
cobbler reposync

cobbler repo add --mirror=http://yum.puppetlabs.com/el/6/dependencies/x86_64/ --name=puppetlabs-deps
cobbler reposync

echo '[puppetlabs]
name=Puppet Labs Packages
baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs' > /etc/yum.repos.d/puppet.repo

yum install -y yum-utils puppet puppet-server cman

sed -i 's;puppet_auto_setup:.*;puppet_auto_setup: 1;g' /etc/cobbler/settings
sed -i 's;sign_puppet_certs_automatically:.*;sign_puppet_certs_automatically: 1;g' /etc/cobbler/settings
sed -i 's;remove_old_puppet_certs_automatically:.*;remove_old_puppet_certs_automatically: 1;g' /etc/cobbler/settings

service cobblerd restart


echo "[main]
    logdir = /var/log/puppet
    rundir = /var/run/puppet
    ssldir = $vardir/ssl
    server = puppet
    report = true
    pluginsync = true
    certname = $hostname
[agent]
    classfile = $vardir/classes.txt
    localconfig = $vardir/localconfig
" >  /etc/puppet/puppet.conf

/etc/init.d/puppetmaster start
chkconfig puppetmaster on

echo "Don't forget to reboot"

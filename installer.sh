#!/usr/bin/env bash
#*********************************************************#
# @@ScriptName: installer.sh
# @@Author: zhenyu<fjctlzy@gmail.com>
# @@Create Date: 2013-08-09 16:10:06
# @@Modify Date: 2013-08-09 16:15:16
# @@Function:
#*********************************************************#
grep -qiE "centos|redhat|fedora" /etc/redhat-release || (echo "Only support CentOS|Redhat|Fedora" && exit 1;)
sh cobbler_installer_for_centos.sh
sh puppet_installer_for_centos.sh



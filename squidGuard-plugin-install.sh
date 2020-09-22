#!/bin/sh
#    Copyright (C) 2019-2020 Cloudfence - JCC
#    All rights reserved.
#
#    Redistribution and use in source and binary forms, with or without
#    modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
#    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
#    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
#    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#    POSSIBILITY OF SUCH DAMAGE.
#    --------------------------------------------------------------------------------------

# Download from Github

# Vars
REPO_URL="https://github.com/cloudfence/dev-packages/raw/master/"
PKG_CMD=$(which pkg)
PKG_CACHE="/var/cache/pkg/"
ASSUME_ALWAYS_YES=YES
export ASSUME_ALWAYS_YES

# Requirements check
OPN_VER=$(/usr/local/sbin/opnsense-version | awk '{print $2}' | cut -d. -f1,2)

if [ "$OPN_VER" == "20.7" ];then 
    echo "Hello OPNSense $OPN_VER"
    PKG_WF="os-squidGuard-latest-dev-BSD12.txz"
elif [ "$OPN_VER" == "20.1" ];then
    echo "Hello OPNSense $OPN_VER"
    PKG_WF="os-squidGuard-latest-dev-BSD11.txz"    
else
    echo "Your OS version is not supported, sorry!"
    exit
fi

uninstall()
{
# lock packages
$PKG_CMD lock pkg
$PKG_CMD lock opnsense
$PKG_CMD lock squid
$PKG_CMD lock python37

$PKG_CMD remove db5
}

setup ()
{

echo "

Copyright (C) 2019-2020 Cloudfence - Julio Camargo
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

"

while true;
    do
        read -p  "Do you ACCEPT the BSD license and terms? [y/n]" ANSWER
        case $ANSWER in
            [Yy]* ) echo "Terms accepted!"; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer [y]es or [n]o.";;
        esac
    done


# lock packages
$PKG_CMD lock pkg
$PKG_CMD lock opnsense
$PKG_CMD lock squid

# Enable FreeBSD repo to download SquidGuard port
cat /usr/local/etc/pkg/repos/FreeBSD.conf | sed 's/no/yes/g' > /tmp/FreeBSD.conf
mv /tmp/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf

$PKG_CMD install -r FreeBSD -F squidguard

SGUARD=$(ls /var/cache/pkg/ | grep squidGuard | tail -1)
$PKG_CMD add -M /var/cache/pkg/$SGUARD

# Disable FreeBSD Repo
cat /usr/local/etc/pkg/repos/FreeBSD.conf | sed 's/yes/no/g' > /tmp/FreeBSD.conf
mv /tmp/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf


# unlock packages
$PKG_CMD unlock pkg
$PKG_CMD unlock opnsense
$PKG_CMD unlock squid

$PKG_CMD add -f /tmp/$PKG_WF

$PKG_CMD update
}

check_version()
{
# download
echo "Fetching package..."
fetch $REPO_URL/$PKG_WF -o /tmp
sleep 3

VERSION=$(pkg query %v os-squidGuard)
LOCAL_VER=$(pkg query -F /tmp/$PKG_WF %v)


# Not installed
if [ -z "$VERSION" ];then
    setup
# Installed - same versions
elif [ "$VERSION" = "$LOCAL_VER" ];then
    echo "You have latest package installed"
    local ANSWER
    while true;
    do
        read -p  "Do you want to UNINSTALL [y]es/[n]o) or FORCE (f) reinstall the WebFilter plugin?" ANSWER
        case $ANSWER in
            [Yy]* ) uninstall; break;;
            [Ff]* ) setup; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer [y]es or [n]o.";;
        esac
    done

# Installed - different versions
elif [ "$VERSION" != "$LOCAL_VER" ];then
    echo "You have the version $VERSION installed, new version $LOCAL_VER found"
    echo "Updating..."
    setup
fi

}

while true;
    do
        read -p  "Do you want to install the WebFilter plugin? [y/n]" ANSWER
        case $ANSWER in
            [Yy]* ) check_version; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer [y]es or [n]o.";;
        esac
    done

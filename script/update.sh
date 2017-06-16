#!/bin/bash -eux

export DEBIAN_FRONTEND=noninteractive

echo "==> Disabling the release upgrader"
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

echo "==> Set dpkg options to disable config file updates"
touch /etc/apt/apt.conf.d/local
echo <<- EOF >> /etc/apt/apt.conf.d/local
    DPkg::Options {
        "--force-confdef";
        "--force-confold";
    }
EOF

echo "==> Checking version of Ubuntu"
. /etc/lsb-release

if [[ $DISTRIB_RELEASE == 16.04 || $DISTRIB_RELEASE == 16.10 ]]; then
    echo "==> Disabling periodic apt upgrades"
    echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic
fi

echo "==> Stop and disable background updates"
if [[ $DISTRIB_RELEASE == 16.04 || $DISTRIB_RELEASE == 16.10 ]]; then
    systemctl disable apt-daily.service
    systemctl disable apt-daily.timer
fi

service unattended-upgrades stop

killall apt-get || true
killall apt.systemd.daily || true

apt-get remove unattended-upgrades -y

echo "==> Updating list of packages"
apt-get update

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Performing dist-upgrade (all packages and kernel)"
    
    if [[ $DISTRIB_RELEASE == 16.04 || $DISTRIB_RELEASE == 16.10 ]]; then
        apt-get --assume-yes dist-upgrade
    else 
        apt-get --assume-yes --force-yes dist-upgrade
    fi

    reboot now
fi

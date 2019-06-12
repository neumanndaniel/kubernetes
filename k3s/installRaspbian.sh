#!/bin/bash

set -e
set -o pipefail

RPHOSTNAME=$1
RPMOUNTPATH=$2
PUBLICSSHKEY=$3
RPTIMEZONE=$4

IMAGE=$(ls raspbian.img)
if [ -z "$IMAGE" ]
then
    wget https://downloads.raspberrypi.org/raspbian_lite_latest -O raspbian.zip
    unzip raspbian.zip
    mv *.img raspbian.img
    rm -f raspbian.zip
fi

sudo dd bs=1M if=raspbian.img of=/dev/sda status=progress

sudo mkdir $RPMOUNTPATH
sudo mount /dev/sda2 $RPMOUNTPATH
cat wpa_supplicant.conf | sudo tee -a $RPMOUNTPATH/etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
echo $RPHOSTNAME | sudo tee $RPMOUNTPATH/etc/hostname > /dev/null
echo "127.0.1.1       $RPHOSTNAME" | sudo tee -a $RPMOUNTPATH/etc/hosts

sudo rm $RPMOUNTPATH/etc/localtime
sudo cp $RPMOUNTPATH/usr/share/zoneinfo/$RPTIMEZONE $RPMOUNTPATH/etc/localtime

sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' $RPMOUNTPATH/etc/ssh/sshd_config
sudo sed -i 's/^UsePAM yes/UsePAM no/g' $RPMOUNTPATH/etc/ssh/sshd_config
sudo mkdir $RPMOUNTPATH/home/pi/.ssh
echo -n $PUBLICSSHKEY >> authorized_keys
sudo mv authorized_keys $RPMOUNTPATH/home/pi/.ssh/
chmod 644 $RPMOUNTPATH/home/pi/.ssh/authorized_keys

sudo umount $RPMOUNTPATH
sudo mount /dev/sda1 $RPMOUNTPATH
sudo touch $RPMOUNTPATH/ssh

echo -n ' cgroup_enable=cpuset cgroup_enable=memory' | sudo tee -a $RPMOUNTPATH/cmdline.txt
sudo sh -c "tr -d '\n' < $RPMOUNTPATH/cmdline.txt > $RPMOUNTPATH/cmdline2.txt"
sudo mv $RPMOUNTPATH/cmdline2.txt $RPMOUNTPATH/cmdline.txt

sudo umount $RPMOUNTPATH

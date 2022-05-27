#!/bin/bash
# add dns records
echo -e "Setting bastion dns...\n"
sleep 1
rsync -P /etc/hosts root@bastion:/etc/hosts >/dev/null
ssh root@bastion "echo '172.25.250.14 servere.lab.example.com servere' >> /etc/hosts "
ssh root@bastion "systemctl restart dnsmasq.service"  >/dev/null
# add a new virtual machine servere
echo -e "Add a new virtual machine servere...\n"
sleep 1
if [ $UID -ne 0 ];then
	echo ""Error: This command has to be run under the root user.
else
# Check whether servere exists, and delete it if it exists
virsh list --all | grep servere &>/dev/null
if [ $? -eq 0 ];then
	echo "Delete the existing servere..."
	virsh destroy --domain servere  2>/dev/null
	virsh undefine --domain servere
 	rm -f /var/lib/libvirt/images/servere-vda.qcow2
	ps -Ao comm | grep virt-viewer
	if [ $? -eq 0 ];then
	kill -9 $(ps -Ao pid,comm | grep 'virt-viewer' | awk '{print $1}')
	fi
fi
virt-install \
	--name servere \
	--memory 2048 \
	--vcpus 2 \
	--disk /var/lib/libvirt/images/servere-vda.qcow2,size=10,format=qcow2,target.bus=virtio \
	--network network=privbr0,mac.address=52:54:00:00:fa:0e,model=virtio \
	--graphics type=spice,listen=127.0.0.1 \
	--noautoconsole \
	--os-type=linux \
	--os-variant rhel8.2 \
	--machine q35 \
	--boot hd,network,cdrom >/dev/null
	#--boot uefi \
	#--extra-args "ks=http://servera.lab.example.com/ks/install.ks" \
	#--cdrom=/content/rhel8.2/x86_64/isos/rhel-8.2-x86_64-dvd.iso 
#--machine KVM \
	#--install kernel_args="console=tty0 console=ttyS0,115200n8" \
	#--graphics type=spice,port=5908,tlsPort=5908,listen=127.0.0.1 \
virt-viewer servere &
#echo -e "Plese use user kiosk and below command view the servere\n"
#echo "virt-viewer -c qemu:///system servere &> /dev/null &"
fi

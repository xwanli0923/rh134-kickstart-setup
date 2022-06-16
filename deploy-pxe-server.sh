#!/bin/bash -e
function deploy_servera {
	yum -y install httpd  dhcp-server tftp-server syslinux
	mkdir /var/www/html/ks
	cp -v serverc.ks /var/www/html/ks/
	cp -v servere.ks /var/www/html/ks/
	chmod 644 /var/www/html/ks/serverc.ks
	chmod 644 /var/www/html/ks/servere.ks
        systemctl enable httpd.service --now

	rm -f /etc/dhcp/dhcpd.conf
	cp -vf dhcpd.conf.example /etc/dhcp/dhcpd.conf 
        systemctl enable dhcpd.service --now

	rsync -uP /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
	wget  -r -nd -np -A cat,msg,conf,img,bin,cfg,c32,png,vmlinuz,memtest  http://content.example.com/rhel8.2/x86_64/dvd/isolinux/ -P /var/lib/tftpboot/
	rm -f /var/lib/tftpboot/grub.conf
	cp -v grub.conf /var/lib/tftpboot/grub.conf
	mkdir /var/lib/tftpboot/pxelinux.cfg
	cp default /var/lib/tftpboot/pxelinux.cfg/
	cp splash.png /var/lib/tftpboot/pxelinux.cfg/
	chmod 644 /var/lib/tftpboot/pxelinux.cfg/default
	chmod 644 /var/lib/tftpboot/pxelinux.cfg/splash.png
        
	cp -v tftp.socket /etc/systemd/system/tftp-server.socket
        cp -v tftp.service /etc/systemd/system/tftp-server.service
	systemctl daemon-reload
	systemctl enable tftp-server.socket --now
	systemctl stop firewalld && setenforce 0
}

if [ $HOSTNAME == servera.lab.example.com ] && [ $UID == 0 ];then
	deploy_servera
else
	echo "Error: This command has to be run under the root user."
fi

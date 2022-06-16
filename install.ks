<<<<<<< Updated upstream
#version=RHEL8
# System bootloader configuration
bootloader --append="console=ttyS0 console=ttyS0,115200n8 no_timer_check net.ifnames=0  crashkernel=auto" --location=mbr --timeout=1 --boot-drive=vda
# Reboot after installation
reboot
# Use text mode install
text
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts=''
# System language
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp --device=link --activate
network  --hostname=serverc.lab.example.com
# User information 
user --groups=wheel --name=student --gecos="Student User" --password=student
# Use network installation
url --url=http://172.25.254.254/content/rhel8.2/x86_64/dvd/
# Root password
rootpw --iscrypted $2b$10$/JathffX.TZKoT9UK4sIOuFpR0bvJ1oQqrQVVrlYFGbJcLalxlBpK
# System authorization information
auth --enableshadow --passalgo=sha512
# SELinux configuration
selinux --enforcing
firstboot --disable
# Firewall configuretion
firewall --enabled --ssh
# Do not configure the X Window System
skipx
# System services
services --disabled="kdump,rhsmcertd" --enabled="sshd,NetworkManager,rngd,chronyd"
# System timezone
timezone Asia/Shanghai --isUtc --ntpserver=172.25.254.250
# Disk partitioning information
part /boot --fstype="xfs" --size=1024 --label=boot
part / --fstype="xfs" --size=1000 --grow --label=root


%pre --erroronfail
/usr/bin/dd bs=512 count=10 if=/dev/zero of=/dev/vda
/usr/sbin/parted -s /dev/vda mklabel msdos
/usr/sbin/parted -s /dev/vda print
%end

%post --erroronfail

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
dnf -C -y remove linux-firmware

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
BOOTPROTOv6="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="yes"
PERSISTENT_DHCLIENT="1"
EOF
# remove ens3 config
rm -f /etc/sysconfig/network-scripts/ifcfg-en* 

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active_profile

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot


# Disable subscription-manager yum plugins
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/product-id.conf
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

echo "Cleaning old yum repodata."
dnf clean all

# Anaconda is writing to /etc/resolv.conf from the generating environment.
# The system should start out with an empty file.
truncate -s 0 /etc/resolv.conf

%end

%packages
@core
NetworkManager
dhcp-client
dnf
dnf-plugin-spacewalk
dnf-utils
dracut-config-generic
dracut-norescue
firewalld
grub2-efi-x64
grub2-pc
insights-client
kernel
kexec-tools
nfs-utils
python3-jsonschema
qemu-guest-agent
redhat-release
redhat-release-eula
rhn-client-tools
rhn-setup
rhnlib
rhnsd
rng-tools
rsync
shim
subscription-manager-cockpit
tar
tcpdump
yum
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-fedora-release
-fedora-repos
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-langpacks-*
-langpacks-en
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%post 
# add yum config 
echo "Configure YUM repository..."
sleep 1
cat > /etc/yum.repos.d/rhel_dvd.repo <<-EOF
[rhel-8.2-for-x86_64-baseos-rpms]
baseurl = http://content.example.com/rhel8.2/x86_64/dvd/BaseOS
enabled = true
gpgcheck = false
name = Red Hat Enterprise Linux 8.2 BaseOS (dvd)

[rhel-8.2-for-x86_64-appstream-rpms]
baseurl = http://content.example.com/rhel8.2/x86_64/dvd/AppStream
enabled = true
gpgcheck = false
name = Red Hat Enterprise Linux 8.2 AppStream (dvd)

EOF

# add pukkey
echo "Add ssh key authentication credentials..."
sleep 1
sed -i 's/^AuthorizedKeysFile.*_keys/AuthorizedKeysFile \/etc\/.rht_authorized_keys .ssh\/authorized_keys/g'  /etc/ssh/sshd_config
cat > /etc/.rht_authorized_keys <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAx/Xk+tLGBCatkBuxzyEXVhupSgb4Lema0PAnM8dFbSxcPz4W4jO8yQgtONzHs8KOhs4J1NG9bHeAwpJa2p9iJkyrigxmQv0LOpvENdlGbA1hwsRoOhBGqwRzSmKHS4Or94FBXvzDwHfbkxDV0XhzHKod8b9tYuaIQfhbF3NUR2ItZiYJhBds+3GOAHhdbU9DOAyX8X60vppkgoJ4nb2Mugw51LM+uVh8ds24wzU3Khr6Dcmae7KX/b/PX0J0rO23ZPq1AJ3i6r13AJUc6beLjQXPzYs/ZLKiQZWaZUePnsiaIpKXpH7vuBK3zidvcK2pf6XXAB9MW7GtoFJnr6v+bQ== InstructorKey
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGtUW3ismHyuCW4CDdTVOOOq6aySdtYenXFWWx7HJa4VTepkG00aaLId9ocra10hc+MB0GTJMCyabDv3i8NKdi6GDH/aOLVsp/Ewy8DEzZMBlJDCt4v2i4/wU4liw6KgEFkZs+5hnqU8d4QzldyGJ5onr+AGvFOKG68CS0BBl40Z1twf1HhCyx8k6nzD2ovlkxWRFZKPAFrtPCBVvQDkOfVFZF+lwzaSztgAjbFZ4A9jqQyUYx4kOJ5DtRef36ucdUdVQale0+8lICl7/gb142SPpYfhxe88/BJScLPRjvVNeu1TxRmoHtVazqnAoRxQYAn2MoI6AG+w6QuZf8f7aL LabGradingKey

EOF

cat > /etc/motd.d/kickstart <<-EOF
Generated by Kickstart $(date %F)
EOF

echo "Add new user devops..."
sleep 1
useradd -c "Devops User" -p '$6$1kKj8t6FzCwwDp4j$zdihSUxG/BhI3TmlXAyQtxyBEdQl8ARrEPUWzdYRGYGRKAu.wAHtexsYB.hPHtwk9ElWogqlJGIK6RdkPyIiG/' devops
cat > /etc/sudoers.d/90-cloud-init-users <<-EOF
# Created by kickstart postscript,$(date +%F)

# User rules for devops
devops ALL=(ALL) NOPASSWD:ALL
EOF
%end
=======
#version=RHEL8
# System bootloader configuration
bootloader --append="console=ttyS0 console=ttyS0,115200n8 no_timer_check net.ifnames=0  crashkernel=auto" --location=mbr --timeout=1 --boot-drive=vda
# Reboot after installation
reboot
# Use text mode install
text
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts=''
# System language
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp --device=link --activate
network  --hostname=serverc.lab.example.com
# User information 
user --groups=wheel --name=student --gecos="Student User" --password=student
# Use network installation
url --url=http://172.25.254.254/content/rhel8.2/x86_64/dvd/
# Root password
rootpw --iscrypted $2b$10$/JathffX.TZKoT9UK4sIOuFpR0bvJ1oQqrQVVrlYFGbJcLalxlBpK
# System authorization information
auth --enableshadow --passalgo=sha512
# SELinux configuration
selinux --enforcing
firstboot --disable
# Firewall configuretion
firewall --enabled --ssh
# Do not configure the X Window System
skipx
# System services
services --disabled="kdump,rhsmcertd" --enabled="sshd,NetworkManager,rngd,chronyd"
# System timezone
timezone Asia/Shanghai --isUtc --ntpserver=172.25.254.250
# Disk partitioning information
part /boot --fstype="xfs" --size=1024 --label=boot
part / --fstype="xfs" --size=1000 --grow --label=root


%pre --erroronfail
/usr/bin/dd bs=512 count=10 if=/dev/zero of=/dev/vda
/usr/sbin/parted -s /dev/vda mklabel msdos
/usr/sbin/parted -s /dev/vda print
%end

%post --erroronfail

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
dnf -C -y remove linux-firmware

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
BOOTPROTOv6="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="yes"
PERSISTENT_DHCLIENT="1"
EOF
# remove ens3 config
rm -f /etc/sysconfig/network-scripts/ifcfg-en* 

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active_profile

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot


# Disable subscription-manager yum plugins
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/product-id.conf
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

echo "Cleaning old yum repodata."
dnf clean all

# Anaconda is writing to /etc/resolv.conf from the generating environment.
# The system should start out with an empty file.
truncate -s 0 /etc/resolv.conf

%end

%packages
@core
NetworkManager
dhcp-client
dnf
dnf-plugin-spacewalk
dnf-utils
dracut-config-generic
dracut-norescue
firewalld
grub2-efi-x64
grub2-pc
insights-client
kernel
kexec-tools
nfs-utils
python3-jsonschema
qemu-guest-agent
redhat-release
redhat-release-eula
rhn-client-tools
rhn-setup
rhnlib
rhnsd
rng-tools
rsync
shim
subscription-manager-cockpit
tar
tcpdump
yum
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-fedora-release
-fedora-repos
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-langpacks-*
-langpacks-en
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%post 
# add yum config 
echo "Configure YUM repository..."
sleep 1
cat > /etc/yum.repos.d/rhel_dvd.repo <<-EOF
[rhel-8.2-for-x86_64-baseos-rpms]
baseurl = http://content.example.com/rhel8.2/x86_64/dvd/BaseOS
enabled = true
gpgcheck = false
name = Red Hat Enterprise Linux 8.2 BaseOS (dvd)

[rhel-8.2-for-x86_64-appstream-rpms]
baseurl = http://content.example.com/rhel8.2/x86_64/dvd/AppStream
enabled = true
gpgcheck = false
name = Red Hat Enterprise Linux 8.2 AppStream (dvd)

EOF

# add pukkey
echo "Add ssh key authentication credentials..."
sleep 1
sed -i 's/^AuthorizedKeysFile.*_keys/AuthorizedKeysFile \/etc\/.rht_authorized_keys .ssh\/authorized_keys/g'  /etc/ssh/sshd_config
cat > /etc/.rht_authorized_keys <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAx/Xk+tLGBCatkBuxzyEXVhupSgb4Lema0PAnM8dFbSxcPz4W4jO8yQgtONzHs8KOhs4J1NG9bHeAwpJa2p9iJkyrigxmQv0LOpvENdlGbA1hwsRoOhBGqwRzSmKHS4Or94FBXvzDwHfbkxDV0XhzHKod8b9tYuaIQfhbF3NUR2ItZiYJhBds+3GOAHhdbU9DOAyX8X60vppkgoJ4nb2Mugw51LM+uVh8ds24wzU3Khr6Dcmae7KX/b/PX0J0rO23ZPq1AJ3i6r13AJUc6beLjQXPzYs/ZLKiQZWaZUePnsiaIpKXpH7vuBK3zidvcK2pf6XXAB9MW7GtoFJnr6v+bQ== InstructorKey
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGtUW3ismHyuCW4CDdTVOOOq6aySdtYenXFWWx7HJa4VTepkG00aaLId9ocra10hc+MB0GTJMCyabDv3i8NKdi6GDH/aOLVsp/Ewy8DEzZMBlJDCt4v2i4/wU4liw6KgEFkZs+5hnqU8d4QzldyGJ5onr+AGvFOKG68CS0BBl40Z1twf1HhCyx8k6nzD2ovlkxWRFZKPAFrtPCBVvQDkOfVFZF+lwzaSztgAjbFZ4A9jqQyUYx4kOJ5DtRef36ucdUdVQale0+8lICl7/gb142SPpYfhxe88/BJScLPRjvVNeu1TxRmoHtVazqnAoRxQYAn2MoI6AG+w6QuZf8f7aL LabGradingKey

EOF

cat > /etc/motd.d/kickstart <<-EOF
Generated by Kickstart $(date %F)
EOF

echo "Add new user devops..."
sleep 1
useradd -c "Devops User" -p '$6$1kKj8t6FzCwwDp4j$zdihSUxG/BhI3TmlXAyQtxyBEdQl8ARrEPUWzdYRGYGRKAu.wAHtexsYB.hPHtwk9ElWogqlJGIK6RdkPyIiG/' devops
cat > /etc/sudoers.d/90-cloud-init-users <<-EOF
# Created by kickstart postscript,$(date +%F)

# User rules for devops
devops ALL=(ALL) NOPASSWD:ALL
EOF
%end
>>>>>>> Stashed changes

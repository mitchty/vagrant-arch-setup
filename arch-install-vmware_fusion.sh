#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
sfdisk --force /dev/sda <<EOF
# partition table of /dev/sda
unit: sectors

/dev/sda1 : start=  2048, size= 204800, Id=83
/dev/sda2 : start=  206848, size= , Id=83
/dev/sda3 : start=  0, size=  0, Id= 0
/dev/sda4 : start=  0, size=  0, Id= 0
EOF

mkfs.ext2 /dev/sda1
mkfs.ext4 -j /dev/sda2

mount /dev/sda2 /mnt

mkdir /mnt/boot

mount /dev/sda1 /mnt/boot

pacstrap /mnt base base-devel

arch-chroot /mnt pacman -S --noconfirm grub-bios

genfstab -p /mnt >> /mnt/etc/fstab
cat > /mnt/etc/pre.sh <<EOF
echo changeme > /etc/hostname

ln -s /usr/share/zoneinfo/UTC /etc/localtime
my_locale="en_US.UTF-8 UTF-8"
echo ${my_locale} >> /etc/locale.gen

locale-gen
mkinitcpio -p linux

modprobe dm-mod

grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# I HATE YOU SYSTEMD, way to break the most basic of things, grrrr
cat > /etc/systemd/system/rc-local.service <<STUPIDSYSTEMDFIX
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target

STUPIDSYSTEMDFIX
systemctl enable rc-local.service
EOF
arch-chroot /mnt sh -c "bash -x /etc/pre.sh"

umount /mnt/boot
rm /mnt/etc/pre.sh

cat > /mnt/etc/rc.local <<EOF
#!/usr/bin/env sh
systemctl start dhcpcd\@enp2s0
systemctl enable dhcpcd\@enp2s0
sleep 5
rm /etc/rc.local

cat /proc/version > /etc/arch-release

pacman -S --noconfirm open-vm-tools open-vm-tools-modules

modprobe dm-mod

systemctl start vmtoolsd
systemctl enable vmtoolsd

mkdir /mnt/shared
mount /mnt/shared

cat > /etc/systemd/system/mnt-hgfs.mount <<HGFS
[Unit]
Description=Load VMware shared folders
ConditionPathExists=.host:/
ConditionVirtualization=vmware

[Mount]
What=.host:/
Where=/mnt/hgfs
Type=vmhgfs
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
HGFS

cat > /etc/systemd/system/mnt-hgfs.automount <<HGFS
[Unit]
Description=Load VMware shared folders
ConditionPathExists=.host:/
ConditionVirtualization=vmware

[Automount]
Where=/mnt/hgfs

[Install]
WantedBy=multi-user.target
HGFS

mkdir -p /mnt/hgfs

systemctl enable mnt-hgfs.automount

pacman -S --noconfirm openssh

cat >> /etc/ssh/sshd_config <<SSH
Protocol 2
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers vagrant
SSH

systemctl start sshd
systemctl enable sshd.service

pacman -S --noconfirm ruby

mv /etc/gemrc /etc/gemrc.original
gem install --no-rdoc --no-ri  puppet chef
mv /etc/gemrc.original /etc/gemrc

groupadd -g 500 admin
groupadd -g 501 puppet
useradd -g admin -G puppet -m -p changeme -s /bin/bash -u 500 vagrant

mkdir -p /home/vagrant/.ssh
chown vagrant:admin /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
curl -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys
chown vagrant:admin /home/vagrant/.ssh/authorized_keys
chmod 400 /home/vagrant/.ssh/authorized_keys

cat >> /etc/sudoers <<SUDO
%admin ALL=NOPASSWD: ALL
vagrant ALL=(ALL) NOPASSWD: ALL
SUDO

perl -pi -e "s/MODULES\=\"\"/MODULES\=\"vmw\_pvscsi vmblock\"/g" /etc/mkinitcpio.conf

mkinitcpio -p linux

rm -fr /var/cache/pacman/pkg/* /tmp/*

systemctl poweroff
EOF
chmod 755 /mnt/etc/rc.local

umount /mnt

reboot

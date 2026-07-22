wipefs -a /dev/sda
sgdisk -Z /dev/sda
sgdisk -n "0::+512M" -t 0:ef00 -c 0:"EFI System" /dev/sda
sgdisk -n "0::" -t 0:bf00 -c 0:"Solaris root" /dev/sda
sgdisk -p /dev/sdasgdisk -p /dev/sda

ls -l /dev/sd*

mkfs.fat -F32 /dev/sda1

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt base linux linux-firmware vi dosfstools efibootmgr intel-ucode
genfstab -U /mnt >>/mnt/etc/fstab

arch-chroot /mnt
ln -s /usr/share/zoneinfo/Japan /etc/localtime
hwclock --systohc --utc
mkinitcpio -p linux
bootctl --path=/boot install


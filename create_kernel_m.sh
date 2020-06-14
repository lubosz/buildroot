#!/bin/bash
set -e
umask 0022

VERSION="`cat ./version.txt`"

if [ -r "update_m/vmlinuz.bin" ]; then
KERNEL="update_m/vmlinuz.bin"
else
KERNEL=""
fi

if [ -r "update_m/modules.squashfs" ]; then
MODULES_FS="update_m/modules.squashfs"
else
MODULE_FS=""
fi

if [ -r "update_m/mininit-syspart" ]; then
MININIT="update_m/mininit-syspart"
else
MININIT=""
fi

if [ -r "update_m/ubiboot-rg350.bin" ]; then
BOOTLOADERS="update_m/ubiboot-rg350.bin"
else
BOOTLOADERS=""
fi

# TODO: Reinstate this:
# X-OD-Manual=CHANGELOG

# Copy kernel and rootfs to update_m dir.
# We want to support symlinks for the kernel and rootfs images and if no
# copy is made, specifying the symlink will include the symlink in the OPK
# and specifying the real path might use a different name than the update_m
# script expects.
if [ "$KERNEL" ] ; then
	DATE=`date -r "$KERNEL" +%F`
else
	echo "ERROR: No kernel or rootfs found."
	exit 1
fi

if [ "$KERNEL" ] ; then

	chmod a-x "$KERNEL" "$MODULES_FS"

	echo -n "Calculating SHA1 sum of kernel... "
	sha1sum "$KERNEL" | cut -d' ' -f1 > "update_m/vmlinuz.bin.sha1"
	echo "done"

	echo -n "Calculating SHA1 sum of modules file-system... "
	sha1sum "$MODULES_FS" | cut -d' ' -f1 > "update_m/modules.squashfs.sha1"
	echo "done"

	KERNEL="$KERNEL update_m/vmlinuz.bin.sha1"
        MODULES_FS="$MODULES_FS update_m/modules.squashfs.sha1"
fi

if [ "$BOOTLOADERS" ] ; then

	echo -n "Calculating SHA1 sum of bootloaders... "
        sha1sum "$BOOTLOADERS" | cut -d' ' -f1 > "update_m/ubiboot-rg350.bin.sha1"
        echo "done"

        BOOTLOADERS="$BOOTLOADERS update_m/ubiboot-rg350.bin.sha1"
fi

if [ "$MININIT" ] ; then

	echo -n "Calculating SHA1 sum of mininit-syspart... "
	sha1sum "$MININIT" | cut -d' ' -f1 > "update_m/mininit-syspart.sha1"
	echo "done"

	MININIT="$MININIT update_m/mininit-syspart.sha1"
fi

echo "$DATE" > update_m/date.txt

echo "$VERSION" > update_m/version.txt

# Report metadata.
echo
echo "=========================="
echo "Bootloaders:          $BOOTLOADERS"
echo "Mininit:              $MININIT"
echo "Kernel:               $KERNEL"
echo "Modules file system:  $MODULES_FS"
echo "build date:           $DATE"
echo "build version:        $VERSION"
echo "=========================="
echo

# Write metadata.
cat > update_m/default.gcw0.desktop <<EOF
[Desktop Entry]
Name=Kernel update $VERSION
Comment=RG350M ROGUE update $DATE
Exec=update.sh
Icon=rogue
Terminal=true
Type=Application
StartupNotify=true
Categories=applications;
EOF

# Create OPK.
OPK_FILE=update_m/RG350-Kernel-update-$VERSION-$DATE.opk
mksquashfs \
	update_m/default.gcw0.desktop \
	update_m/rogue.png \
	update_m/update.sh \
	update_m/trimfat.py \
	update_m/flash_partition.sh \
	update_m/date.txt \
    update_m/version.txt \
    update_m/fsck.fat \
	$BOOTLOADERS \
	$MININIT \
	$KERNEL \
	$MODULES_FS \
	$OPK_FILE \
	-no-progress -noappend -comp gzip -all-root

echo
echo "=========================="
echo
echo "updater OPK:       $OPK_FILE"
echo

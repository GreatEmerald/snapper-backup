#!/bin/bash
# Backup script to external storage
# Copyright (c) GreatEmerald, 2020
# Under GPLv3+

# Change this to the backup path! It needs to have subfolders with the name of the snapper config.
ARCHIVE_PATH=/mnt/archive/snapshots/$1

OLD_ROOT_ID=`cat ${SUBVOLUME}/.snapshots/remote-id`
re='^[0-9]+$'
if ! [[ $OLD_ROOT_ID =~ $re ]] ; then
	echo "Error: Previous snapshot of $1 not found, bailing. The file contained: ${OLD_ROOT_ID}" >&2; exit 1
fi
echo "Creating new manually-cleaned-up snapshots of $1"
mv ${SUBVOLUME}/.snapshots/remote-id ${SUBVOLUME}/.snapshots/remote-id-old
snapper -c $1 create -t single -p -d "External backup" > ${SUBVOLUME}/.snapshots/remote-id
NEW_ROOT_ID=`cat ${SUBVOLUME}/.snapshots/remote-id`
echo "Checking if snapshots succeeded..."
if ! [[ $NEW_ROOT_ID =~ $re ]] ; then
	echo "Error: Current snapshot of $1 not found, bailing. The output was: ${NEW_ROOT_ID}" >&2
	mv ${SUBVOLUME}/.snapshots/remote-id-old ${SUBVOLUME}/.snapshots/remote-id
	exit 1
fi
echo "Sending the snapshot difference"
btrfs send -p ${SUBVOLUME}/.snapshots/${OLD_ROOT_ID}/snapshot ${SUBVOLUME}/.snapshots/${NEW_ROOT_ID}/snapshot | btrfs receive $ARCHIVE_PATH && mv ${ARCHIVE_PATH}/snapshot ${ARCHIVE_PATH}/${NEW_ROOT_ID}
btrfs filesystem sync ${SUBVOLUME}
echo "Removing older non-cleaned-up snapshot"
snapper -c $1 delete ${OLD_ROOT_ID}
rm ${SUBVOLUME}/.snapshots/remote-id-old
echo "Backup complete!"

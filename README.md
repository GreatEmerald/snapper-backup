# snapper-backup
A simple script for backing up snapshots created by Snapper, for use in systemd environments. Useful if you want to use btrfs send-receive to back up your snapshots onto an external device.

## First time setup
The script assumes a particular setup: a file `remote-id` is placed into the `.snapshots` directory of the volume that is snapshotted to keep track of the snapshot that has last been backed up to the external disk. Also, the first line of the script is where the snapshots will be backed up to. You need to edit that line to point to where you actually want to store the backups.

Next, create a first time setup:

```bash
# If you don't yet have one (e.g. for snapshots of /home), assuming you name it "home"
# Note that you always have a config "root" that points to /
SRCCONFIG=home
SRCPATH=/home # Path to backup
DSTPATH=/mnt/archive/snapshots
snapper -c $SRCCONFIG create-config $SRCPATH
snapper -c $SRCCONFIG create -t single -p -d "External backup" > $SRCPATH/.snapshots/remote-id
mkdir -p $DSTPATH/$SRCCONFIG
btrfs send $SRCPATH/.snapshots/$(cat $SRCPATH/.snapshots/remote-id)/snapshot | btrfs receive $DSTPATH/$SRCCONFIG
mv $DSTPATH/$SRCCONFIG/snapshot $DSTPATH/$SRCCONFIG/$(cat $SRCPATH/.snapshots/remote-id)
```

To run it once, simply call:

```bash
sudo snapper-backup.sh home
```

But it really is meant to be run from the included systemd timer unit. First, put the `snapper-backup.sh` script into `/usr/local/sbin/`, and then the two units into `/etc/systemd/system`, and finally run:

```bash
# If you want to snapshot the "home" config:
sudo systemctl enable snapper-backup@home.timer
```

You can run as many timers as you want, one line for each config to snapshot.

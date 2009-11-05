#!/bin/sh

# do not ask, if we already have root
[ -f /sysroot/proc ] && exit 0

# check if destination already exists
[ -b /dev/mapper/$2 ] && exit 0

# we already asked for this device
[ -f /tmp/cryptroot-asked-$2 ] && exit 0

. /lib/dracut-lib.sh
LUKS=$(getargs rd_LUKS_UUID=)
ask=1

if [ -n "$LUKS" ]; then
    ask=0
    luuid=${2##luks-}
    for luks in $LUKS; do
	luks=${luks##luks-}
	if [ "${luuid##$luks}" != "$luuid" ]; then
	    ask=1
	fi
    done
fi

if [ $ask -gt 0 ]; then
    info "luksOpen $1 $2"
    # flock against other interactive activities
    { flock -s 9; 
	/bin/plymouth ask-for-password \
	    --prompt "$1 is password protected" \
	    --command="/sbin/cryptsetup luksOpen -T1 $1 $2"
    } 9>/.console.lock
fi

# mark device as asked
>> /tmp/cryptroot-asked-$2

udevsettle

unset LUKS
unset ask
unset luks
exit 0


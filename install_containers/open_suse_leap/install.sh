#!/bin/bash
VOLUME_DEV=$1

curl -O http://ftp.tu-chemnitz.de/pub/linux/opensuse/distribution/leap/15.1/jeos/openSUSE-Leap-15.1-JeOS.x86_64-15.1.0-OpenStack-Cloud-Snapshot8.12.17.qcow2

qemu-img convert *.qcow2 leap.raw
dd if=leap.raw of=$VOLUME_DEV

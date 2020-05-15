#!/bin/sh

VOLUME_DEV=$1
fcct -o hetzner.ign hetzner.yaml
coreos-installer install $VOLUME_DEV -s stable -i hetzner.ign

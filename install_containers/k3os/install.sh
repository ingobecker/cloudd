#!/bin/bash
VERSION=v0.10.1
ISO_URL=https://github.com/rancher/k3os/releases/download/${VERSION}/k3os-amd64.iso

bash k3os_install.sh --config config.yaml \
                     $1 \
                     $ISO_URL

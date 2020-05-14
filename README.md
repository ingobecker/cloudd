# cloudd

cloudd is a terraform module for creating arbitrary operating system images on hetzner cloud in a simple and automated way. It accomplishes that by using a combination of `terraform`, `cloud-init`, `dracut` and `podman`. Although primarily created to be used on hetzner cloud the `cloudd` terraform module is completely platfom agnostic and should work on every cloud provider that supports `cloud-init` and offers an operating system image that uses `dracut` and ships with a `podman` package(fedora makes for a good fit ;).

cloudd uses so called *install containers*. An install container is an OCI container that includes the instructions how an operating system image is created. Creating an image can be as easy as curling a raw image file and writing it onto a block device using `dd`.

cloudd itself is a terraform module which creates a cloud-init configuration that can be applied to any cloud provider that supports cloud-init and lets you provision a VM with fedora. To run it on a specific cloud provider, you have to use a provider specific implementation of cloudd, i.e. [cloudd-hcloud](https://github.com/ingobecker/cloudd-hcloud).

## Support

### cloud providers

The following cloud providers are supported:

* [cloudd-hcloud](https://github.com/ingobecker/cloudd-hcloud)
* [cloudd-libvirt](https://github.com/ingobecker/cloudd-libvirt)

cloudd-libvirt is used mainly for the delevopment of cloudd itself.

### Operating systems

cloudd ships with intallation containers that let you create images for the following operating systems:

* fedora CoreOS
* rancher k3OS
* openSUSE leap jeOS

see [cloudd-install-containers](https://github.com/ingobecker/cloudd-install-containers)

### Mix and match..

.. any of the providers with any of the operating systems from above.

## Quickstart

This example requires a hetzner cloud api token, terraform, curl as well as the `jq` tool to be installed on your system.

Clone the [cloudd-hcloud-example](https://github.com/ingobecker/cloudd-hcloud-example) repo, cd into it and create an empty directory named `leap`:

```Shell
$ git clone https://github.com/ingobecker/cloudd-hcloud-example.git
$ cd cloudd-hcloud-example
$ mkdir leap
```

Create an install container by writing a `Containerfile` with the following content:

```Dockerfile
# leap/Containerfile
FROM ubuntu:focal

RUN apt-get update && apt-get install -y curl ca-certificates qemu-utils
COPY install.sh .
ENTRYPOINT ["sh", "install.sh"]

LABEL RUN "podman run --privileged \
                 --rm \
                 -v /dev:/dev \
                 -v /run/udev:/run/udev \
                 IMAGE"
```

When cloudd runs the install container, it passes the path of a block-device to the entrypoint. The install containers job is to install the operating system to this device using any tools appropriate.

The way the container is run can be customized using the mandatory `RUN` runlabel. It's always a good idea to run the container `--privileged` and bind-mount the hosts `/dev` directory into it.

This example uses an ubuntu image and installs `curl` and `qemu-img`. Those tools are needed to create the new image.

```Shell
# leap/install.sh
VOLUME_DEV=$1

curl -O http://ftp.tu-chemnitz.de/pub/linux/opensuse/distribution/leap/15.1/jeos/openSUSE-Leap-15.1-JeOS.x86_64-15.1.0-OpenStack-Cloud-Snapshot8.12.17.qcow2

qemu-img convert *.qcow2 leap.raw
dd if=leap.raw of=$VOLUME_DEV
```

In this example, a cloud image from openSUSE is used which comes with cloud-init installed. The image is downloaded, converted from qcow2 into a raw format and written to the block-device that cloudd supplied to the contrainer.

To run this example, enter your hetzner cloud api token into the `terraform.tfvars`. Set the `context` to the `leap` directory created above and give your new image a name:

```HCL
# main.tf
module "cloudd-hcloud" {
  source = "github.com/ingobecker/cloudd-hcloud"

  name = "leap15.1"
  context = "${path.module}/leap"
}
```

Initialize and apply the module:

```Shell
$ terraform init
$ terraform apply
```

This might take some time, depending on the size and way your install container and the way it works.

Once finishd, an image id is printed:

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

image_id = 12345678
```

This id can be used in other hcloud resources:

```HCL
resource "hcloud_server" "test" {
  image = "12345678"
}
```

Or even better, reference the modules output value:

```HCL
resource "hcloud_server" "test" {
  image = module.cloudd-hcloud.image_id
}
```

Since the `cloudd-hcloud` module uses a hetzner cloud vm as well as an external volume, it makes sense to clean them up, after the image has been created.

## How it works

The proccess of image creation consists of two stages.

During the first stage, a fedora system is setup using cloud-init in a way that it is capable of running containers. For that, podman is installed and the context directory passed to the module is copied to the remote system. Afterwards your conrainer is built using the supplied context and run as specified by the `RUN` runlabel.

The second stage uses `dracut` to write the image copied to the external volume in the previous stage to the root device of the vm. In order to do so, cloudd creates a new initramfs and inserts a hook just before the root filesystem is mounted. After that, cloudd reboots into the prepared initramfs and runs the dd hook. Once finished the vm is shut down ready for snapshotting.

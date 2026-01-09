# Build yocto images using this docker container

This repo uses an excerpt from the Atlas build system and has not been worked
through very carefully. A lot of seemingly useless extras are still in the
`Makefile` and the docker image. It can be improved, but should work for our
needs right now.

By using Docker for the yocto builds, only docker, git and make are needed on
the host to build images.

## Install Docker on your host

Install Docker on your Linux host following the instructions found [here](https://docs.docker.com/engine/install/). After
installation, install the packages listed above and make sure you add your user
to the docker group (If needed, first add the docker group with `sudo groupadd
docker`). On an Ubuntu based system:

``` sh
sudo apt-get install git make
sudo usermod -aG docker $USER
```

and then log out and in again to make sure the user change applies (you may need
to reboot to get the group change to take effect).

Verify that your Docker installation works by running

``` sh
docker run hello-world
```

## Download poky

Standing in the top level directory of this repo, clone poky.

``` sh
simple-docker-build$ git clone -b scarthgap git://git.yoctoproject.org/poky
```

## Build a yocto image for Beaglebone from within the build shell

The first time you open the build shell, the docker image
(codiax-docker-builder) will be built locally to your machine. It will take a
while, but will be faster next time.

``` sh
simple-docker-build$ make yocto-shell
docker-shell:/simple-docker-build$ . poky/oe-init-buildenv
docker-shell:/simple-docker-build/build$ MACHINE=beaglebone-yocto bitbake core-image-minimal
```

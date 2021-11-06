# GENTOO INSTALL SCRIPT

## About

This is a quick installer script that can be used to bootstrap amd64 Gentoo Linux quickly.

USE_LIVECD_KERNEL=1 - Use livecd kernel

USE_LIVECD_KERNEL=0 - compile kernel

```shell
# livecd kernel with root password
USE_LIVECD_KERNEL=1 ROOT_PASSWORD=Gentoo123 ./install.sh

# Compiled kernel with root password
USE_LIVECD_KERNEL=0 ROOT_PASSWORD=Gentoo123 ./install.sh
```

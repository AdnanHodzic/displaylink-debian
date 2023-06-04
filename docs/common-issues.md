# Common issues

## Make error Bad return status for module build on kernel...

While installing displaylink-debian, you might see an error similar to this one in the terminal output:

```log
  Building module:
  cleaning build area...
  make -j8 KERNELRELEASE=5.10.0-23-amd64 all INCLUDEDIR=/lib/modules/5.10.0-23-amd64/build/include KVERSION=5.10.0-23-amd64 DKMS_BUILD=1...(bad exit status: 2)
  Error! Bad return status for module build on kernel: 5.10.0-23-amd64 (x86_64)
  Consult /var/lib/dkms/evdi/1.13.1/build/make.log for more information.
```

**Prerequisite:**
* displaylink must **not** be installed
* libssl-dev must be installed
  
Try this procedure to fix the previous error:

```sh
sudo apt install libssl-dev
cd /usr/src/linux-headers-$(uname -r)
sudo tar -xaf /usr/src/linux-source-$(uname -r | egrep -o '^[0-9]+\.[0-9]+').tar.xz --strip-components=1
sudo make oldconfig
sudo make prepare
```
Then install displaylink as usual:

`sudo ./displaylink-debian.sh --install`


## More common issues

* [Disable UEFI / secure boot](https://github.com/AdnanHodzic/displaylink-debian/issues/123)

* [Bash / sh can't be executed](https://github.com/AdnanHodzic/displaylink-debian/issues/74#issuecomment-410622725)

* [secure boot / cable problems](https://github.com/AdnanHodzic/displaylink-debian/issues/142#issuecomment-413091374)

* [rendering issues](https://github.com/AdnanHodzic/displaylink-debian/issues/68)

* [Unable to locate package linux-headers](https://github.com/AdnanHodzic/displaylink-debian/issues/141)

* [Debian / Fail to connect screens](https://github.com/AdnanHodzic/displaylink-debian/issues/130)

* [mouse/cursor flicker issue](https://github.com/AdnanHodzic/displaylink-debian/issues/192)

* [`Can't open display :0` error](https://github.com/AdnanHodzic/displaylink-debian/issues/639)


## Most common Debian Jessie related issues:
* systemctl status dlm.service failure
* Glibc GLIBCXX_3.4.21 missing

Due to older version of libstdc++6 in Jessie, you need to download and install version from [Stretch release](https://packages.debian.org/stretch/libstdc++6). After package has been updated, run displaylink-debian and select "Re-install" option.

Reference: [#42](https://github.com/AdnanHodzic/displaylink-debian/issues/42)

Should you experience problems with the display either remaining black, only showing mouse pointer or a frozen image of your main screen, then this could be due to Intel graphics driver interfering with displaylink.

Reference: [#68](https://github.com/AdnanHodzic/displaylink-debian/issues/68)

## syntax error near unexpected token \`newline'...

If you just downloaded the script and tried to execute it, you might get the following error:

```
$ ./displaylink-debian.sh
./displaylink-debian.sh: line 1: syntax error near unexpected token `newline'
./displaylink-debian.sh: line 1: `<!DOCTYPE html>'
```

The line number might be different.

*Solution:*

Download the script again as a ZIP file: https://github.com/AdnanHodzic/displaylink-debian/archive/master.zip

Extract it and run it:

```sh
unzip displaylink-debian-master.zip
cd displaylink-debian-master
sudo ./displaylink-debian.sh
```

References: [#111](https://github.com/AdnanHodzic/displaylink-debian/issues/111), [#102](https://github.com/AdnanHodzic/displaylink-debian/issues/102), [#89](https://github.com/AdnanHodzic/displaylink-debian/issues/89), [#65](https://github.com/AdnanHodzic/displaylink-debian/issues/65) 

## Having a different problem?

When submitting a new [issue](https://github.com/AdnanHodzic/displaylink-debian/issues), include debug information by running: `sudo ./displaylink-debian.sh --debug`

## Monitoring for errors

* Monitor ```dmesg | grep Display``` output while plugging in Displaylink
* Monitor ```/var/log/displaylink/DisplayLinkManager.log``` file
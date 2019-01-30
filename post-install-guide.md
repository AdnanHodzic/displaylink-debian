# Post Installation Guide

* [Prerequisites](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#prerequisites)

* [Setting provider sources](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#setting-provider-sources)

* [Screen Layout Configuration](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#screen-layout-configuration)

* [Automated (persistent) display configuration](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#automated-persistent-display-configuration)

* [Troubleshooting most common issues](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#troubleshooting-most-common-issues)

* [Having a different problem](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#having-a-different-problem)

### Prerequisites

* Make sure that UEFI/secure boot is disabled!

* When you are logging into your session you are using X server (X11) and not Wayland.

* After install you must reboot to apply the changes.

* After reboot, make sure DispayLink is running, i.e:

  ```systemctl status dlm.service```
  
  If it's not running, start it by running:
  
  ```systemctl start dlm.service```
  
  To start automatically at boot run:
  
  ```systemctl enable dlm.service```


### Setting provider sources

* Check providers, i.e:

  ```xrandr --listproviders```

If you get a list of more then one provider, it means your displays were detected.

* Set provider sources, i.e:
   ```
   xrandr --setprovideroutputsource 1 0
   
   xrandr --setprovideroutputsource 2 0
    ```
This will connect you to two external monitors. 

### Screen Layout Configuration

There are couple of tools to help you configure screen layout of your external monitors.

##### xrandr

Depending on your setup, to connect provider 1 to provier 0, you'd run:

```xrandr --output DVI-1-0 --auto --right-of eDP1```

For further reference I suggest reading: 
[How to use xrandr](https://pkg-xorg.alioth.debian.org/howto/use-xrandr.html)

##### GNOME Displays

If you're GNOME desktop user, simply run:

```gnome-control-center display```

##### arandr

Another very easy and intuative (gui) tool is ```arandr``` (Another XRandR GUI) 

Make sure to install it first: ```sudo apt-get install arandr```

### Automated (persistent) display configuration

Since hotplug doesn't work (on Debian and Kali) and every time you connect your computer to Displaylink you'll need to re-configure your displays.

I've set-up couple of [aliases](http://www.linfo.org/alias.html) which help me accomplish this in semi-automated manner.

Every time I connect my computer to DisplayLink ...

##### two

I simple run ```two``` which is an alias for setting up two external displays as primary and secondary, whilst turning off laptop built in display. So I can close the lid.

##### one

Every time I want to diconnect my displays I run ```one```. Which turns off both external displays, turns on built in laptop display and makes it a primary (default behaviour).

I did this by simply adding following code to my ```~/.bashrc```

```bash
# two
alias two="xrandr --setprovideroutputsource 1 0 && xrandr --setprovideroutputsource 2 0 && xrandr --output VIRTUAL1 --off --output DVI-1-0 --primary --auto --pos 0x0 --rotate normal --output DP1 --off --output HDMI2 --off --output HDMI1 --off --output eDP1 --off --output DVI-2-1 --auto --pos 1680x0 --rotate normal"

# one
alias one="xrandr --output VIRTUAL1 --off --output DVI-1-0 --off --output DP1 --off --output HDMI2 --off --output HDMI1 --off --output eDP1 --primary --mode 1366x768 --pos 0x0 --rotate normal --output DVI-2-1 --off"
```

Note, in case you're editting ```~/.bashrc```, make sure you run ```source ~/.bashrc``` to appy the changes without having to log in/out.

### Troubleshooting most common issues

* [Service won't start](https://github.com/AdnanHodzic/displaylink-debian/issues/15)

* [Disable UEFI / secure boot](https://github.com/AdnanHodzic/displaylink-debian/issues/123)

* [Bash / sh can't be executed](https://github.com/AdnanHodzic/displaylink-debian/issues/74#issuecomment-410622725)

* [secure boot / cable problems](https://github.com/AdnanHodzic/displaylink-debian/issues/142#issuecomment-413091374)

* [rendering issues](https://github.com/AdnanHodzic/displaylink-debian/issues/68)

* [dml.service won't start](https://github.com/AdnanHodzic/displaylink-debian/issues/48#issuecomment-432044380)

* [Unable to locate package linux-headers](https://github.com/AdnanHodzic/displaylink-debian/issues/141)

* [Debian / Fail to connect screens](https://github.com/AdnanHodzic/displaylink-debian/issues/130)

* [mouse/cursor flicker issue](https://github.com/AdnanHodzic/displaylink-debian/issues/192)

##### Monitoring for errors

* Monitor ```dmesg | grep Display``` output while plugging in Displaylink
* Monitor ```/var/log/displaylink/DisplayLinkManager.log``` file

##### Most common Debian Jessie related issues:
* systemctl status dlm.service failure
* Glibc GLIBCXX_3.4.21 missing

Due to older version of libstdc++6 in Jessie, you need to download and install version from [Stretch release](https://packages.debian.org/stretch/libstdc++6). After package has been updated, run displaylink-debian and select "Re-install" option.

Reference: [issue #42](https://github.com/AdnanHodzic/displaylink-debian/issues/42)

Should you experience problems with the display either remaining black, only showing mouse pointer or a frozen image of your main screen, then this could be due to Intel graphics driver interfering with displaylink.

Reference: [issue #68](https://github.com/AdnanHodzic/displaylink-debian/issues/68)

##### syntax error near unexpected token \`newline'...

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

```
$ unzip displaylink-debian-master.zip
Archive:  displaylink-debian-master.zip
075594536fe4683a5e25aec99e3b6379662ef2ea
   creating: displaylink-debian-master/
  inflating: displaylink-debian-master/README.md  
  inflating: displaylink-debian-master/displaylink-debian.sh  
  inflating: displaylink-debian-master/post-install-guide.md  
$ cd displaylink-debian-master
$ sudo ./displaylink-debian.sh
```

References: [issue #111](https://github.com/AdnanHodzic/displaylink-debian/issues/111),
[issue #102](https://github.com/AdnanHodzic/displaylink-debian/issues/102),
[issue #89](https://github.com/AdnanHodzic/displaylink-debian/issues/89),
[issue #65](https://github.com/AdnanHodzic/displaylink-debian/issues/65)


### Having a different problem?

When submitting a new [issue](https://github.com/AdnanHodzic/displaylink-debian/issues), include debug information by running: `sudo ./displaylink-debian.sh --debug`

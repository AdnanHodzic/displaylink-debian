# Post Installation Guide

* [Prerequisites](#prerequisites)

* [Display detection](#display-detection)

* [Screen Layout Configuration](#screen-layout-configuration)

* [Automated (persistent) display configuration](#automated-persistent-display-configuration)

* [Troubleshooting most common issues](#troubleshooting-most-common-issues)

* [Having a different problem](#having-a-different-problem)

### Prerequisites

* Make sure that UEFI/secure boot is disabled!

* When you are logging into your session you are using X server (X11) and not Wayland.

* After install you must reboot to apply the changes.

* After reboot, make sure DispayLink is running by running debug i.e: `sudo ./displaylink-debian.sh --debug`

Then check `DisplayLink info` section, i.e:

```
---------------- DisplayLink info ----------------

Driver version: 5.1.26
DisplayLink service status: up and running
EVDI service version: 1.6.0
```

* Check providers to see if your monitors were detected, i.e:

  ```xrandr --listproviders```

If you get a list of more then one provider, it means your displays were properly detected. 

If that's not the case and you have an Intel graphics card try [following suggestion](https://github.com/AdnanHodzic/displaylink-debian/issues/228#issuecomment-467889348), if that doesn't work [try this](https://github.com/AdnanHodzic/displaylink-debian/issues/236#issuecomment-471213411).

If you have Nvidia or ATI/AMD graphics card, try removing: `/etc/X11/xorg.conf.d/20-displaylink.conf` file followed by reboot and check again if you're getting more then one provider. 

If none of the suggestions in [Prerequsites section](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#prerequisites) solved your problem, make sure to consult [Troubleshooting most common issues](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#troubleshooting-most-common-issues).

### Display Detection

Only do this in case your monitors weren't automatically detected.

First run `xrandr --listproviders`. 
The output should be similar to this:
```
Providers: number : 5
Provider 0: id: 0x44 cap: 0x9, Source Output, Sink Offload crtcs: 3 outputs: 2 associated providers: 0 name:Intel
Provider 1: id: 0x138 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 0 name:modesetting
Provider 2: id: 0x116 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 0 name:modesetting
Provider 3: id: 0xf4 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 0 name:modesetting
Provider 4: id: 0xd2 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 0 name:modesetting
```
Notes:
* Provider 0 is the actual graphics provider and 1-4 are DisplayLink providers.
* All providers have 0 associated providers. Which means that we will have to connect all the DisplayLink providers to the main provider. 

We can do this with the command `xrandr --setprovideroutputsource <prov-xid> <source-xid>`
In this case we would run:
```
xrandr --setprovideroutputsource 1 0
xrandr --setprovideroutputsource 2 0
xrandr --setprovideroutputsource 3 0
xrandr --setprovideroutputsource 4 0
```
If we would re-run `xrandr --listproviders` this would output:
```
Providers: number : 5
Provider 0: id: 0x44 cap: 0x9, Source Output, Sink Offload crtcs: 3 outputs: 2 associated providers: 4 name:Intel
Provider 1: id: 0x138 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 1 name:modesetting
Provider 2: id: 0x116 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 1 name:modesetting
Provider 3: id: 0xf4 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 1 name:modesetting
Provider 4: id: 0xd2 cap: 0x2, Sink Output crtcs: 1 outputs: 1 associated providers: 1 name:modesetting
```

For further reference I suggest reading: 
[How to use xrandr](https://web.archive.org/web/20180224075928/https://pkg-xorg.alioth.debian.org/howto/use-xrandr.html)

### Screen Layout Configuration

There are couple of tools to help you configure screen layout of your external monitors. 

##### xrandr

Depending on your setup, to place DVI-1-0 virtually-right of the eDP1 display you'd run:

```xrandr --output DVI-1-0 --auto --right-of eDP1```

For further reference I suggest reading: 
[How to use xrandr](https://web.archive.org/web/20180224075928/https://pkg-xorg.alioth.debian.org/howto/use-xrandr.html)

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

* [Disable UEFI / secure boot](https://github.com/AdnanHodzic/displaylink-debian/issues/123)

* [Bash / sh can't be executed](https://github.com/AdnanHodzic/displaylink-debian/issues/74#issuecomment-410622725)

* [secure boot / cable problems](https://github.com/AdnanHodzic/displaylink-debian/issues/142#issuecomment-413091374)

* [rendering issues](https://github.com/AdnanHodzic/displaylink-debian/issues/68)

* [Unable to locate package linux-headers](https://github.com/AdnanHodzic/displaylink-debian/issues/141)

* [Debian / Fail to connect screens](https://github.com/AdnanHodzic/displaylink-debian/issues/130)

* [mouse/cursor flicker issue](https://github.com/AdnanHodzic/displaylink-debian/issues/192)

* [`Can't open display :0` error](https://github.com/AdnanHodzic/displaylink-debian/issues/639)

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

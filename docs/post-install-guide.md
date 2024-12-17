# Post Installation Guide

## Prerequisites

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

If none of the suggestions in [Prerequsites section](#prerequisites) solved your problem, make sure to consult [Troubleshooting most common issues](common-issues.md).

## Display Detection

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

## Screen Layout Configuration

There are couple of tools to help you configure screen layout of your external monitors. 

### xrandr

Depending on your setup, to place DVI-1-0 virtually-right of the eDP1 display you'd run:

```xrandr --output DVI-1-0 --auto --right-of eDP1```

For further reference I suggest reading: 
[How to use xrandr](https://web.archive.org/web/20180224075928/https://pkg-xorg.alioth.debian.org/howto/use-xrandr.html)

### GNOME Displays

If you're GNOME desktop user, simply run:

```gnome-control-center display```

### arandr

Another very easy and intuative (gui) tool is ```arandr``` (Another XRandR GUI) 

Make sure to install it first: ```sudo apt-get install arandr```

## Automated (persistent) display configuration

Since hotplug doesn't work (on Debian and Kali) and every time you connect your computer to Displaylink you'll need to re-configure your displays.

I've set-up couple of [aliases](http://www.linfo.org/alias.html) which help me accomplish this in semi-automated manner.

Every time I connect my computer to DisplayLink ...

### two

I simple run ```two``` which is an alias for setting up two external displays as primary and secondary, whilst turning off laptop built in display. So I can close the lid.

### one

Every time I want to diconnect my displays I run ```one```. Which turns off both external displays, turns on built in laptop display and makes it a primary (default behaviour).

I did this by simply adding following code to my ```~/.bashrc```

```bash
# two
alias two="xrandr --setprovideroutputsource 1 0 && xrandr --setprovideroutputsource 2 0 && xrandr --output VIRTUAL1 --off --output DVI-1-0 --primary --auto --pos 0x0 --rotate normal --output DP1 --off --output HDMI2 --off --output HDMI1 --off --output eDP1 --off --output DVI-2-1 --auto --pos 1680x0 --rotate normal"

# one
alias one="xrandr --output VIRTUAL1 --off --output DVI-1-0 --off --output DP1 --off --output HDMI2 --off --output HDMI1 --off --output eDP1 --primary --mode 1366x768 --pos 0x0 --rotate normal --output DVI-2-1 --off"
```

Note, in case you're editting ```~/.bashrc```, make sure you run ```source ~/.bashrc``` to appy the changes without having to log in/out.

---
Alternatively, one can add an Xsession script, so the providers are automatically bound to the default output:
```bash
# File: /etc/X11/Xsession.d/45displaylink-provider-settings
# Bind any existing 'modesetting' provider output to the default source

providers=$(xrandr --listproviders | grep "modesetting" | cut -d: -f 1 | cut -d ' ' -f 2 | grep -v 0)

for provider in $providers; do
    xrandr --setprovideroutputsource $provider 0
done
```

With the above script, one doesn't need to manually run the `xrandr --setprovideroutputsource`, as they are registered at the X11 start and the screen layout can be persisted set in user setting.

## Upgrading your OS or updating displaylink
It's recommended to run the uninstall and install procedure separately instead of relying on the reinstall option.
1. `sudo ./displaylink-debian.sh --uninstall`
2. reboot
3. `sudo ./displaylink-debian.sh --install`



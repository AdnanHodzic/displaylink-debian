# Post Installation Guide

### Prerequisites


* After install you must reboot to apply the changes.

* After reboot, make sure dispaylink is running, i.e:

  ```systemctl status displaylink.service```
  
  If it's not running, start it by running:
  
  ```systemctl start displaylink.service```
  
  To start automatically at boot run:
  
  ```systemctl enable displaylink.service```

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

### Automated configuration

Since hotplug doesn't work (on Debian) and every time you connect your computer to Displaylink you'll need to re-configure your displays.

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

### Troubleshooting

* Monitor ```dmesg``` output while plugging in Displaylink
* Monitor ```/var/log/displaylink/DisplayLinkManager.log``` file

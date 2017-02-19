# displaylink-debian
DisplayLink driver installer for Debian GNU/Linux, Ubuntu, Elementary OS, Mint and Kali Linux.

#### Problem
[DisplayLink](http://www.displaylink.com/) releases its drivers only for Ubuntu 14.04, and latest kernel version they support is 3.19.


#### displaylink-debian

* Allows you to seamlessly install/uninstall DisplayLink drivers on Debian GNU/Linux, Ubuntu and elementary OS.


How? Just run the script! (as sudo)

`sudo ./displaylink-debian.sh`

#### Technical

##### displaylink-debian.sh

* Downloads and extracts contents of original [DisplayLink Ubuntu driver] (http://www.displaylink.com/downloads/ubuntu.php>)

* _displaylink-debian.sh_ will modify contents of original _displaylink-installer.sh_ and customize it for Debian. After which install/uninstall is performed. 

* Supported platforms are:

  * Debian: Jessie 8.0/Stretch 9.0/Sid (unstable)
  * Ubuntu: 14.04 Trusty/15.04 Vivid/15.10 Wily/16.04 Xenial/16.10 Yakkety/17.04 Zesty
  * elementary OS: O.3 Freya/0.4 Loki
  * Mint: 15 Olivia/16 Petra/17.3 Rosa/18 Sarah
  * Kali: 2016.2/kali-rolling

  Regardless of which kernel version you're using.

#### Post installation Guide and Troubleshooting

Please refer to [Post Installation Guide](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md) for further reference.

Before submitting an issue, please make sure you've seen [Troubleshooting most common issues](https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#troubleshooting-most-common-issues).

#### Discussion
Blog post: [Kernel agnostic, DisplayLink Debian GNU/Linux driver installer (Jessie/Stretch/Sid)](http://foolcontrol.org/?p=1777)

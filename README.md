# displaylink-debian

DisplayLink driver installer for Debian GNU/Linux, Ubuntu, Elementary OS,
Mint, Kali and Deepin Linux.


#### Problem

[DisplayLink][] releases its drivers only for Ubuntu 14.04 LTS and 16.04 LTS,
supported Linux kernel versions are 3.19 and 4.4.


#### Solution

[displaylink-debian][] allows seamless install/uninstall of the official
DisplayLink drivers on Debian GNU/Linux, Ubuntu, elementary OS, and more!

#### How to run "displaylink-debian"

##### Repo clone (method 1)

`git clone https://github.com/AdnanHodzic/displaylink-debian.git`

`cd displaylink-debian/ && sudo ./displaylink-debian.sh`

##### Download and run script without Git (method 2)

`wget https://raw.githubusercontent.com/AdnanHodzic/displaylink-debian/master/displaylink-debian.sh`

`chmod +x ./displaylink-debian.sh && sudo ./displaylink-debian.sh`

#### Technical

* _displaylink-debian.sh_ downloads and extracts the contents of the
  official [DisplayLink Ubuntu driver][upstream].

* _displaylink-debian.sh_ modifies the contents of the official installer,
  _displaylink-installer.sh_, to suit Debian and other Linux distributions.

*  Install/Uninstall is performed.

* Supported platforms are:

  * Debian: Jessie 8.0/Stretch 9.0/Sid (unstable)
  * Ubuntu: 14.04 Trusty/15.04 Vivid/15.10 Wily/16.04 Xenial/16.10 Yakkety/17.04 Zesty/17.10 Artful/18.04 Bionic
  * elementary OS: O.3 Freya/0.4 Loki
  * Mint: 15 Olivia/16 Petra/17.3 Rosa/18 Sarah/18.3 Sylvia
  * Kali: kali-rolling/2016.2/2017.3
  * Deepin: 15/15.1/15.1.1/15.2/15.4.1

  Regardless of the kernel version you're using.


#### Post installation Guide and Troubleshooting

Please refer to the [Post Installation Guide][PostInstall] for further
reference.

Before submitting a bug report in the issue tracker, please make sure to
read: [Troubleshooting most common issues][TroubleShooting].


#### Discussion

* [Kernel agnostic, DisplayLink Debian GNU/Linux driver installer][blog]


[DisplayLink]:        http://www.displaylink.com/
[upstream]:           http://www.displaylink.com/downloads/ubuntu.php
[blog]:               http://foolcontrol.org/?p=1777
[displaylink-debian]: https://github.com/AdnanHodzic/displaylink-debian
[PostInstall]:        https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md
[TroubleShooting]:    https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#troubleshooting-most-common-issues

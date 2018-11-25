# displaylink-debian

DisplayLink driver installer for Debian GNU/Linux, Ubuntu, Elementary OS,
Mint, Kali, Deepin and more! [Full list of all supported Linux distributions](https://github.com/AdnanHodzic/displaylink-debian#supported-platforms-are)


#### Why do I need displaylink-debian?

[DisplayLink][] releases its drivers only for Ubuntu 16.04 LTS and 18.04 LTS,
and only supported Linux kernel versions are 4.4 and 4.15. Hence if you run any other kernel or Ubuntu version or any any Linux distribution DisplayLink will not work as expected. 

[displaylink-debian][] allows seamless installation of the official
DisplayLink drivers tailored to work for most of the Debian based Linux distributions regardless of which Linux kernel version you're using. [Full list of all supported Linux distributions](https://github.com/AdnanHodzic/displaylink-debian#supported-platforms-are)

#### How to run "displaylink-debian"

##### Repo clone (method 1)

`git clone https://github.com/AdnanHodzic/displaylink-debian.git`

`cd displaylink-debian/ && sudo ./displaylink-debian.sh`

##### Download and run script without Git (method 2)

`wget https://raw.githubusercontent.com/AdnanHodzic/displaylink-debian/master/displaylink-debian.sh`

`chmod +x displaylink-debian.sh && sudo ./displaylink-debian.sh`

#### Post installation Guide and Troubleshooting

Please refer to the [Post Installation Guide][PostInstall] for further
reference.

Before submitting a bug report in the issue tracker, please make sure to
read: [Troubleshooting most common issues][TroubleShooting].

#### Supported platforms are:

  * Debian: Jessie 8.0/Stretch 9.0/Buster 10/Sid (unstable)
  * Ubuntu: 14.04 Trusty/15.04 Vivid/15.10 Wily/16.04 Xenial/16.10 Yakkety/17.04 Zesty/17.10 Artful/18.04 Bionic/19.04 Disco
  * elementary OS: O.3 Freya/0.4 Loki/5.0 Juno
  * Mint: 15 Olivia/16 Petra/17.3 Rosa/18 Sarah/18.3 Sylvia
  * Kali: kali-rolling/2016.2/2017.3/2018.3/2018.4
  * Deepin: 15/15.1/15.1.1/15.2/15.4.1
  * MX Linux: 17.1
  * BunsenLabs: Helium

  Regardless of which Linux kernel version you're using.
  
  If your distribution is not on the list, please [submit a request to add support for it](https://github.com/AdnanHodzic/displaylink-debian/issues/new).

#### Technical

* _displaylink-debian.sh_ downloads and extracts the contents of the
  official [DisplayLink Ubuntu driver][upstream].

* _displaylink-debian.sh_ modifies the contents of the official installer,
  _displaylink-installer.sh_, makes all necessary changes for DisplayLink to work out of box on supported Linux distribution.

*  Install/Reinstall/Uninstall is performed.


#### Discussion

* [Kernel agnostic, DisplayLink Debian GNU/Linux driver installer][blog]


[DisplayLink]:        http://www.displaylink.com/
[upstream]:           http://www.displaylink.com/downloads/ubuntu.php
[blog]:               http://foolcontrol.org/?p=1777
[displaylink-debian]: https://github.com/AdnanHodzic/displaylink-debian
[PostInstall]:        https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md
[TroubleShooting]:    https://github.com/AdnanHodzic/displaylink-debian/blob/master/post-install-guide.md#troubleshooting-most-common-issues

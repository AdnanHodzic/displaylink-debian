# displaylink-debian

DisplayLink driver installer for Debian and Ubuntu based Linux distributions: Debian, Ubuntu, Elementary OS, Mint, Kali, Deepin and many more! [Full list of all supported platforms](https://github.com/AdnanHodzic/displaylink-debian#supported-platforms-are)

#### Looking for maintainers (developers)!

[After 4+ years since I started this project](https://foolcontrol.org/?p=1777), I’m no longer using DisplayLink. In the plethora of other projects I’m involved with ([especially latest one](https://twitter.com/fooctrl/status/1233455946350891008)), I don’t have time or [motivation](https://github.com/AdnanHodzic/displaylink-debian/issues/226#issuecomment-467439973) to continue working on displaylink-debian.

Hence, I’m looking for maintainers (developers) to continue work on this project. If necessary I’m more than happy to help you with onboarding. If you’re interested, please [leave a comment on issue #373](https://github.com/AdnanHodzic/displaylink-debian/issues/373).

In meantime, I’ll devote the bare minimum of my time which will mostly consist of MR (merge requests) code review and approval.

#### Why do I need displaylink-debian?

[DisplayLink][] releases its drivers only for Ubuntu 16.04 LTS and 18.04 LTS,
and only supported Linux kernel versions are 4.4 and 4.15. Hence if you run any other kernel or Ubuntu version or any any Linux distribution DisplayLink will not work as expected. 

[displaylink-debian][] allows seamless installation of the official
DisplayLink drivers tailored to work for most of the Debian based Linux distributions regardless of which Linux kernel version you're using.

#### How to run "displaylink-debian"

##### Repo clone (method 1)

`git clone https://github.com/AdnanHodzic/displaylink-debian.git`

`cd displaylink-debian/ && sudo ./displaylink-debian.sh`

*After installation has been completed, make sure to consult [Post Install Guide][PostInstall]!*

##### Download and run script without Git (method 2)

`wget https://raw.githubusercontent.com/AdnanHodzic/displaylink-debian/master/displaylink-debian.sh`
`wget https://raw.githubusercontent.com/AdnanHodzic/displaylink-debian/master/displaylink.sh`
`wget https://raw.githubusercontent.com/AdnanHodzic/displaylink-debian/master/evdi.sh`

`chmod +x displaylink-debian.sh evdi.sh && sudo ./displaylink-debian.sh`

*After installation has been completed, make sure to consult [Post Install Guide][PostInstall]!*

#### Post installation Guide and Troubleshooting

***Please note:** Your external monitor/s may not work as expected unless you perform additional steps as described in the [Post Installation Guide][PostInstall].*

Before submitting a bug report in the [issue tracker](https://github.com/AdnanHodzic/displaylink-debian/issues/new), please make sure to:
* read [Troubleshooting most common issues][TroubleShooting].
* when submitting a new issue, include debug information by running: `sudo ./displaylink-debian.sh --debug`

#### Supported platforms are:

  * Debian: Jessie 8.0/Stretch 9.0/Buster 10/Bullseye (testing)/Sid (unstable)
  * Ubuntu: 14.04 Trusty/15.04 Vivid/15.10 Wily/16.04 Xenial/16.10 Yakkety/17.04 Zesty/17.10 Artful/18.04 Bionic/19.04 Disco/19.10 Eoan/20.04 Focal
  * elementary OS: O.3 Freya/0.4 Loki/5.0 Juno
  * Mint: 15 Olivia/16 Petra/17.3 Rosa/18 Sarah/18.3 Sylvia/19.1 Tessa
  * Kali: kali-rolling/2016.2/2017.3/2018.3/2018.4
  * Deepin: 15/15.1/15.1.1/15.2/15.4.1
  * MX Linux: 17.1
  * BunsenLabs: Helium
  * Parrot: 4.5
  * Devuan: ASCII
  * Pop!_OS: 20.04 Focal

  Regardless of which Linux kernel version you're using.
  
  If your distribution is not on the list, make sure to include debug information by running: `sudo ./displaylink-debian.sh --debug` and [submit a request to add support for it](https://github.com/AdnanHodzic/displaylink-debian/issues/new).

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

#### Donate (PayPal or Bitcoin)

Since I'm working on this project in free time without any support or reimbursement from DisplayLink, and [have saved some 100$](https://github.com/AdnanHodzic/displaylink-debian/issues/172#issuecomment-441384936). Please consider supporting this project by making a donation of any amount!

##### PayPal
[![paypal](https://www.paypalobjects.com/en_US/NL/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=adnan%40hodzic.org&item_name=Contribution+for+work+on+debian-displaylink&currency_code=EUR&source=url)

##### BitCoin
[bc1qlncmgdjyqy8pe4gad4k2s6xtyr8f2r3ehrnl87](bitcoin:bc1qlncmgdjyqy8pe4gad4k2s6xtyr8f2r3ehrnl87)

[![bitcoin](https://foolcontrol.org/wp-content/uploads/2019/08/btc-donate-displaylink-debian.png)](bitcoin:bc1qlncmgdjyqy8pe4gad4k2s6xtyr8f2r3ehrnl87)

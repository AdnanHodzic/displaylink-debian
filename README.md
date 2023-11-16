# displaylink-debian

DisplayLink driver installer for Debian and Ubuntu based Linux distributions: Debian, Ubuntu, Elementary OS, Mint, Kali, Deepin and many more! [Full list of all supported platforms](https://github.com/AdnanHodzic/displaylink-debian#supported-platforms-are)

<!---
#### Looking for maintainers (developers)!

[After 4+ years since I started this project](https://foolcontrol.org/?p=1777), I’m no longer using DisplayLink. In the plethora of other projects I’m involved with ([especially latest one](https://twitter.com/fooctrl/status/1233455946350891008)), I don’t have time or [motivation](https://github.com/AdnanHodzic/displaylink-debian/issues/226#issuecomment-467439973) to continue working on displaylink-debian.

Hence, I’m looking for maintainers (developers) to continue work on this project. If necessary I’m more than happy to help you with onboarding. If you’re interested, please [leave a comment on issue #373](https://github.com/AdnanHodzic/displaylink-debian/issues/373).

In meantime, I’ll devote the bare minimum of my time which will mostly consist of MR (merge requests) code review and approval.
-->

## Why do I need displaylink-debian?

[DisplayLink][] releases its drivers only for Ubuntu xx.04 LTS. Hence if you run any other Ubuntu version or any other Linux distribution DisplayLink will not work as expected. 

[displaylink-debian][] allows seamless installation of the official
DisplayLink drivers tailored to work for most of the Debian based Linux distributions regardless of which Linux kernel version (>4.15) you're using. 

## Installation
1. Download the repo, cd in the directory and run the shell script with sudo:
```shell
git clone https://github.com/AdnanHodzic/displaylink-debian.git
cd displaylink-debian
sudo ./displaylink-debian.sh
```
1. Then consult the [Post Install Guide][PostInstall] to make sure everything works as intended.


## Troubleshooting and debugging

***Please note:** Your external monitor/s may not work as expected unless you perform additional steps as described in the [Post Installation Guide][PostInstall].*

Before submitting a bug report in the [issue tracker](https://github.com/AdnanHodzic/displaylink-debian/issues/new), please make sure to:
* read [Troubleshooting most common issues][TroubleShooting].
* when submitting a new issue, include debug information by running: `sudo ./displaylink-debian.sh --debug`

## Supported platforms are:

  * Debian: Jessie 8.0/Stretch 9.0/Buster 10/Bullseye 11/Bookworm 12/Trixie(testing)/Sid (unstable)
  * Ubuntu: 14.04 Trusty - 23.10 Mantic
  * elementary OS: 0.3 Freya- 7.0 Horus
  * Mint: 15 Olivia - 21.2 Victoria
  * LMDE: 2 Betsy - 6 Faye
  * Kali: kali-rolling/2016.2 - 2023.1
  * Deepin: stable - unstable
  * UOS: apricot - eagle
  * MX Linux: 17.1/18
  * BunsenLabs: Helium - Beryllium
  * Parrot: 4.5 - 5+
  * Devuan: ASCII - Chimaera
  * Pop!_OS: 20.04 Focal - 22.04 Jammy
  * PureOS: 9 Amber - 10 Byzantium
  * Nitrux: nitrux
  * Zorin: focal

  Regardless of which Linux kernel version (>4.15) you're using.
  
  If your distribution or version is not on the list, make sure to include debug information by running: `sudo ./displaylink-debian.sh --debug` and [submit a request to add support for it](https://github.com/AdnanHodzic/displaylink-debian/issues/new).

## Technical

* _displaylink-debian.sh_ downloads and extracts the contents of the
  official [DisplayLink Ubuntu driver][upstream].

* _displaylink-debian.sh_ modifies the contents of the official installer,
  _displaylink-installer.sh_, makes all necessary changes for DisplayLink to work out of box on supported Linux distribution.

*  Install/Reinstall/Uninstall is performed.


## Discussion

* [Kernel agnostic, DisplayLink Debian GNU/Linux driver installer][blog]

## Donate (PayPal or Bitcoin)

Since I'm working on this project in free time without any support or reimbursement from DisplayLink, and [have saved some 100$](https://github.com/AdnanHodzic/displaylink-debian/issues/172#issuecomment-441384936). Please consider supporting this project by making a donation of any amount!

### PayPal
[![paypal](https://www.paypalobjects.com/en_US/NL/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=adnan%40hodzic.org&item_name=Contribution+for+work+on+debian-displaylink&currency_code=EUR&source=url)

### BitCoin
[bc1qlncmgdjyqy8pe4gad4k2s6xtyr8f2r3ehrnl87](bitcoin:bc1qlncmgdjyqy8pe4gad4k2s6xtyr8f2r3ehrnl87)

[![bitcoin](https://foolcontrol.org/wp-content/uploads/2019/08/btc-donate-displaylink-debian.png)](bitcoin:bc1qlncmgdjyqy8pe4gad4k2s6xtyr8f2r3ehrnl87)





[DisplayLink]:        https://www.synaptics.com/products/displaylink-graphics
[upstream]:           https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu
[blog]:               https://foolcontrol.org/?p=1777
[displaylink-debian]: https://github.com/AdnanHodzic/displaylink-debian
[PostInstall]:        docs/post-install-guide.md
[TroubleShooting]:    docs/common-issues.md

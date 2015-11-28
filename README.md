# displaylink-debian
DisplayLink driver installer for Debian (Stretch)

#### displaylink-debian

* Allows you to seamlessly install and uninstall DisplayLink drivers. 

* [Downloads original DisplayLink Ubuntu driver] (http://www.displaylink.com/downloads/ubuntu.php>, modifies its) installer script and performs the install/uninstall.

#### displaylink-installer.sh

* Original installer script, which is currently modified to (only) work with **Debian Stretch on Linux kernel 4.2.***

* During the installation process, _displaylink-debian.sh_ will modify the original _displaylink-installer.sh_ 


### Usage

Just run the script! (as regular user)

`./displaylink-debian`

#### Requirements:

Make sure following are installed:

`apt-get install unzip linux-headers-$(uname -r) dkms`

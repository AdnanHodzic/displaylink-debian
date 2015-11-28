# displaylink-debian
DisplayLink driver installer for Debian (Stretch)

#### Problem
[DisplayLink](http://www.displaylink.com/) releases its drivers only for Ubuntu, and latest kernel they support is 3.19. 


#### displaylink-debian

* Allows you to seamlessly install and uninstall DisplayLink drivers on Debian with 4.2 kernel.


How? Just run the script! (as regular user)

`./displaylink-debian.sh`

but first make sure following dependencies are installed:

`apt-get install unzip linux-headers-$(uname -r) dkms`

#### Technical

##### displaylink-debian.sh

* [Downloads original DisplayLink Ubuntu driver] (http://www.displaylink.com/downloads/ubuntu.php>),  modifies its installer script for Debian and performs the install/uninstall.

##### displaylink-installer.sh

* Original installer script, which is currently modified to (only) work with **Debian Stretch on Linux kernel 4.2.***

* During the installation process, _displaylink-debian.sh_ will modify the original _displaylink-installer.sh_ 

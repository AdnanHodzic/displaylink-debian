# displaylink-debian
DisplayLink driver installer for Debian GNU/Linux and Ubuntu.

#### Problem
[DisplayLink](http://www.displaylink.com/) releases its drivers only for Ubuntu, and latest kernel version they support is 3.19. 


#### displaylink-debian

* Allows you to seamlessly install and uninstall DisplayLink drivers on Debian GNU/Linux and Ubuntu.


How? Just run the script! (as regular user)

`./displaylink-debian.sh`

but first make sure following dependencies are installed:

`apt-get install unzip linux-headers-$(uname -r) dkms lsb-release`

#### Technical

##### displaylink-debian.sh

* Downloads and extracts contents of original [DisplayLink Ubuntu driver] (http://www.displaylink.com/downloads/ubuntu.php>)

* _displaylink-debian.sh_ will modify contents of original _displaylink-installer.sh_ and customize it for Debian. After which install/uninstall is performed. 

* Supported platforms are: 
  * Debian: Jessie/Stretch/Sid (regardless of which kernel version you're using.)
  * Ubuntu >= 15.04 <= 16.04 (regardless of which kernel version you're using.)


#### Discussion
Blog post: [Kernel agnostic, DisplayLink Debian GNU/Linux driver installer (Jessie/Stretch/Sid)](http://foolcontrol.org/?p=1777)

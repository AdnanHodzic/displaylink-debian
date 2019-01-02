#!/bin/bash
#
# displaylink-debian:
# DisplayLink driver installer for Debian and Ubuntu based Linux distributions: Debian, Ubuntu, Elementary OS,
# Mint, Kali, Deepin and more! Full list of all supported platforms: http://bit.ly/2zrwz2u
#
# DisplayLink driver installer for Debian GNU/Linux, Ubuntu, Elementary OS, Mint, Kali, Deepin and more! Full list of all supported Linux distributions
#
# Blog post: http://foolcontrol.org/?p=1777
#
# Copyleft: Adnan Hodzic <adnan@hodzic.org>
# License: GPLv3

# define the version to get as the latest available version
version=`wget -q -O - https://www.displaylink.com/downloads/ubuntu | grep "download-version" | head -n 1 | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/'`
# define download url to be the correct version
dlurl="https://www.displaylink.com/"`wget -q -O - https://www.displaylink.com/downloads/ubuntu | grep "download-link" | head -n 1 | perl -pe '($_)=/<a href="\/([^"]+)"[^>]+class="download-link"/'`
driver_dir=$version

# global vars
lsb="$(lsb_release -is)"
codename="$(lsb_release -cs)"
platform="$(lsb_release -ics | sed '$!s/$/ /' | tr -d '\n')"
kernel="$(uname -r)"
xorg_config_displaylink="/etc/X11/xorg.conf.d/20-displaylink.conf"
dlm_service_check="$(systemctl is-active --quiet dlm.service && echo up and running)"
vga_info="$(lspci | grep -oP '(?<=VGA compatible controller: ).*')"
graphics_vendor="$(lspci -nnk | grep -i vga -A3 | grep 'in use' | cut -d ':' -f2 | sed 's/ //g')"
graphics_subcard="$(lspci -nnk | grep -i vga -A3 | grep Subsystem | cut -d ' ' -f5)"
providers="$(xrandr --listproviders)"


separator(){
sep="\n-------------------------------------------------------------------"
echo -e $sep
}

# Wrong key error message
wrong_key(){
echo -e "\n-----------------------------"
echo -e "\nWrong value. Concentrate!\n"
echo -e "-----------------------------\n"
echo -e "Enter any key to continue"
read key
}

root_check(){
# root check
if (( $EUID != 0 ));
then
	separator
	echo -e "\nMust be run as root (i.e: 'sudo $0')."
	separator
	exit 1
fi
}

# Dependencies
dep_check() {
echo -e "\nChecking dependencies\n"

if [ "$lsb" == "Deepin" ];
then
	deps=(unzip linux-headers-$(uname -r)-deepin dkms lsb-release linux-source-deepin x11-xserver-utils)
else
	deps=(unzip linux-headers-$(uname -r) dkms lsb-release linux-source x11-xserver-utils)
fi

for dep in ${deps[@]}
do
	if ! dpkg -s $dep | grep "Status: install ok installed" > /dev/null 2>&1
	then
		default=y
		read -p "$dep not found! Install? [Y/n] " response
		response=${response:-$default}
		if [[ $response =~  ^(yes|y|Y)$ ]]
		then
			if ! apt-get install $dep
			then
				echo "$dep installation failed.  Aborting."
				exit 1
			fi
		else
			separator
			echo -e "\nCannot continue without $dep.  Aborting."
			separator
		exit 1
		fi
	else
		echo "$dep is installed"
	fi
done
}

distro_check(){
separator
# RedHat
if [ -f /etc/redhat-release ];
then
	echo "This is a Redhat based distro ..."
	# ToDo:
	# Add platform type message for RedHat
	exit 1
else

# Confirm dependencies are in place
dep_check

# Unsupported platform message
message(){
echo -e "\n---------------------------------------------------------------\n"
echo -e "Unsuported platform: $platform"
echo -e "Full list of all supported platforms: http://bit.ly/2zrwz2u"
echo -e ""
echo -e "This tool is Open Source and feel free to extend it"
echo -e "GitHub repo: https://github.com/AdnanHodzic/displaylink-debian/"
echo -e "\n---------------------------------------------------------------\n"
}

# Ubuntu
if [ "$lsb" == "Ubuntu" ];
then
	if [ $codename == "trusty" ] || [ $codename == "vivid" ] || [ $codename == "wily" ] || [ $codename == "xenial" ] || [ $codename == "yakkety" ] || [ $codename == "zesty" ] || [ $codename == "artful" ] || [ $codename == "bionic" ] || [ $codename == "cosmic" ] || [ $codename == "disco" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# elementary OS
elif [ "$lsb" == "elementary OS" ] || [ "$lsb" == "elementary" ];
then
	if [ $codename == "freya" ] || [ $codename == "loki" ] || [ $codename == "juno" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Debian
elif [ "$lsb" == "Debian" ];
then
	if [ $codename == "jessie" ] || [ $codename == "stretch" ] || [ $codename == "sid" ] || [ $codename == "buster" ] || [ $codename == "n/a" ] ;
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Mint
elif [ "$lsb" == "LinuxMint" ];
then
	if [ $codename == "sarah" ] || [ $codename == "rosa" ] || [ $codename == "petra" ] || [ $codename == "olivia" ] || [ $codename == "serena" ] || [ $codename == "sonya" ] || [ $codename == "sylvia" ] || [ $codename == "tara" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Kali
elif [ "$lsb" == "Kali" ];
then
	if [ $codename == "kali-rolling" ] || [ $codename == "2016.2" ] || [ $codename == "2017.3" ] || [ $codename == "2018.3" ] || [ $codename == "2018.4" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Deepin
elif [ "$lsb" == "Deepin" ];
then
	if [ $codename == "unstable" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# MX Linux
elif [ "$lsb" == "MX" ];
then
	if [ $codename == "Horizon" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# BunsenLabs
elif [ "$lsb" == "BunsenLabs" ];
then
	if [ $codename == "helium" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
else
	message
	exit 1
fi
fi
}

sysinitdaemon_get(){
sysinitdaemon="systemd"

if [ "$lsb" == "Ubuntu" ];
then
	if [ $codename == "trusty" ];
	then
        sysinitdaemon="upstart"
	fi
# Elementary
elif [ "$lsb" == "elementary OS" ];
then
    if [ $codename == "freya" ];
    then
        sysinitdaemon="upstart"
    fi
fi

echo $sysinitdaemon
}

clean_up(){
# remove obsolete/redundant files which can only hamper reinstalls

separator
echo -e "\nPerforming clean-up"

# go back to displaylink-debian
cd - &> /dev/null

if [ -f "DisplayLink_Ubuntu_$version.zip" ]
then
	echo "Removing redundant: \"DisplayLink_Ubuntu_$version.zip\" file"
	rm "DisplayLink_Ubuntu_$version.zip"
fi

if [ -d $driver_dir ]
then
	echo "Removing redundant: \"$driver_dir\" directory"
	rm -r $driver_dir
fi

}

setup_complete(){
ack=${ack:-$default}
default=N

read -p "Rebot now? [y/N] " ack
ack=${ack:-$default}

for letter in "$ack"; do
	if [[ "$letter" == [Yy] ]];
	then
			echo "Rebooting ..."
			reboot
	elif [[ "$letter" == [Nn] ]];
	then
			echo -e "\nReboot postponed, changes won't be applied until reboot"
	else
			wrong_key
	fi
done
}

download() {
    local dlfileid=$(echo $dlurl | perl -pe '($_)=/.+\?id=(\d+)/')

    echo -en "\nPlease read the Software License Agreement\navailable at $dlurl\nand accept here: [Y]es or [N]o: "
    read ACCEPT
    case $ACCEPT in
        y*|Y*)
            echo -e "\nDownloading DisplayLink Ubuntu driver:\n"
            wget -O DisplayLink_Ubuntu_${version}.zip "--post-data=fileId=$dlfileid&accept_submit=Accept" $dlurl
            # make sure we got the file downloadet before continueing
            if [ $? -ne 0 ]
            then
            	echo -e "\nUnable to download Displaylink driver\n"
            	exit
            fi
            ;;
        *)
            echo "Can't download the driver without accepting the license agreement!"
            exit 1
            ;;
    esac
}

install(){
separator
download

# prep
mkdir $driver_dir

separator
echo -e "\nPreparing for install\n"
test -d $driver_dir && /bin/rm -Rf $driver_dir
unzip -d $driver_dir DisplayLink_Ubuntu_${version}.zip
chmod +x $driver_dir/displaylink-driver-${version}.[0-9]*.run
./$driver_dir/displaylink-driver-${version}.[0-9]*.run --keep --noexec
mv displaylink-driver-${version}.[0-9]*/ $driver_dir/displaylink-driver-${version}

# get sysinitdaemon
sysinitdaemon=$(sysinitdaemon_get)

# modify displaylink-installer.sh
sed -i "s/SYSTEMINITDAEMON=unknown/SYSTEMINITDAEMON=$sysinitdaemon/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh

if [ "$lsb" == "Debian" ] || [ "$lsb" == "Kali" ] || [ "$lsb" == "Deepin" ] || [ "$lsb" == "BunsenLabs" ];
then
	sed -i 's#/lib/modules/$KVER/build/Kconfig#/lib/modules/$KVER/build/scripts/kconfig/conf#g' $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
	ln -s /lib/modules/$(uname -r)/build/Makefile /lib/modules/$(uname -r)/build/Kconfig
fi

# install
separator
echo -e "\nInstalling driver version: $version\n"
cd $driver_dir/displaylink-driver-${version} && ./displaylink-installer.sh install
}

# post install
post_install(){
separator
echo -e "\nPerforming post install steps\n"

# fix: issue #42 (dlm.service can't start)
# note: for this to work libstdc++6 package needs to be installed from >= Stretch
if [ "$lsb" == "Debian" ] || [ "$lsb" == "Kali" ];
then
	ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/displaylink/libstdc++.so.6
fi

# fix: issue #36 (can't enable dlm.service)
sed -i "/RestartSec=5/a[Install]\nWantedBy=multi-user.target" /lib/systemd/system/dlm.service
sudo systemctl enable dlm.service

# setup xorg.conf depending on graphics card
modesetting(){
test ! -d /etc/X11/xorg.conf.d && mkdir -p /etc/X11/xorg.conf.d
drv=$(lspci -nnk | grep -i vga -A3 | grep 'in use'|cut -d":" -f2|sed 's/ //g')
cardsub=$(lspci -nnk | grep -i vga -A3|grep Subsystem|cut -d" " -f5)

# intel displaylink xorg.conf
xorg_intel(){
cat > $xorg_config_displaylink <<EOL
Section "Device"
    Identifier  "Intel"
    Driver      "intel"
EndSection
EOL
}

# modesetting displaylink xorg.conf
xorg_modesetting(){
cat > $xorg_config_displaylink <<EOL
Section "Device"
    Identifier  "DisplayLink"
    Driver      "modesetting"
    Option      "PageFlip" "false"
EndSection
EOL
}

# nvidia displaylink xorg.conf
xorg_nvidia(){
cat > $xorg_config_displaylink <<EOL
Section "Device"
  Identifier "DisplayLink"
EndSection
EOL
}

# amd displaylink xorg.conf
xorg_amd(){
cat > $xorg_config_displaylink <<EOL
Section "Device"
    Identifier "AMDGPU"
    Driver     "amdgpu"
    Option     "PageFlip" "false"
EndSection
EOL
}

# customize displaylink xorg.conf
if ([ "$drv" == "i915" ] && [ "$cardsub" == "v2/3rd" ] || [ "$cardsub" == "[HD" ] || [ "$cardsub" == "620" ]);
then
		# set xorg for Intel cards pt2 (issue: 179, 68, 88, 192)
		xorg_modesetting
elif ([ "$drv" == "i915" ]);
then
        # set xorg for Intel cards
        xorg_intel
elif ([ "$drv" == "nvidia" ]);
then
		# set xorg for Nvidia cards
		xorg_nvidia
elif ([ "$drv" == "nvidia" ] && [ "$cardsub" == "GP106" ]);
then
		# set xorg for Nvidia cards pt2 (issue: 176, 179)
		xorg_modesetting
elif ([ "$drv" == "amdgpu" ]);
then
		# set xorg for AMD cards (issue: 180)
		xorg_amd
else
		# default xorg setting
		xorg_modesetting
fi

chown root: $xorg_config_displaylink
chmod 644 $xorg_config_displaylink
}

function ver2int {
echo "$@" | awk -F "." '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

xorg_vcheck="$(dpkg -l | grep "ii  xserver-xorg-core" | awk '{print $3}' | sed 's/[^,:]*://g')"
min_xorg=1.18.3

if [ "$(ver2int $xorg_vcheck)" -gt "$(ver2int $min_xorg)" ];
then
	echo "Setup DisplayLink xorg.conf depending on graphics card"
	modesetting
else
	echo "No need to disable PageFlip for modesetting"
fi
}

# uninstall
uninstall(){
separator
echo -e "\nUninstalling ...\n"

# displaylink-installer uninstall
if [ "$lsb" == "Debian" ] || [ "$lsb" == "Kali" ] || [ "$lsb" == "Deepin" ] || [ "$lsb" == "BunsenLabs" ];
then
	rm /lib/modules/$(uname -r)/build/Kconfig
fi

# evdi module still in use (issue 178, 192)
evdi_version="$(systemctl status dlm.service | grep -o '4.4.[[:digit:]]*')"
dkms remove evdi/$evdi_version --all
evdi_dir="/usr/src/evdi-$evdi_version"
if [ -d "$evdi_dir" ];
then
		rm -rf $evdi_dir
fi

# disabled and remove dlm.service
systemctl disable dlm.service
rm -f /lib/systemd/system/dlm.service

# double check if evdi module is loaded, if yes remove it
if lsmod | grep "evdi" &> /dev/null ; then
	echo "Removing evdi module"
	rmmod evdi
fi

# remove modesetting file
if [ -f $xorg_config_displaylink ]
then
		echo "Removing Displaylink Xorg config file"
		rm $xorg_config_displaylink
fi

}

# debug: get system information for issue debug
debug(){
separator
echo -e "\nStarting Debug ...\n"

ack=${ack:-$default}
default=N

read -p "Did you read Post Installation Guide? http://bit.ly/2TbZleK [y/N] " ack
ack=${ack:-$default}

for letter in "$ack"; do
	if [[ "$letter" == [Yy] ]];
	then
			echo ""
			continue
	elif [[ "$letter" == [Nn] ]];
	then
			echo -e "\nPlease read Post Installation Guide: http://bit.ly/2TbZleK\n"
			exit 1
	else
			wrong_key
	fi
done

read -p "Did you read Troubleshooting most common issues? http://bit.ly/2Rofd0x [y/N] " ack
ack=${ack:-$default}

for letter in "$ack"; do
	if [[ "$letter" == [Yy] ]];
	then
			echo -e ""
			continue
	elif [[ "$letter" == [Nn] ]];
	then
			echo -e "\nPlease read Troubleshooting most common issues: http://bit.ly/2Rofd0x\n"
			exit 1
	else
			wrong_key
	fi
done

evdi_version="$(systemctl status dlm.service | grep -o '4.4.[[:digit:]]*')"
echo -e "--------------- Linux system info ----------------\n"
echo -e "Distro: $lsb"
echo -e "Release: $codename"
echo -e "Kernel: $kernel"
echo -e "\n---------------- DisplayLink info ----------------\n"
echo -e "Driver version: $version"
echo -e "EVDI service status: $dlm_service_check"
echo -e "EVDI service version: $evdi_version"
echo -e "\n------------------ Graphics card -----------------\n"
echo -e "Vendor: $graphics_vendor"
echo -e "Subsystem: $graphics_subcard"
echo -e "VGA: $vga_info"
echo -e "\n-------------- DisplayLink xorg.conf -------------\n"
echo -e "File: $xorg_config_displaylink"
echo -e "Contents:\n $(cat $xorg_config_displaylink)"
echo -e "\n-------------------- Monitors --------------------\n"
echo -e "$providers"
}

# interactively asks for operation
ask_operation(){
echo -e "\n--------------------------- displaylink-debian -------------------------------"
echo -e "\nDisplayLink driver installer for Debian and Ubuntu based Linux distributions:\n"
echo -e "* Debian, Ubuntu, Elementary OS, Mint, Kali, Deepin and many more!"
echo -e "* Full list of all supported platforms: http://bit.ly/2zrwz2u"
echo -e "* When submitting a new issue, include Debug information"
echo -e "\nOptions:\n"
read -p "[I]nstall
[D]ebug
[R]e-install
[U]ninstall
[Q]uit

Select a key: [i/d/r/u/q]: " answer
}

root_check

if [[ -z "${1}" ]];
then
  ask_operation
else
  case "${1}" in
    "--install")
        answer="i"
        ;;
    "--uninstall")
        answer="u"
        ;;
    "--reinstall")
        answer="r"
        ;;
    "--debug")
        answer="d"
        ;;
    *)
        answer="n"
        ;;
  esac
fi

if [[ $answer == [Ii] ]];
then
	distro_check
	install
	post_install
	clean_up
	separator
	echo -e "\nInstall complete, please reboot to apply the changes"
	echo -e "After reboot, make sure to consult post-install guide! http://bit.ly/2TbZleK"
	setup_complete
	separator
	echo ""
elif [[ $answer == [Uu] ]];
then
	distro_check
	uninstall
	clean_up
	separator
	echo -e "\nUninstall complete, please reboot to apply the changes"
	setup_complete
	separator
	echo ""
elif [[ $answer == [Rr] ]];
then
	distro_check
	uninstall
	clean_up
	distro_check
	install
	post_install
	clean_up
	separator
	echo -e "\nInstall complete, please reboot to apply the changes"
	echo -e "After reboot, make sure to consult post-install guide! http://bit.ly/2TbZleK"
	setup_complete
	separator
	echo ""
elif [[ $answer == [Dd] ]];
then
	debug
	separator
	echo -e "\nUse this information when submitting an issue (http://bit.ly/2GLDlpY)"
	separator
	echo ""
elif [[ $answer == [Qq] ]];
then
	separator
	echo ""
	exit 0
else
	echo -e "\nWrong key, aborting ...\n"
	exit 1
fi

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

separator(){
sep="\n-------------------------------------------------------------------"
echo -e $sep
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
	deps=(unzip linux-headers-$(uname -r)-deepin dkms lsb-release linux-source-deepin)
else
	deps=(unzip linux-headers-$(uname -r) dkms lsb-release linux-source)
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

# Checker parameters
lsb="$(lsb_release -is)"
codename="$(lsb_release -cs)"
platform="$(lsb_release -ics | sed '$!s/$/ /' | tr -d '\n')"

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

# disable pageflip for modesetting
modesetting(){
test ! -d /etc/X11/xorg.conf.d && mkdir -p /etc/X11/xorg.conf.d
drv=$(lspci -nnk | grep -i vga -A3 | grep 'in use'|cut -d":" -f2|sed 's/ //g')
cardsub=$(lspci -nnk | grep -i vga -A3|grep Subsystem|cut -d" " -f5)
if ([ "$drv" == "i915" ]);
then
cat > /etc/X11/xorg.conf.d/20-displaylink.conf <<EOL
Section "Device"
    Identifier  "Intel"
    Driver      "intel"
EndSection
EOL
elif ([ "$drv" == "i915" ] && [ "$cardsub" == "v2/3rd" ]);
then
cat > /etc/X11/xorg.conf.d/20-displaylink.conf <<EOL
Section "Device"
    Identifier  "DisplayLink"
    Driver      "modesetting"
    Option      "PageFlip" "false"
EndSection
EOL
elif ([ "$drv" == "nvidia" ]);
then
cat > /etc/X11/xorg.conf.d/20-displaylink.conf <<EOL
Section "Device"
  Identifier "DisplayLink"
EndSection
EOL
elif ([ "$drv" == "nvidia" ] && [ "$cardsub" == "GP106" ]);
then
cat > /etc/X11/xorg.conf.d/20-displaylink.conf <<EOL
Section "Device"
    Identifier  "DisplayLink"
    Driver      "modesetting"
    Option      "PageFlip" "false"
EndSection
EOL
elif ([ "$drv" == "amdgpu" ]);
then
cat > /etc/X11/xorg.conf.d/20-displaylink.conf <<EOL
Section "Device"
    Identifier "AMDGPU"
    Driver     "amdgpu"
    Option     "PageFlip" "false"
EndSection
EOL
else
cat > /etc/X11/xorg.conf.d/20-displaylink.conf <<EOL
Section "Device"
    Identifier  "DisplayLink"
    Driver      "modesetting"
    Option      "PageFlip" "false"
EndSection
EOL
fi

chown root: /etc/X11/xorg.conf.d/20-displaylink.conf
chmod 644 /etc/X11/xorg.conf.d/20-displaylink.conf
}

function ver2int {
echo "$@" | awk -F "." '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

xorg_vcheck="$(dpkg -l | grep "ii  xserver-xorg-core" | awk '{print $3}' | sed 's/[^,:]*://g')"
min_xorg=1.18.3

if [ "$(ver2int $xorg_vcheck)" -gt "$(ver2int $min_xorg)" ];
then
	echo "Disabling PageFlip for modesetting"
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

# double check if evdi module is loaded, if yes remove it
evdi_module="evdi"

if lsmod | grep "$evdi_module" &> /dev/null ; then
	echo "Removing $evdi_module module"
	rmmod evdi
fi

# remove modesetting file
if [ -f "/etc/X11/xorg.conf.d/20-displaylink.conf" ]
then
		echo "Removing disabled PageFlip for modesetting"
		rm "/etc/X11/xorg.conf.d/20-displaylink.conf"
fi

}

# interactively asks for operation
ask_operation(){
    echo -e "\n--------------------------- displaylink-debian -------------------------------"
    echo -e "\nDisplayLink driver installer for Debian and Ubuntu based Linux distributions:\n"
    echo -e "* Debian, Ubuntu, Elementary OS, Mint, Kali, Deepin and many more!"
    echo -e "* Full list of all supported platforms: http://bit.ly/2zrwz2u"
    echo -e "\nOptions:\n"
    read -p "[I]nstall
[U]ninstall
[R]e-install
[Q]uit

Select a key: [i/u/r/q]: " answer
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
	echo -e "\nInstall complete, please reboot then consult the post-install guide to complete the installation"
	separator
	echo ""
elif [[ $answer == [Uu] ]];
then
	distro_check
	uninstall
	clean_up
	separator
	echo -e "\nUninstall complete"
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
	echo -e "\nRe-install complete, please reboot then consult the post-install guide to complete the installation"
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

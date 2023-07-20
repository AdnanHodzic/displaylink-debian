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

# Bash Strict Mode
set -eu
# set -o pipefail # TODO: Some code still fails this check, fix before enabling.
IFS=$'\n\t'

kernel_check="$(uname -r | egrep -o '^[0-9]+\.[0-9]+')"

function ver2int {
echo "$@" | awk -F "." '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

# Get latest versions
versions=$(wget -q -O - https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu | grep "<p>Release: " | head -n 2 | perl -pe '($_)=/([0-9]+([.][0-9]+)+(\ Beta)*)/; exit if $. > 1;')
# if versions contains "Beta", try to download previous version
if [[ $versions =~ Beta ]]; then
    version=$(wget -q -O - https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu | grep "<p>Release: " | head -n 2 | perl -pe '($_)=/([0-9]+([.][0-9]+)+(?!\ Beta))/; exit if $. > 1;')
    dlurl="https://www.synaptics.com/$(wget -q -O - https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu | grep -B 2 $version'-Release' | perl -pe '($_)=/<a href="\/([^"]+)"[^>]+class="download-link"/')"
    driver_url="https://www.synaptics.com/$(wget -q -O - ${dlurl} | grep '<a class="no-link"' | head -n 1 | perl -pe '($_)=/href="\/([^"]+)"/')"
else
    version=`wget -q -O - https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu | grep "<p>Release: " | head -n 1 | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/; exit if $. > 1;'`
    dlurl="https://www.synaptics.com/$(wget -q -O - https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu | grep -B 2 $version'-Release' | perl -pe '($_)=/<a href="\/([^"]+)"[^>]+class="download-link"/')"
    driver_url="https://www.synaptics.com/$(wget -q -O - ${dlurl} | grep '<a class="no-link"' | head -n 1 | perl -pe '($_)=/href="\/([^"]+)"/')"
fi
driver_dir=$version
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"
resourcesDir="$(pwd)/resources/"

# globalvars
lsb="$(lsb_release -is)"
codename="$(lsb_release -cs)"
platform="$(lsb_release -ics | sed '$!s/$/ /' | tr -d '\n')"
kernel="$(uname -r)"
xorg_config_displaylink="/etc/X11/xorg.conf.d/20-displaylink.conf"
blacklist="/etc/modprobe.d/blacklist.conf"
sys_driver_version="$(ls /usr/src/ | grep "evdi" | cut -d "-" -f2)"
vga_info="$(lspci | grep -oP '(?<=VGA compatible controller: ).*')" || :
vga_info_3d="$(lspci | grep -i '3d controller' | sed 's/^.*: //')"
graphics_vendor="$(lspci -nnk | grep -i vga -A3 | grep 'in use' | cut -d ':' -f2 | sed 's/ //g')"
graphics_subcard="$(lspci -nnk | grep -i vga -A3 | grep Subsystem | cut -d ' ' -f5)"
providers="$(xrandr --listproviders)"
xorg_vcheck="$(dpkg -l | grep "ii  xserver-xorg-core" | awk '{print $3}' | sed 's/[^,:]*://g')"
min_xorg=1.18.3
newgen_xorg=1.19.6
init_script='displaylink.sh'
evdi_modprobe='/etc/modules-load.d/evdi.conf'
kconfig_file="/lib/modules/$kernel/build/Kconfig"

# Using modules-load.d should always be preferred to 'modprobe evdi' in start
# command

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

# list all xorg related configs
xconfig_list(){
x11_etc="/etc/X11/"

if [ ! -d "${x11_etc}" ] ; then # No directory found
	echo "X11 configs: None"
	return 0
fi

count_conf_in_etc=$(find $x11_etc -maxdepth 2 -name "*.conf" | wc -l)
if [ $count_conf_in_etc -gt 0 ]; then
	find $x11_etc -type f -name "*.conf" | xargs echo "X11 configs:"
fi
}

# Dependencies
dep_check() {
echo -e "\nChecking dependencies\n"

deps=(unzip linux-headers-$(uname -r) dkms lsb-release linux-source x11-xserver-utils wget libdrm-dev libelf-dev git pciutils)

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
if [ "$lsb" == "Ubuntu" ] || [ "$lsb" == "Neon" ];
then
	if [ $codename == "trusty" ] || [ $codename == "vivid" ] || [ $codename == "wily" ] || [ $codename == "xenial" ] || [ $codename == "yakkety" ] || [ $codename == "zesty" ] || [ $codename == "artful" ] || [ $codename == "bionic" ] || [ $codename == "cosmic" ] || [ $codename == "disco" ] || [ $codename == "eoan" ] || [ $codename == "focal" ] || [ $codename == "groovy" ] || [ $codename == "hirsute" ] || [ $codename == "impish" ] || [ $codename == "jammy" ] || [ $codename == "kinetic" ] || [ $codename == "lunar" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# elementary OS
elif [ "$lsb" == "elementary OS" ] || echo $lsb | grep -qi "elementary";
then
	if [ $codename == "freya" ] || [ $codename == "loki" ] || [ $codename == "juno" ] || [ $codename == "hera" ] || [ $codename == "odin" ] || [ $codename == "jolnir" ] || [ $codename == "horus" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Debian
elif [ "$lsb" == "Debian" ];
then
	if [ $codename == "jessie" ] || [ $codename == "stretch" ] || [ $codename == "buster" ] || [ $codename == "bullseye" ] || [ $codename == "bookworm" ] || [ $codename == "trixie" ] || [ $codename == "sid" ] || [ $codename == "n/a" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Devuan
elif [ "$lsb" == "Devuan" ]
then
    if [ "$codename" == "ascii" ] || [ "$codename" == "beowulf" ] || [ "$codename" == "chimaera" ];
    then
        echo -e "\nPlatform requirements satisfied, proceeding ..."
    else
        message
        exit 1
    fi
# Mint
# Issue 464	
elif echo $lsb | grep -qi "Linuxmint" ;
then
	if [ $codename == "sarah" ] || [ $codename == "rosa" ] || [ $codename == "petra" ] || [ $codename == "olivia" ] || [ $codename == "serena" ] || [ $codename == "sonya" ] || [ $codename == "sylvia" ] || [ $codename == "tara" ] || [ $codename == "tessa" ] || [ $codename == "betsy" ] || [ $codename == "cindy" ] || [ $codename == "tina" ] || [ $codename == "tricia" ] || [ $codename == "debbie" ] || [ $codename == "ulyana" ] || [ $codename == "ulyssa" ] || [ $codename == "uma" ] || [ $codename == "una" ] || [ $codename == "elsie" ] || [ $codename == "vanessa" ] || [ $codename == "vera" ] || [ $codename == "victoria" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Kali
elif [ "$lsb" == "Kali" ];
then
	# issue: 204
	if [ $codename == "kali-rolling" ] || [ $codename == "2016.2" ] || [ $codename == "2017.3" ] || [ $codename == "2018.3" ] || [ $codename == "2018.4" ] || [ $codename == "2022.1" ] || [ $codename == "n/a" ] || [ $codename == "2022.2" ] || [ $codename == "2022.3" ] || [ $codename == "2022.4" ] || [ $codename == "2023.1" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Deepin
elif [ "$lsb" == "Deepin" ] || [ "$lsb" == "Uos" ] ;
then
	if [ $codename == "unstable" ] || [ $codename == "stable" ] || [ $codename == "eagle" ] || [ $codename == "apricot" ] || [ $codename == "n/a" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# MX Linux
elif [ "$lsb" == "MX" ];
then
	if [ $codename == "Horizon" ] || [ $codename == "Continuum" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# BunsenLabs
elif [ "$lsb" == "BunsenLabs" ] || [ "$lsb" == "Bunsenlabs" ];
then
	if [ $codename == "helium" ] || [ $codename == "lithium" ] || [ $codename == "buster" ] || [ $codename == "beryllium" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Parrot
elif [ "$lsb" == "Parrot" ];
then
	if [ $codename == "n/a" ] || [ $codename == "lts" ] || [ $codename == "ara" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# PopOS
elif [ "$lsb" == "Pop" ];
then
	if [ $codename == "focal" ] || [ $codename == "groovy" ] || [ $codename == "hirsute" ] || [ $codename == "impish" ] || [ $codename == "jammy" ] || [ $codename == "n/a" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# PureOS
elif [ "$lsb" == "PureOS" ];
then
	if [ $codename == "amber" ] || [ $codename == "byzantium" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi
# Nitrux
elif [ "$lsb" == "Nitrux" ];
then
	if [ $codename == "nitrux" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ..."
	else
		message
		exit 1
	fi	
# Zorin
elif [ "$lsb" == "Zorin" ];
then
	if [ $codename == "focal" ];
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

pre_install() {

if [ -f $kconfig_file ];
then
  kconfig_exists="true"
else
  kconfig_exists="false"
  touch $kconfig_file
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
elif [ "$lsb" == "elementary OS" ] || echo $lsb | grep -qi "elementary";
then
    if [ $codename == "freya" ];
    then
        sysinitdaemon="upstart"
    fi
elif [ "$lsb" == "Devuan" ]
then
    sysinitdaemon="sysvinit"
fi

echo $sysinitdaemon
}

displaylink_service_check () {
    sysinitdaemon=$(sysinitdaemon_get)
    if [ "$sysinitdaemon" == "systemd" ]
    then
        systemctl is-active --quiet displaylink-driver.service && \
            echo up and running
    elif [ "$sysinitdaemon" == "sysvinit" ]
    then
        /etc/init.d/$init_script status
    fi
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
default=Y
ack=${ack:-$default}

read -p "Reboot now? [Y/n] " ack
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
default=y
echo -en "\nPlease read the Software License Agreement available at: \n$dlurl\nDo you accept?: [Y/n]: "
read ACCEPT
ACCEPT=${ACCEPT:-$default}
case $ACCEPT in
		y*|Y*)
				echo -e "\nDownloading DisplayLink Ubuntu driver:\n"
				wget -O DisplayLink_Ubuntu_${version}.zip "${driver_url}"
				# make sure file is downloaded before continuing
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
# Check whether prior drivers have been downloaded
if [ -d $driver_dir ]
then
	echo "Removing prior: \"$driver_dir\" directory"
	rm -r $driver_dir
fi

mkdir $driver_dir

separator
echo -e "\nPreparing for install\n"
test -d $driver_dir && /bin/rm -Rf $driver_dir
unzip -d $driver_dir DisplayLink_Ubuntu_${version}.zip
chmod +x $driver_dir/displaylink-driver-${version}[.\d]*-[0-9]*.[0-9]*.run
./$driver_dir/displaylink-driver-${version}[.\d]*-[0-9]*.[0-9]*.run --keep --noexec
mv displaylink-driver-${version}[.\d]*-*[0-9]*.[0-9]*/ $driver_dir/displaylink-driver-${version}
# get sysinitdaemon
sysinitdaemon=$(sysinitdaemon_get)

# modify displaylink-installer.sh
sed -i "s/SYSTEMINITDAEMON=unknown/SYSTEMINITDAEMON=$sysinitdaemon/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh

# issue: 227
if [ "$lsb" == "Debian" ] || [ "$lsb" == "Devuan" ] || [ "$lsb" == "Kali" ] || [ "$lsb" == "Deepin" ] || [ "$lsb" == "BunsenLabs" ] || [ "$lsb" == "Bunsenlabs" ] || [ "$lsb" == "MX" ] || [ "$lsb" == "Uos" ];
then
	sed -i 's#/lib/modules/$KVER/build/Kconfig#/lib/modules/$KVER/build/scripts/kconfig/conf#g' $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
	ln -sf /lib/modules/$(uname -r)/build/Makefile /lib/modules/$(uname -r)/build/Kconfig
fi

# Patch displaylink-installer.sh to prevent reboot before our script is done.
patchName="displaylink-installer.patch"
finalPatchPath="$resourcesDir$patchName"
patch -Np0 $driver_dir/displaylink-driver-${version}/displaylink-installer.sh <$finalPatchPath

# run displaylink install
echo -e "\nInstalling driver version: $version\n"
cd $driver_dir/displaylink-driver-${version}
./displaylink-installer.sh install


# udlfb kernel version check
kernel_check="$(uname -r | egrep -o '[0-9]+\.[0-9]+')"

# add udlfb to blacklist (issue #207)
udl_block(){

# if necessary create blacklist.conf
if [ ! -f $blacklist ]; then
		touch $blacklist
fi

if ! grep -Fxq "blacklist udlfb" $blacklist
then
		echo "Adding udlfb to blacklist"
		echo "blacklist udlfb" >> $blacklist
fi

# add udl to blacklist (issue #207)
if ! grep -Fxq "blacklist udl" $blacklist
then
		echo "Adding udl to blacklist"
		echo "blacklist udl" >> $blacklist
fi
}

# add udl/udlfb to blacklist depending on kernel version (issue #207)
if [ "$(ver2int $kernel_check)" -ge "$(ver2int '4.14.9')" ];
then
		udl_block
fi

}

# post install
post_install(){
separator
echo -e "\nPerforming post install steps\n"

if [ "$kconfig_exists" == "false" ];
then
  rm $kconfig_file
fi

# fix: issue #42 (dlm.service can't start)
# note: for this to work libstdc++6 package needs to be installed from >= Stretch
if [ "$lsb" == "Debian" ] || [ "$lsb" == "Devuan" ] || [ "$lsb" == "Kali" ];
then
	ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/displaylink/libstdc++.so.6
fi

sysinitdaemon=$(sysinitdaemon_get)
if [ "$sysinitdaemon" == "systemd" ]
then
    # Fix inability to enable displaylink-driver.service
    sed -i "/RestartSec=5/a[Install]\nWantedBy=multi-user.target" /lib/systemd/system/displaylink-driver.service

    echo "Enable displaylink-driver service"
    systemctl enable displaylink-driver.service
elif [ "$sysinitdaemon" == "sysvinit" ]
then
    echo "Copying init script to /etc/init.d\n"
    cp "$dir/$init_script" /etc/init.d/
    chmod +x "/etc/init.d/$init_script"
    echo "Load evdi at startup"
    cat > "$evdi_modprobe" <<EOF
evdi
EOF
    echo "Enable and start displaylink service"
    update-rc.d "$init_script" defaults
    /etc/init.d/$init_script start
fi

# setup xorg.conf depending on graphics card
modesetting(){
test ! -d /etc/X11/xorg.conf.d && mkdir -p /etc/X11/xorg.conf.d
drv=$(lspci -nnk | grep -i vga -A3 | grep 'in use'|cut -d":" -f2|sed 's/ //g')
drv_nvidia=$(lspci | grep -i '3d controller' | sed 's/^.*: //' | awk '{print $1}')
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

# modesetting displaylink xorg.conf
xorg_modesetting_newgen(){
cat > $xorg_config_displaylink <<EOL
Section "OutputClass"
    Identifier  "DisplayLink"
    MatchDriver "evdi"
    Driver      "modesetting"
    Option      "AccelMethod" "none"
EndSection
EOL
}

nvidia_pregame(){
xsetup_loc="/usr/share/sddm/scripts/Xsetup"

nvidia_xrandr(){
cat >> $xsetup_loc << EOL

xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
EOL
}

nvidia_xrandr_full(){
cat >> $xsetup_loc << EOL
#!/bin/sh
# Xsetup - run as root before the login dialog appears

if [ -e /sbin/prime-offload ]; then
    echo running NVIDIA Prime setup /sbin/prime-offload
    /sbin/prime-offload
fi

xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
EOL
}

# create Xsetup file if not there + make necessary changes (issue: #201, #206)
if [ ! -f $xsetup_loc ];
then
    echo "$xsetup_loc not found, creating"
		mkdir -p /usr/share/sddm/scripts/
		touch $xsetup_loc
		nvidia_xrandr_full
		chmod +x $xsetup_loc
		echo -e "Wrote changes to $xsetup_loc"
fi

# make necessary changes to Xsetup
if ! grep -q "setprovideroutputsource modesetting" $xsetup_loc
then
		mv $xsetup_loc $xsetup_loc.org.bak
		echo -e "\nMade backup of: $xsetup_loc file"
		echo -e "\nLocation: $xsetup_loc.org.bak"
		nvidia_xrandr
		chmod +x $xsetup_loc
		echo -e "Wrote changes to $xsetup_loc"
fi

# xorg.conf ops
xorg_config="/etc/x11/xorg.conf"
usr_xorg_config_displaylink="/usr/share/X11/xorg.conf.d/20-displaylink.conf"

if [ -f $xorg_config ];
then
		mv $xorg_config $xorg_config.org.bak
		echo -e "\nMade backup of: $xorg_config file"
		echo -e "\nLocation: $xorg_config.org.bak"
fi

if [ -f $xorg_config_displaylink ];
then
		mv $xorg_config_displaylink $xorg_config_displaylink.org.bak
		echo -e "\nMade backup of: $xorg_config_displaylink file"
		echo -e "\nLocation: $xorg_config_displaylink.org.bak"
fi

if [ -f $usr_xorg_config_displaylink ];
then
		mv $usr_xorg_config_displaylink $usr_xorg_config_displaylink.org.bak
		echo -e "\nMade backup of: $usr_xorg_config_displaylink file"
		echo -e "\nLocation: $usr_xorg_config_displaylink.org.bak"
fi
}

# nvidia displaylink xorg.conf (issue: 176)
xorg_nvidia(){
cat > $xorg_config_displaylink <<EOL
Section "ServerLayout"
    Identifier "layout"
    Screen 0 "nvidia"
    Inactive "intel"
EndSection

Section "Device"
    Identifier "intel"
    Driver "modesetting"
    Option "AccelMethod" "None"
EndSection

Section "Screen"
    Identifier "intel"
    Device "intel"
EndSection

Section "Device"
    Identifier "nvidia"
    Driver "nvidia"
    Option "ConstrainCursor" "off"
EndSection

Section "Screen"
    Identifier "nvidia"
    Device "nvidia"
    Option "AllowEmptyInitialConfiguration" "on"
    Option "IgnoreDisplayDevices" "CRT"
EndSection
EOL
}

# issue: 204, 216
nvidia_hashcat(){
echo "Installing hashcat-nvidia, 'contrib non-free' must be enabled in apt sources"
apt-get install hashcat-nvidia
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

# set xorg for Nvidia cards (issue: 176, 179, 211, 217, 596)
if [ "$drv_nvidia" == "NVIDIA" ] || [[ $drv == *"nvidia"* ]];
then
		nvidia_pregame
		xorg_nvidia
		#nvidia_hashcat
# set xorg for AMD cards (issue: 180)
elif [ "$drv" == "amdgpu" ];
then
		xorg_amd
# set xorg for Intel cards
elif [ "$drv" == "i915" ];
then
		# set xorg modesetting for Intel cards (issue: 179, 68, 88, 192)
		if [ "$cardsub" == "v2/3rd" ] || [ "$cardsub" == "HD" ] || [ "$cardsub" == "620" ] || [ "$cardsub" == "530" ] || [ "$cardsub" == "540" ] || [ "$cardsub" == "UHD" ] || [ "$cardsub" == "GT2" ];
		then
				if [ "$(ver2int $xorg_vcheck)" -gt "$(ver2int $newgen_xorg)" ];
				then
						# reference: issue #200
						xorg_modesetting_newgen
				else
						xorg_modesetting
				fi
		# generic intel
		else
				xorg_intel
		fi
# default xorg modesetting
else
		if [ "$(ver2int $xorg_vcheck)" -gt "$(ver2int $newgen_xorg)" ];
		then
				# reference: issue #200
				xorg_modesetting_newgen
		else
				xorg_modesetting
		fi
fi

echo -e "Wrote X11 changes to: $xorg_config_displaylink"
chown root: $xorg_config_displaylink
chmod 644 $xorg_config_displaylink
}

function ver2int {
echo "$@" | awk -F "." '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

# depending on X11 version start modesetting func
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
if [ "$lsb" == "Debian" ] || [ "$lsb" == "Devuan" ] || [ "$lsb" == "Kali" ] || [ "$lsb" == "Deepin" ] || [ "$lsb" == "BunsenLabs" ] || [ "$lsb" == "Bunsenlabs" ] || [ "$lsb" == "Uos" ];
then
	if [ -f /lib/modules/$(uname -r)/build/Kconfig ]; then
		rm /lib/modules/$(uname -r)/build/Kconfig
	fi
fi

if [ "$(sysinitdaemon_get)" == "sysvinit" ]
then
    update-rc.d "$init_script" remove
    rm -f "/etc/init.d/$init_script"
    rm -f "$evdi_modprobe"
fi

# run unintsall script
bash /opt/displaylink/displaylink-installer.sh uninstall && 2>&1>/dev/null

# remove modesetting file
if [ -f $xorg_config_displaylink ]
then
		echo "Removing Displaylink Xorg config file"
		rm $xorg_config_displaylink
fi

# delete udl/udlfb from blacklist (issue #207)
sed -i '/blacklist udlfb/d' $blacklist
sed -i '/blacklist udl/d' $blacklist

}

# debug: get system information for issue debug
debug(){
separator
echo -e "\nStarting Debug ...\n"

default=N
ack=${ack:-$default}

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

if [ -f /sys/devices/evdi/version ]
then
	evdi_version="$(cat /sys/devices/evdi/version)"
else
	evdi_version="/sys/devices/evdi/version not found"
fi

echo -e "--------------- Linux system info ----------------\n"
echo -e "Distro: $lsb"
echo -e "Release: $codename"
echo -e "Kernel: $kernel"
echo -e "\n---------------- DisplayLink info ----------------\n"
echo -e "Driver version: $sys_driver_version"
echo -e "DisplayLink service status: $(displaylink_service_check)"
echo -e "EVDI service version: $evdi_version"
echo -e "\n------------------ Graphics card -----------------\n"
echo -e "Vendor: $graphics_vendor"
echo -e "Subsystem: $graphics_subcard"
echo -e "VGA: $vga_info"
echo -e "VGA (3D): $vga_info_3d"
echo -e "X11 version: $xorg_vcheck"
xconfig_list
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

if [[ "$#" -lt 1 ]];
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
        pre_install
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
	pre_install
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

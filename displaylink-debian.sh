#!/bin/bash
#
# DisplayLink driver installer for Linux
# Supported platforms: Debian GNU/Linux, Ubuntu, Elementary OS, Mint, Kali
#
# Blog post: http://foolcontrol.org/?p=1777
#
# Copyleft: Adnan Hodzic <adnan@hodzic.org>
# License: GPLv3

version=1.2.58
driver_dir=$version

# Dependencies
deps=(unzip linux-headers-$(uname -r) dkms lsb-release)

dep_check() {
echo "Checking dependencies..."
for dep in ${deps[@]}
do
	if ! dpkg -s $dep > /dev/null 2>&1
	then
		read -p "$dep not found! Install? [y/N] " response
		response=${response,,} # tolower
		if [[ $response =~ ^(yes|y)$ ]]
		then
			if ! sudo apt-get install $dep
			then
				echo "$dep installation failed.  Aborting."
				exit 1
			fi
		else
			echo "Cannot continue without $dep.  Aborting."
		exit 1
		fi
	else
		echo "$dep is installed"
	fi
done
}

distro_check(){

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
echo -e ""
echo -e "This tool is Open Source and feel free to extend it"
echo -e "GitHub repo: https://github.com/AdnanHodzic/displaylink-debian/"
echo -e "\n---------------------------------------------------------------\n"
}

# Ubuntu
if [ "$lsb" == "Ubuntu" ];
then
	if [ $codename == "trusty" ] || [ $codename == "vivid" ] || [ $codename == "wily" ] || [ $codename == "xenial" ] || [ $codename == "yakkety" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
	else
		message
		exit 1
	fi
# elementary OS
elif [ "$lsb" == "elementary OS" ] || [ "$lsb" == "elementary" ];
then
	if [ $codename == "freya" ] || [ $codename == "loki" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
	else
		message
		exit 1
	fi
# Debian
elif [ "$lsb" == "Debian" ];
then
	if [ $codename == "jessie" ] || [ $codename == "stretch" ] || [ $codename == "sid" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
	else
		message
		exit 1
	fi
# Mint
elif [ "$lsb" == "LinuxMint" ];
then
	if [ $codename == "sarah" ] || [ $codename == "rosa" ] || [ $codename == "petra" ] || [ $codename == "olivia" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
	else
		message
		exit 1
	fi
# Kali
elif [ "$lsb" == "Kali" ];
then
	if [ $codename == "kali-rolling" ] || [ $codename == "2016.2" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
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

install_clean_up(){
# remove obsolete/redundant files which can only hamper reinstalls

# go back to displaylink-debian
cd - &> /dev/null

if [ -f "DisplayLink_Ubuntu_$version.zip" ]
then
	echo "Removing redundant: \"DisplayLink_Ubuntu_$version.zip\" file"
	rm "DisplayLink_Ubuntu_$version.zip"
fi
}

uninstall_clean_up(){
# remove obsolete/redundant files
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


install(){
echo -e "\nDownloading DisplayLink Ubuntu driver:"
dlurl="http://www.displaylink.com/downloads/file?id=701"
wget -O DisplayLink_Ubuntu_${version}.zip $dlurl
# prep
mkdir $driver_dir
echo -e "\nPrepring for install ...\n"
test -d $driver_dir && /bin/rm -Rf $driver_dir
unzip -d $driver_dir DisplayLink_Ubuntu_${version}.zip
chmod +x $driver_dir/displaylink-driver-${version}.run
./$driver_dir/displaylink-driver-${version}.run --keep --noexec
mv displaylink-driver-${version}/ $driver_dir/displaylink-driver-${version}

# get sysinitdaemon
sysinitdaemon=$(sysinitdaemon_get)

# modify displaylink-installer.sh
sed -i "s/SYSTEMINITDAEMON=unknown/SYSTEMINITDAEMON=$sysinitdaemon/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
sed -i "s/"179"/"17e9"/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
sed -i "s/detect_distro/detect_distro/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh 
sed -i "s/detect_distro()/detect_distro()/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh 
sed -i "s/check_requirements/check_requirements/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
sed -i "s/check_requirements()/check_requirements()/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh

# install
echo -e "\nInstalling ... \n"
cd $driver_dir/displaylink-driver-${version} && sudo ./displaylink-installer.sh install
}

# uninstall
uninstall(){

echo -e "\nUninstalling ...\n"

sudo displaylink-installer uninstall

# double check if evdi module is loaded, if yes remove it
evdi_module="evdi"

if lsmod | grep "$evdi_module" &> /dev/null ; then
	echo "Removing $evdi_module module"
	sudo rmmod evdi
fi
}

echo -e "\nDisplayLink driver for Debian GNU/Linux\n"

read -p "[I]nstall
[U]ninstall

Select a key: [i/u]: " answer

if [[ $answer == [Ii] ]];
then
	distro_check
	install
	install_clean_up
	echo -e "\nInstall complete, please reboot to apply the changes\n"
elif [[ $answer == [Uu] ]];
then
	distro_check
	uninstall
	uninstall_clean_up
	echo -e "\nUninstall complete\n"
else
	echo -e "\nWrong key, aborting ...\n"
	exit 1
fi

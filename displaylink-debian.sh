#!/bin/bash
#
# DisplayLink driver installer for Debian GNU/Linux
#
# Copyleft: Adnan Hodzic <adnan@hodzic.org>
# License: GPLv3

driver_dir=1.0.138

# ToDo: add dependency check on:
# unzip linux-headers-$(uname -r) dkms lsb-release

distro_check(){

# RedHat
if [ -f /etc/redhat-release ];
then
	echo "This is a Redhat based distro ..."
	# ToDo:
	# Add platform type message for RedHat
	exit 1
else

# Checker parameters 
lsb="$(lsb_release -is)"
codename="$(lsb_release -cs)"
platform="$(lsb_release -ics | sed '$!s/$/ /' | tr -d '\n')"

# Unsupported platform message
message(){
echo -e "\n------------------------------------------------------\n"
echo -e "Unsuported platform: $platform"
echo -e ""
echo -e "This tool is Open Source and feel free to extend it"
echo -e "GitHub repo: https://goo.gl/6soXDE"
echo -e "------------------------------------------------------\n"
}

# Ubuntu
if [ $lsb == "Ubuntu" ];
then
		message
		exit 1
# Debian
elif [ $lsb == "Debian" ];
then
	if [ $codename == "jessie" ] || [ $codename == "stretch" ] || [ $codename == "sid" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
		#exit 1
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

install(){
echo -e "\nDownloading DisplayLink Ubuntu driver:"
wget http://downloads.displaylink.com/publicsoftware/DisplayLink-Ubuntu-1.0.138.zip

# prep
mkdir $driver_dir
echo -e "\nPrepring for install ...\n"
unzip -d $driver_dir DisplayLink-Ubuntu-1.0.138.zip
chmod +x $driver_dir/displaylink-driver-1.0.138.run
./$driver_dir/displaylink-driver-1.0.138.run --keep --noexec
mv displaylink-driver-1.0.138/ $driver_dir/displaylink-driver-1.0.138

# modify displaylink-installer.sh
sed -i "s/SYSTEMINITDAEMON=unknown/SYSTEMINITDAEMON=systemd/g" $driver_dir/displaylink-driver-1.0.138/displaylink-installer.sh
sed -i "s/"179"/"17e9"/g" $driver_dir/displaylink-driver-1.0.138/displaylink-installer.sh
sed -i "s/detect_distro/#detect_distro/g" $driver_dir/displaylink-driver-1.0.138/displaylink-installer.sh 
sed -i "s/#detect_distro()/detect_distro()/g" $driver_dir/displaylink-driver-1.0.138/displaylink-installer.sh 
sed -i "s/check_requirements/#check_requirements/g" $driver_dir/displaylink-driver-1.0.138/displaylink-installer.sh
sed -i "s/#check_requirements()/check_requirements()/g" $driver_dir/displaylink-driver-1.0.138/displaylink-installer.sh

# install
echo -e "\nInstalling ... \n"
cd $driver_dir/displaylink-driver-1.0.138 && sudo ./displaylink-installer.sh install

echo -e "\nInstall complete\n"
}

# uninstall
uninstall(){

# ToDo: add confirmation before uninstalling?
echo -e "\nUninstalling ...\n"

cd $driver_dir/displaylink-driver-1.0.138 && sudo ./displaylink-installer.sh uninstall
sudo rmmod evdi

# cleanup
# Todo: add confirmation before removing
cd -
rm -r $driver_dir
rm DisplayLink-Ubuntu-1.0.138.zip

echo -e "\nUninstall complete\n"
}

post(){
eval $(rm -r $driver_dir)
eval $(rm DisplayLink-Ubuntu-1.0.138.zip)
}

echo -e "\nDisplayLink driver for Debian GNU/Linux\n"

read -p "[I]nstall
[U]ninstall

Select a key: [i/u]: " answer

if [[ $answer == [Ii] ]];
then
	distro_check
	install
elif [[ $answer == [Uu] ]];
then
	uninstall
	#post
else
	echo -e "\nWrong key, aborting ...\n"
	exit 1
fi

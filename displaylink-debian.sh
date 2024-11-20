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

# URLs
synaptics_url="https://www.synaptics.com"
displaylink_driver_url="${synaptics_url}/products/displaylink-graphics/downloads/ubuntu"
platform_list_url='http://bit.ly/2zrwz2u'
repo_issue_url='http://bit.ly/2GLDlpY'
repo_url='https://github.com/AdnanHodzic/displaylink-debian'
post_install_guide_url="${repo_url}/blob/master/docs/post-install-guide.md"

# script description text used when rendering the script help menu or interactive script menu
script_description="
--------------------------- displaylink-debian -------------------------------

DisplayLink driver installer for Debian and Ubuntu based Linux distributions:

* Debian, Ubuntu, Elementary OS, Mint, Kali, Deepin and many more!
* Full list of all supported platforms: $platform_list_url
* When submitting a new issue, include Debug information
"

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"
resources_dir="$(pwd)/resources/"

# globalvars
lsb="$(lsb_release -is)"
codename="$(lsb_release -cs)"
platform="$(lsb_release -ics | sed '$!s/$/ /' | tr -d '\n')"
kernel_release="$(uname -r)"
xorg_config_displaylink='/etc/X11/xorg.conf.d/20-displaylink.conf'
blacklist='/etc/modprobe.d/blacklist.conf'
sys_driver_version="$(ls /usr/src/ | grep 'evdi' | cut -d '-' -f2)"
vga_info="$(lspci | grep -oP '(?<=VGA compatible controller: ).*')" || :
vga_info_3d="$(lspci | grep -i '3d controller' | sed 's/^.*: //')"
graphics_vendor="$(lspci -nnk | grep -i vga -A3 | grep 'in use' | cut -d ':' -f2 | sed 's/ //g')"
graphics_subcard="$(lspci -nnk | grep -i vga -A3 | grep Subsystem | cut -d ' ' -f5)"
providers="$(xrandr --listproviders)"
xorg_vcheck="$(dpkg -l | grep 'ii  xserver-xorg-core' | awk '{print $3}' | sed 's/[^,:]*://g')"
min_xorg=1.18.3
newgen_xorg=1.19.6
init_script='displaylink.sh'
evdi_modprobe='/etc/modules-load.d/evdi.conf'
kconfig_file="/lib/modules/${kernel_release}/build/Kconfig"
opt_displaylink_dir='/opt/displaylink'
etc_init_dir='/etc/init.d'

# Using modules-load.d should always be preferred to 'modprobe evdi' in start
# command

# creates a backup of a specified file
function backup_file() {
	local -r file_name="$1"

	if [ -z "$file_name" ]; then
		echo -e '\nFile must be specified for backup.  Skipping backup...'
		return 1
	fi

	if [ ! -f "$file_name" ]; then
		echo -e "\nFile does not exist: $file_name  Skipping backup..."
		return 1
	fi

	mv "$file_name" "${file_name}.org.bak"
	echo -e "\nMade backup of: $file_name file"
	echo -e "\nLocation: ${file_name}.org.bak"
}

# retrieves a DisplayLink driver version
function get_displaylink_driver_version() {
	local -r head_lines="$1"
	local -r perl_command="$2"

	wget -q -O - "$displaylink_driver_url" | grep '<p>Release: ' | head -n "$head_lines" | perl -pe "$perl_command"
}

# retrieves the latest DisplayLink driver version
function get_latest_displaylink_driver_version() {
    # Get latest displaylink driver versions
    local -r versions=$(get_displaylink_driver_version 2 '($_)=/([0-9]+([.][0-9]+)+(\ Beta)*)/; exit if $. > 1;')

    local head_lines=1
    local perl_command='($_)=/([0-9]+([.][0-9]+)+)/; exit if $. > 1;'

    # if versions contains "Beta", set parameters to try and download previous version
    if [[ "$versions" =~ 'Beta' ]]; then
        head_lines=2
        perl_command='($_)=/([0-9]+([.][0-9]+)+(?!\ Beta))/; exit if $. > 1;'
    fi

	# return the latest driver version
    get_displaylink_driver_version "$head_lines" "$perl_command"
}

# writes a text separator line to the terminal
function separator() {
	echo -e '\n-------------------------------------------------------------------'
}

# invalid option error message
function invalid_option() {
	separator
	echo -e '\nInvalid option specified.'
	separator
	read -rsn1 -p 'Enter any key to continue'
	echo ''

	# exit the script when an invalid
	# option is specified by the user
	exit 1
}

# checks if the script is executed by root user
function root_check() {
	# perform root check and exit function early,
	# if the script is executed by root user
	[ $EUID -eq 0 ] && return

	separator
	echo -e "\nScript must be executed as root user (i.e: 'sudo $0')."
	separator
	exit 1
}

# list all xorg related configs
function get_xconfig_list() {
	local -r x11_etc='/etc/X11/'

	# No directory found
	if [ ! -d "$x11_etc" ]; then
		echo 'X11 configs: None'
		return 0
	fi

	if [ "$(find "$x11_etc" -maxdepth 2 -name "*.conf" | wc -l)" -gt 0 ]; then
		find "$x11_etc" -type f -name "*.conf" | xargs echo 'X11 configs:'
	fi
}

# checks if script dependencies are installed
# automatically installs missing script dependencies
function dependencies_check() {
	echo -e '\nChecking dependencies...\n'

	local -r dpkg_arch="$(dpkg --print-architecture)"

	# script dependencies
	local -r dependencies=(
		'unzip'
		"linux-headers-${kernel_release}"
		'dkms'
		'lsb-release'
		'linux-source'
		'x11-xserver-utils'
		'wget'
		"libdrm-dev:${dpkg_arch}"
		"libelf-dev:${dpkg_arch}"
		'git'
		'pciutils'
		'build-essential'
	)

	for dependency in "${dependencies[@]}"; do
		# skip dependency installation if dependency is already present
		if dpkg -s "$dependency" | grep -q 'Status: install ok installed'; then
			continue
		fi

		echo "installing dependency: $dependency"

		# attempt to install missing dependency
		if ! apt-get install -q=2 -y "$dependency"; then
			echo "$dependency installation failed.  Aborting."
			exit 1
		fi
	done
}

# checks if the script is running on a supported
function distro_check() {
	separator
	# check for Red Hat based distro
	if [ -f /etc/redhat-release ]; then
		echo -e '\nRed Hat based linux distributions are not supported.'
		separator
		exit 1
	fi

	# confirm dependencies are in place
	dependencies_check

	# supported Debian based linux distributions
	local -r supported_distributions=(
		'BunsenLabs'
		'Bunsenlabs'
		'Debian'
		'Deepin'
		'Devuan'
		'elementary OS'
		'Kali'
		'MX'
		'Neon'
		'Nitrux'
		'Parrot'
		'Pop'
		'PureOS'
		'Ubuntu'
		'Uos' # Deepin alternative LSB string
		'Zorin'
	)

	if [[ "${supported_distributions[*]/$lsb/}" != "${supported_distributions[*]}" ]] || [[ "$lsb" =~ (elementary|Linuxmint) ]]; then
		echo -e '\nPlatform requirements satisfied, proceeding ...'
	else
		cat <<_UNSUPPORTED_PLATFORM_MESSAGE_

---------------------------------------------------------------

Unsuported platform: $platform
Full list of all supported platforms: $platform_list_url
This tool is Open Source and feel free to extend it
GitHub repo: $repo_url

---------------------------------------------------------------

_UNSUPPORTED_PLATFORM_MESSAGE_
		exit 1
	fi
}

# checks if the Kconfig file exists
function pre_install() {
	if [ -f "$kconfig_file" ]; then
		kconfig_exists=true
	else
		kconfig_exists=false
		touch "$kconfig_file"
	fi
}

# retrieves the init system name
function get_init_system() {
	local init_system=''

	case "$lsb" in
		'Devuan')
			init_system='sysvinit'
			;;

		'elementary OS')
			[ "$codename" == 'freya' ] && init_system='upstart'
			;;

		'Ubuntu')
			[ "$codename" == 'trusty' ] && init_system='upstart'
			;;
	esac

	if [ -z "$init_system" ] && [[ "$lsb" =~ elementary ]] && [ "$codename" == 'freya' ]; then
		init_system='upstart'
	fi

	# if init system not detected, then fallback to systemd
	[ -z "$init_system" ] && init_system='systemd'

	echo "$init_system"
}

# checks if the Displaylink service is running
function displaylink_service_check () {
	case "$(get_init_system)" in
		'systemd')
			systemctl is-active --quiet displaylink-driver.service && echo 'up and running'
			;;

		'sysvinit')
			"${etc_init_dir}/${init_script}" status
			;;
	esac
}

# performs post-installation clean-up by removing obsolete/redundant files which can only hamper reinstalls
function clean_up() {
	local -r version="$1"
	local -r driver_dir="$2"

	separator
	echo -e '\nPerforming clean-up'

	local -r zip_file="DisplayLink_Ubuntu_${version}.zip"

	# go back to displaylink-debian
	cd - &> /dev/null

	local -r clean_up_targets=(
		"$zip_file"
		"$driver_dir"
	)

	for clean_up_target in "${clean_up_targets[@]}"; do
		# skip if file or directory does not exist
		[ ! -e "$clean_up_target" ] && continue

		echo "Removing: '$clean_up_target' ..."

		if ! rm -r "$clean_up_target"; then
			echo -e "\nUnable to remove: $clean_up_target"
		fi
	done
}

# called when the driver setup is complete
function setup_complete() {
	local -r default='Y'
	local reboot_choice="$default"

	read -p 'Reboot now? [Y/n] ' reboot_choice
	reboot_choice="${reboot_choice:-$default}"

	case "$reboot_choice" in
		[yY])
			echo 'Rebooting ...'
			reboot
			;;

		[nN])
			echo -e '\nReboot postponed, changes will not be applied until reboot.'
			;;

		*)
			invalid_option
			;;
	esac
}

# downloads the DisplayLink driver
function download() {
	local -r version="$1"

	local -r default='y'
	local accept_license_agreement="$default"

	local -r download_url="${synaptics_url}/$(wget -q -O - "$displaylink_driver_url" | grep -B 2 "${version}-Release" | perl -pe '($_)=/<a href="\/([^"]+)"[^>]+class="download-link"/')"
	local -r driver_url="${synaptics_url}/$(wget -q -O - "$download_url" | grep '<a class="no-link"' | head -n 1 | perl -pe '($_)=/href="\/([^"]+)"/')"

	echo -en "\nPlease read the Software License Agreement available at: \n${download_url}\nDo you accept?: [Y/n]: "
	read accept_license_agreement
	accept_license_agreement=${accept_license_agreement:-$default}

	# exit the script if the user did not accept the software license agreement
	if [[ ! "$accept_license_agreement" =~ ^[yY]$ ]]; then
		echo 'Cannot download the driver without accepting the license agreement!'
		exit 1
	fi

	echo -e '\nDownloading DisplayLink Ubuntu driver:\n'

	# make sure file is downloaded before continuing
	if ! wget -O "DisplayLink_Ubuntu_${version}.zip" "${driver_url}"; then
		echo -e '\nUnable to download Displaylink driver\n'
		exit 1
	fi
}

# add udlfb to blacklist (issue #207)
function udl_block() {
	# if necessary create blacklist.conf
	[ ! -f "$blacklist" ] && touch "$blacklist"

	local -r blacklist_items=(
		'udlfb'
		'udl' # add udl to blacklist (issue #207)
	)

	for blacklist_item in "${blacklist_items[@]}"; do
		# skip if item already blacklisted
		if grep -Fxq "blacklist $blacklist_item" "$blacklist"; then
			continue
		fi

		# add item to blacklist
		echo "Adding $blacklist_item to blacklist"
		echo "blacklist $blacklist_item" >> "$blacklist"
	done
}

# returns the integer representation of the specified version string
function ver2int {
	echo "$@" | awk -F "." '{ printf("%03d%03d%03d\n", $1,$2,$3); }'
}

# installs the displaylink driver
function install() {
	local -r version="$1"
	local -r driver_dir="$2"

	separator
	download "$version"

	local -r displaylink_driver_dir="${driver_dir}/displaylink-driver-${version}"
    local -r installer_script="${displaylink_driver_dir}/displaylink-installer.sh"
	local -r build_dir="$(dirname "$kconfig_file")"

	# udlfb kernel version check
	local -r kernel_version="$(echo "$kernel_release" | grep -Eo '[0-9]+\.[0-9]+')"

	# get init system
	local -r init_system="$(get_init_system)"

	# prepare for installation
	# check if prior drivers have been downloaded
	if [ -d "$driver_dir" ]; then
		echo "Removing prior: '$driver_dir' directory"
		rm -r "$driver_dir"
	fi

	mkdir -p "$driver_dir"

	separator
	echo -e '\nPreparing for install\n'
	test -d "$driver_dir" && /bin/rm -Rf "$driver_dir"
	unzip -d "$driver_dir" "DisplayLink_Ubuntu_${version}.zip"
	chmod +x $driver_dir/displaylink-driver-${version}*.run
	$driver_dir/displaylink-driver-${version}*.run --keep --noexec
	mv displaylink-driver-${version}*/ "$displaylink_driver_dir"

	# modify displaylink-installer.sh
	sed -i "s/SYSTEMINITDAEMON=unknown/SYSTEMINITDAEMON=$init_system/g" "$installer_script"

	# issue: 227
	local -r distros=(
		'BunsenLabs'
		'Bunsenlabs'
		'Debian'
		'Deepin'
		'Devuan'
		'Kali'
		'MX'
		'Uos'
	)

	if [[ "${distros[*]/$lsb/}" != "${distros[*]}" ]]; then
		sed -i 's#/lib/modules/$KVER/build/Kconfig#/lib/modules/$KVER/build/scripts/kconfig/conf#g' "$installer_script"
		ln -sf "${build_dir}/Makefile" "${build_dir}/Kconfig"
	fi

	# patch displaylink-installer.sh to prevent reboot before the script is done
	patch -Np0 "$installer_script" < "${resources_dir}displaylink-installer.patch"

	# run displaylink install
	echo -e "\nInstalling driver version: $version\n"
	cd "$displaylink_driver_dir"
	./displaylink-installer.sh install

	# add udl/udlfb to blacklist depending on kernel version (issue #207)
	[ "$(ver2int "$kernel_version")" -ge "$(ver2int '4.14.9')" ] && udl_block
}

# issue: 204, 216
function nvidia_hashcat() {
	echo "Installing hashcat-nvidia, 'contrib non-free' must be enabled in apt sources"
	apt-get install -y hashcat-nvidia
}

# appends nvidia xrandr specific script code (partial)
function nvidia_xrandr_partial() {
	cat >> "$1" <<_NVIDIA_XRANDR_SCRIPT_

xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
_NVIDIA_XRANDR_SCRIPT_
}

# writes nvidia xrandr specific script code (full)
function nvidia_xrandr_full() {
	cat > "$1" <<_NVIDIA_XRANDR_FULL_SCRIPT_
#!/bin/sh
# Xsetup - run as root before the login dialog appears

if [ -e /sbin/prime-offload ]; then
    echo 'running NVIDIA Prime setup /sbin/prime-offload'
    /sbin/prime-offload
fi
_NVIDIA_XRANDR_FULL_SCRIPT_

	nvidia_xrandr_partial "$1"
}

# performs nvidia specific pre-setup operations
function nvidia_pregame() {
	local -r xsetup_loc='/usr/share/sddm/scripts/Xsetup'

	# xorg.conf ops
	local -r xorg_config='/etc/x11/xorg.conf'
	local -r usr_xorg_config_displaylink='/usr/share/X11/xorg.conf.d/20-displaylink.conf'

	# create Xsetup file if not there + make necessary changes (issue: #201, #206)
	if [ ! -f "$xsetup_loc" ]; then
		echo "$xsetup_loc not found, creating"
		mkdir -p /usr/share/sddm/scripts/
		touch "$xsetup_loc"
		nvidia_xrandr_full "$xsetup_loc"
		chmod +x "$xsetup_loc"
		echo -e "Wrote changes to $xsetup_loc"
	fi

	# make necessary changes to Xsetup
	if ! grep -q 'setprovideroutputsource modesetting' "$xsetup_loc"; then
		backup_file "$xsetup_loc"
		nvidia_xrandr_partial "$xsetup_loc"
		chmod +x "$xsetup_loc"
		echo -e "Wrote changes to $xsetup_loc"
	fi

	# config files to backup
	local -r configs=(
		"$xorg_config"
		"$xorg_config_displaylink"
		"$usr_xorg_config_displaylink"
	)

	for config_file in "${configs[@]}"; do
		# skip if config file does not exist
		[ ! -f "$config_file" ] && continue

		# backup config file
		backup_file "$config_file"
	done
}

# amd displaylink xorg.conf
function xorg_amd() {
	cat > "$xorg_config_displaylink" <<_XORG_AMD_CONFIG_
Section "Device"
	Identifier "AMDGPU"
	Driver     "amdgpu"
	Option     "PageFlip" "false"
EndSection
_XORG_AMD_CONFIG_
}

# intel displaylink xorg.conf
function xorg_intel() {
	cat > "$xorg_config_displaylink" <<_XORG_INTEL_CONFIG_
Section "Device"
	Identifier  "Intel"
	Driver      "intel"
EndSection
_XORG_INTEL_CONFIG_
}

# modesetting displaylink xorg.conf
function xorg_modesetting() {
	cat > "$xorg_config_displaylink" <<_XORG_MODESETTING_CONFIG_
Section "Device"
	Identifier  "DisplayLink"
	Driver      "modesetting"
	Option      "PageFlip" "false"
EndSection
_XORG_MODESETTING_CONFIG_
}

# modesetting displaylink xorg.conf
function xorg_modesetting_newgen() {
	cat > "$xorg_config_displaylink" <<_XORG_EVDI_CONFIG_
Section "OutputClass"
	Identifier  "DisplayLink"
	MatchDriver "evdi"
	Driver      "modesetting"
	Option      "AccelMethod" "none"
EndSection
_XORG_EVDI_CONFIG_
}

# nvidia displaylink xorg.conf (issue: 176)
function xorg_nvidia() {
	cat > "$xorg_config_displaylink" <<_XORG_NVIDIA_CONFIG_
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
_XORG_NVIDIA_CONFIG_
}

# setup xorg.conf depending on graphics card
function modesetting() {
	test ! -d /etc/X11/xorg.conf.d && mkdir -p /etc/X11/xorg.conf.d

	local -r driver=$(lspci -nnk | grep -i vga -A3 | grep 'in use' | cut -d':' -f2 | sed 's/ //g')
	local -r driver_nvidia=$(lspci | grep -i '3d controller' | sed 's/^.*: //' | awk '{print $1}')
	local -r card_subsystem=$(lspci -nnk | grep -i vga -A3 | grep Subsystem | cut -d' ' -f5)

	# set xorg for Nvidia cards (issue: 176, 179, 211, 217, 596)
	if [ "$driver_nvidia" == 'NVIDIA' ] || [[ $driver == *"nvidia"* ]]; then
		nvidia_pregame
		xorg_nvidia
		#nvidia_hashcat
	# set xorg for AMD cards (issue: 180)
	elif [ "$driver" == 'amdgpu' ]; then
		xorg_amd
	# set xorg for Intel cards
	elif [ "$driver" == 'i915' ]; then
		# set xorg modesetting for Intel cards (issue: 179, 68, 88, 192)
		local -r supported_subsystems=(
			'530'
			'540'
			'620'
			'GT2'
			'HD'
			'UHD'
			'v2/3rd'
		)

		if [ "${supported_subsystems[*]/$card_subsystem/}" != "${supported_subsystems[*]}" ]; then
			if [ "$(ver2int "$xorg_vcheck")" -gt "$(ver2int "$newgen_xorg")" ]; then
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
		if [ "$(ver2int "$xorg_vcheck")" -gt "$(ver2int "$newgen_xorg")" ]; then
			# reference: issue #200
			xorg_modesetting_newgen
		else
			xorg_modesetting
		fi
	fi

	echo -e "Wrote X11 changes to: $xorg_config_displaylink"
	chown root: "$xorg_config_displaylink"
	chmod 644 "$xorg_config_displaylink"
}

# performs post-installation steps
function post_install() {
	separator
	echo -e '\nPerforming post-install steps\n'

	# remove Kconfig file if it does not exist?
	[ "$kconfig_exists" = false ] && rm "$kconfig_file"

	# fix: issue #42 (dlm.service can't start)
	# note: for this to work libstdc++6 package needs to be installed from >= Stretch
	if [[ "$lsb" =~ ^(Debian|Devuan|Kali)$ ]]; then
		# partially addresses meta issue #931
		[ ! -d "$opt_displaylink_dir" ] && mkdir -p "$opt_displaylink_dir"

		ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6 "${opt_displaylink_dir}/libstdc++.so.6"
	fi

	case "$(get_init_system)" in
		'systemd')
			# partially addresses meta issue #931
			local -r displaylink_driver_service='/lib/systemd/system/displaylink-driver.service'
            if [ ! -f "$displaylink_driver_service" ]; then
                echo -e 'DisplayLink driver service not found!\nInstallation failed!\nExiting...'
                exit 1
            fi

			# Fix inability to enable displaylink-driver.service
			sed -i '/RestartSec=5/a[Install]\nWantedBy=multi-user.target' "$displaylink_driver_service"

			echo 'Enabling displaylink-driver service ...'
			systemctl enable displaylink-driver.service
			;;

		'sysvinit')
			local -r init_script_path="${etc_init_dir}/${init_script}"

			echo -e "Copying init script to ${etc_init_dir}\n"
			cp "${dir}/${init_script}" "${etc_init_dir}/"
			chmod +x "$init_script_path"

			echo 'Load evdi at startup'
			cat > "$evdi_modprobe" <<_EVDI_MODPROBE_
evdi
_EVDI_MODPROBE_
			echo 'Enabling displaylink service ...'
			update-rc.d "$init_script" defaults

			echo 'Starting displaylink service ...'
			"$init_script_path" start
			;;
	esac

	# depending on X11 version start modesetting func
	if [ "$(ver2int "$xorg_vcheck")" -gt "$(ver2int "$min_xorg")" ]; then
		echo 'Setup DisplayLink xorg.conf depending on graphics card'
		modesetting
	else
		echo 'No need to disable PageFlip for modesetting'
	fi
}

# uninstalls the displaylink driver
function uninstall() {
	separator
	echo -e '\nUninstalling ...\n'

	# displaylink-installer uninstall

	local -r distros=(
		'BunsenLabs'
		'Bunsenlabs'
		'Debian'
		'Devuan'
		'Deepin'
		'Kali'
		'Uos'
	)

	if [ -f "$kconfig_file" ] && [[ "${distros[*]/$lsb/}" != "${distros[*]}" ]]; then
		rm "$kconfig_file"
	fi

	if [ "$(get_init_system)" == 'sysvinit' ]; then
		update-rc.d "$init_script" remove
		rm -f "${etc_init_dir}/${init_script}"
		rm -f "$evdi_modprobe"
	fi

	# run unintsall script
	bash /opt/displaylink/displaylink-installer.sh uninstall && 2>&1>/dev/null

	# remove modesetting file
	if [ -f "$xorg_config_displaylink" ]; then
		echo 'Removing Displaylink Xorg config file ...'
		rm "$xorg_config_displaylink"
	fi

	# delete udl/udlfb from blacklist (issue #207)
	sed -i '/blacklist udlfb/d' "$blacklist"
	sed -i '/blacklist udl/d' "$blacklist"
}

# debug: get system information for issue debug
function debug() {
	separator
	echo -e '\nStarting Debug ...\n'

	local -r default='N'
	local answer="$default"

	local -r evdi_version_file='/sys/devices/evdi/version'

	local -A subject_urls=(
		['Post Installation Guide']="$post_install_guide_url"
		['Troubleshooting most common issues']="${repo_url}/blob/master/docs/common-issues.md"
	)

	# array contains subject types in their original order
	local -r subjects=(
		'Post Installation Guide'
		'Troubleshooting most common issues'
	)

	local url=''

	for subject in "${subjects[@]}"; do
		url="${subject_urls[$subject]}"

		read -p "Did you read ${subject}? ${url} [y/N] " answer
		answer="${answer:-$default}"

		case "$answer" in
			[yY])
				echo ''
				continue
				;;

			[nN])
				echo -e "\nPlease read ${subject}: ${url}\n"
				exit 1
				;;

			*)
				invalid_option
				;;
		esac
	done

	local -r evdi_version="$(
		[ -f "$evdi_version_file" ] && \
			cat "$evdi_version_file" || \
			echo "$evdi_version_file not found"
	)"

    # render debug info
    cat <<_DEBUG_INFO_
--------------- Linux system info ----------------

Distro:  $lsb
Release: $codename
Kernel:  $kernel_release

---------------- DisplayLink info ----------------

Driver version:             $sys_driver_version
DisplayLink service status: $(displaylink_service_check || echo '[SERVICE NOT FOUND]')
EVDI service version:       $evdi_version

------------------ Graphics card -----------------

Vendor:      $graphics_vendor
Subsystem:   $graphics_subcard
VGA:         $vga_info
VGA (3D):    ${vga_info_3d:-N/A}
X11 version: $xorg_vcheck

_DEBUG_INFO_

	# render xorg config file paths
    get_xconfig_list

    # render more debug info
    cat <<_DEBUG_INFO_
-------------- DisplayLink xorg.conf -------------

File:     $xorg_config_displaylink
Contents: $(
	[ -f "$xorg_config_displaylink" ] && \
		echo -e "\n$(cat "$xorg_config_displaylink")" || \
		echo '[CONFIG FILE NOT FOUND]'
)

-------------------- Monitors --------------------

$providers
_DEBUG_INFO_
}

# Prints the help menu to the terminal.
function show_help_menu() {
	local -r omit_script_description="$1"

	if [ -z "$omit_script_description" ] || [ "$omit_script_description" = false ]; then
		echo "$script_description"
	else
		separator
		echo -e '\nViewing help menu...'
		separator
	fi

    cat <<_HELP_TEXT_
NOTES:
    - This script must be executed by the root user.
    - All options are optional.
    - If no options are specfied, then an options menu will be presented.

USAGE:
    sudo $0 [OPTIONS]

OPTIONS:
    -d,  --debug
        Prints debug information to the terminal.

    -h,  --help
        Prints this help menu.

    -u,  --install
        Installs the DisplayLink driver.

    -r,  --reinstall
        Re-installs the DisplayLink driver.

    -u,  --uninstall
        Uninstalls the DisplayLink driver.

_HELP_TEXT_
}

# script entry-point
function main() {
	local interactive_menu=false
	local script_option=''

    # render interactive menu if no script parameter is specified
	if [[ "$#" -lt 1 ]]; then
		interactive_menu=true

		cat <<_INTERACTIVE_MENU_HEADER_
$script_description
Options:
_INTERACTIVE_MENU_HEADER_

        read -p "
[I]nstall
[D]ebug
[H]elp
[R]e-install
[U]ninstall
[Q]uit

Select a key: [i/d/h/r/u/q]: " script_option

	# parse script parameters
	else
		case "${1}" in
			'-d'|'--debug')
				script_option='d'
				;;

			'-h'|'--help')
				script_option='h'
				;;

			'-i'|'--install')
				script_option='i'
				;;

			'-r'|'--reinstall')
				script_option='r'
				;;

			'-u'|'--uninstall')
				script_option='u'
				;;
			*)
				script_option='n'
				;;
		esac
	fi

	# exit early if the user decided to quit the script
	[[ "$script_option" =~ ^[qQ]$ ]] && echo -e '\nExiting...\n' && exit 0

    # check if script is executed by root user (skip check for help menu)
	[[ ! "$script_option" =~ ^[hH]$ ]] && root_check

	# run distro check for debug, install, reinstall, and uninstall options
	[[ "$script_option" =~ ^[dDiIrRuU]$ ]] && distro_check

	local driver_dir=''
	local version=''

	# get the latest DisplayLink driver version for installs, reinstalls, and uninstalls only
	if [[ "$script_option" =~ ^[iIrRuU]$ ]]; then
		version="$(get_latest_displaylink_driver_version)"
		driver_dir="$(realpath "./${version}")"
	fi

	local -r installation_completed_message="

Installation completed, please reboot to apply the changes.
After reboot, make sure to consult post-install guide! $post_install_guide_url"

	case "$script_option" in
        # Debug
        # > Prints debug information (system info, driver info, etc) to the terminal.
		[dD])
			debug
			separator
			echo -e "\nUse this information when submitting an issue ($repo_issue_url)"
			separator
			echo ''
			;;

        # Help
        # > Prints the script help menu to the terminal.
        [hH])
            show_help_menu "$interactive_menu"
            exit 0
            ;;

        # Install
        # > Installs the DisplayLink driver.
        [iI])
			pre_install
			install "$version" "$driver_dir"
			post_install
			clean_up "$version" "$driver_dir"
			separator
			echo "$installation_completed_message"
			setup_complete
			separator
			echo ''
			;;

        # Re-Install
        # > Re-installs the DisplayLink driver.
        [rR])
			uninstall
			clean_up "$version" "$driver_dir"
			pre_install
			install "$version" "$driver_dir"
			post_install
			clean_up "$version" "$driver_dir"
			separator
			echo "$installation_completed_message"
			setup_complete
			separator
			echo ''
			;;

        # Uninstall
        # > Uninstalls the DisplayLink driver.
        [uU])
			uninstall
			clean_up "$version" "$driver_dir"
			separator
			echo -e '\nUninstall complete, please reboot to apply the changes.'
			setup_complete
			separator
			echo ''
			;;

        # Unknown option
        *)
            echo -e '\nUnknown option selected.  Exiting...'
            echo ''
            exit 1
            ;;
	esac
}

# run script entry-point
main "$@"


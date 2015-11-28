#!/bin/bash
# Copyright (c) 2015 DisplayLink (UK) Ltd.
#
# This script has been modified to work with 
# with Debian Stretch on Linux kernel 4.2.*
#
# Copyleft: Adnan Hodzic <adnan@hodzic.org>
# License: GPLv3

SELF=$0
COREDIR=/usr/lib/displaylink
LOGSDIR=/var/log/displaylink
PRODUCT="DisplayLink Linux Software"
VERSION=1.0.138
ACTION=default
SYSTEMINITDAEMON=systemd

add_udev_rule()
{
  echo 'ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="17e9", ATTR{bNumInterfaces}=="*5", GROUP="plugdev", MODE="0660"' > /etc/udev/rules.d/99-displaylink.rules
  chmod 0644 /etc/udev/rules.d/99-displaylink.rules
}

remove_udev_rule()
{
  rm -f /etc/udev/rules.d/99-displaylink.rules
}

install_module()
{
  TARGZ="$1"
  MODVER="$2"
  ERRORS="$3"

  SRCDIR="/usr/src/evdi-$MODVER"
  mkdir -p "$SRCDIR"
  if ! tar xf $TARGZ -C "$SRCDIR"; then
    echo "Unable to extract $TARGZ" to "$SRCDIR" > $ERRORS
    return 1
  fi

  echo "Registering EVDI kernel module with DKMS"
  dkms add evdi/$MODVER -q
  if [ $? != 0 -a $? != 3 ]; then
    echo "Unable to add evdi/$MODVER to DKMS source tree." > $ERRORS
    return 2
  fi

  echo "Building EVDI kernel module with DKMS"
  dkms build evdi/$MODVER -q
  if [ $? != 0 ]; then
    echo "Failed to build evdi/$MODVER. Consult /var/lib/dkms/evdi/$MODVER/build/make.log for details." > $ERRORS
    return 3
  fi

  echo "Installing EVDI kernel module to kernel tree"
  dkms install evdi/$MODVER -q
  if [ $? != 0 ]; then
    echo "Failed to install evdi/$MODVER to the kernel tree." > $ERRORS
    return 4
  fi

  echo "EVDI kernel module built successfully"
}

remove_module()
{
  MODVER="$1"
  SRCDIR="/usr/src/evdi-$MODVER"
  dkms remove evdi/$MODVER --all -q
  [ -d "$SRCDIR" ] && rm -rf "$SRCDIR"
}

is_64_bit()
{
  [ "$(getconf LONG_BIT)" == "64" ]
}

add_upstart_script()
{
  cat > /etc/init/displaylink.conf <<'EOF'
description "DisplayLink Manager Service"
# Copyright (c) 2015 DisplayLink (UK) Ltd.

start on login-session-start
stop on desktop-shutdown

# Restart if process crashes
respawn

# Only attempt to respawn 10 times in 5 seconds
respawn limit 10 5

chdir /usr/lib/displaylink

script
    [ -r /etc/default/displaylink ] && . /etc/default/displaylink
    modprobe evdi
    exec /usr/lib/displaylink/DisplayLinkManager
end script
EOF

  chmod 0644 /etc/init/displaylink.conf
}

add_systemd_service()
{
  cat > /lib/systemd/system/displaylink.service <<'EOF'
[Unit]
Description=DisplayLink Manager Service
After=display-manager.service
Conflicts=getty@tty7.service

[Service]
ExecStartPre=/sbin/modprobe evdi
ExecStart=/usr/lib/displaylink/DisplayLinkManager
Restart=always
WorkingDirectory=/usr/lib/displaylink
RestartSec=5

[Install]
WantedBy=graphical.target

EOF

  chmod 0644 /lib/systemd/system/displaylink.service
  systemctl enable displaylink.service
}

remove_upstart_script()
{
  rm -f /etc/init/displaylink.conf
}

remove_systemd_service()
{
  systemctl disable displaylink.service
  rm -f /lib/systemd/system/displaylink.service
}

add_pm_script()
{
  cat > $COREDIR/displaylink.sh <<EOF
#!/bin/bash
# Copyright (c) 2015 DisplayLink (UK) Ltd.

suspend_dlm()
{
  #flush any bytes in pipe
  while read -n 1 -t 1 SUSPEND_RESULT < $COREDIR/PmMessagesPort_out; do : ; done;

  #suspend DisplayLinkManager
  echo "S" > $COREDIR/PmMessagesPort_in

  #wait until suspend of DisplayLinkManager finish
  read -n 1 -t 10 SUSPEND_RESULT < $COREDIR/PmMessagesPort_out
}

resume_dlm()
{
  #resume DisplayLinkManager
  echo "R" > $COREDIR/PmMessagesPort_in
}

EOF

  if [ "$1" = "upstart" ]
  then
    cat >> $COREDIR/displaylink.sh <<EOF
case "\$1" in
  thaw)
    resume_dlm
    ;;
  hibernate)
    suspend_dlm
    ;;
  suspend)
    suspend_dlm
    ;;
  resume)
    resume_dlm
    ;;
esac

EOF
  elif [ "$1" = "systemd" ]
  then
    cat >> $COREDIR/displaylink.sh <<EOF
case "\$1/\$2" in
  pre/*)
    suspend_dlm
    ;;
  post/*)
    resume_dlm
    ;;
esac

EOF
  fi

  chmod 0755 $COREDIR/displaylink.sh
  if [ "$1" = "upstart" ]
  then
    ln -s $COREDIR/displaylink.sh /etc/pm/sleep.d/displaylink.sh
  elif [ "$1" = "systemd" ]
  then
    ln -s $COREDIR/displaylink.sh /lib/systemd/system-sleep/displaylink.sh
  fi
}

remove_pm_scripts()
{
  rm -f /etc/pm/sleep.d/displaylink.sh
  rm -f /lib/systemd/system-sleep/displaylink.sh
}

cleanup()
{
  rm -rf $COREDIR
  rm -rf $LOGSDIR
  rm -f /usr/bin/displaylink-installer
}

install()
{
  echo "Installing"
  mkdir -p $COREDIR
  mkdir -p $LOGSDIR
  chmod 0755 $COREDIR
  chmod 0755 $LOGSDIR

  cp -f $SELF $COREDIR
  ln -sf "$COREDIR/$(basename $SELF)" /usr/bin/displaylink-installer

  local ERRORS=$(mktemp)
  echo "Configuring EVDI DKMS module"
  install_module "evdi-$VERSION-src.tar.gz" "$VERSION" "$ERRORS"
  local success=$?

  local error="$(< $ERRORS)"
  rm -f $ERRORS
  if [ 0 -ne $success ]; then
    echo "ERROR (code $success): $error." >&2
    cleanup
    exit 1
  fi

  is_64_bit && ARCH="x64" || ARCH="x86"
  local DLM="$ARCH/DisplayLinkManager"
  echo "Installing $DLM"
  [ -x $DLM ] && mv -f $DLM $COREDIR

  echo "Installing libraries"
  local LIBEVDI="$ARCH/libevdi.so"
  local LIBUSB="$ARCH/libusb-1.0.so.0.1.0"

  [ -f $LIBEVDI ] && mv -f $LIBEVDI $COREDIR
  [ -f $LIBUSB ] && mv -f $LIBUSB $COREDIR
  ln -sf $COREDIR/libusb-1.0.so.0.1.0 $COREDIR/libusb-1.0.so.0
  ln -sf $COREDIR/libusb-1.0.so.0.1.0 $COREDIR/libusb-1.0.so

  chmod 0755 $COREDIR/DisplayLinkManager
  chmod 0755 $COREDIR/libevdi.so
  chmod 0755 $COREDIR/libusb*.so*

  echo "Installing firmware packages"
  mv -f *.spkg $COREDIR
  chmod 0644 $COREDIR/*.spkg

  echo "Installing license file"
  mv -f LICENSE $COREDIR
  chmod 0644 $COREDIR/LICENSE

  echo "Adding udev rule for DisplayLink DL-3xxx/5xxx devices"
  add_udev_rule

  if [ "upstart" == "$SYSTEMINITDAEMON" ]; then
    echo "Starting DLM upstart job"
    add_upstart_script
    add_pm_script "upstart"
    start displaylink
  elif [ "systemd" == "$SYSTEMINITDAEMON" ]; then
    echo "Starting DLM systemd service"
    add_systemd_service
    add_pm_script "systemd"
    systemctl start displaylink.service
  fi
}

uninstall()
{
  echo "Uninstalling"

  echo "Removing EVDI from kernel tree, DKMS, and removing sources."
  remove_module $VERSION

  if [ "upstart" == "$SYSTEMINITDAEMON" ]; then
    echo "Stopping DLM upstart job"
    stop displaylink
    remove_upstart_script
  elif [ "systemd" == "$SYSTEMINITDAEMON" ]; then
    echo "Stopping DLM systemd service"
    systemctl stop displaylink.service
    remove_systemd_service
  fi

  echo "Removing suspend-resume hooks"
  remove_pm_scripts

  echo "Removing udev rule"
  remove_udev_rule

  echo "Removing Core folder"
  cleanup

  echo -e "\nUninstallation steps complete."
  if [ -f /sys/devices/evdi/version ]; then
    echo "Please note that the evdi kernel module is still in the memory."
    echo "A reboot is required to fully complete the uninstallation process."
  fi
}

missing_requirement()
{
  echo "Unsatisfied dependencies. Missing component: $1." >&2
  echo "This is a fatal error, cannot install $PRODUCT." >&2
  exit 1
}

version_lt()
{
  local left=$(echo $1 | cut -d. -f-2)
  local right=$(echo $2 | cut -d. -f-2)
  local greater=$(echo -e "$left\n$right" | sort -Vr | head -1)
  [ "$greater" != "$left" ] && return $true
  return $false
}

check_requirements()
{
  # DKMS
#  which dkms >/dev/null || missing_requirement "DKMS"

  # Required kernel version
#  MIN_KVER="3.14"
#  MAX_KVER="3.19"
#  KVER=$(uname -r)

#  version_lt $KVER $MIN_KVER &&
#    missing_requirement "Kernel version $KVER is too old. At least $MIN_KVER is required"
#  version_lt $MAX_KVER $KVER &&
#     echo "WARNING: Kernel version $KVER is not supported. Highest supported version is $MAX_KVER."

  # Linux headers
#  [ ! -f "/lib/modules/$KVER/build/Kbuild" ] && missing_requirement "Linux headers for running kernel, $KVER"

    # DKMS
    which dkms >/dev/null || missing_requirement "DKMS"

    # Required kernel version
    KVER=$(uname -r)
    [ $(echo $KVER | cut -d. -f1) != 4 ] && missing_requirement "Kernel version $KVER is too old. At least 3.14 is required"
    [ $(echo $KVER | cut -d. -f2) -lt 2 ] && missing_requirement "Kernel version $KVER is too old. At least 3.14 is required"

    # Linux headers
    #[ ! -f "/lib/modules/$KVER/build/Kbuild" ] && missing_requirement "Linux headers for running kernel, $KVER"
    local LH=$(dpkg -l | grep linux-headers-$(uname -r))

    if [[ $LH != ii* ]]; then
	missing_requirement "Linux headers for running kernel, $KVER"
    else
	echo "Linux Headers found : linux-headers-$(uname -r))"
    fi
}

usage()
{
  echo
  echo "Installs $PRODUCT, version $VERSION."
  echo "Usage: $SELF [ install | uninstall ]"
  echo
  echo "If no argument is given, a quick compatibility check is performed but nothing is installed."
  exit 1
}

detect_distro()
{
  if which lsb_release >/dev/null; then
    local R=$(lsb_release -d -s)
    echo "Distribution discovered: $R"
    if [ -z "${R##Ubuntu 14.*}" ]; then
      SYSTEMINITDAEMON=upstart
    elif [ -z "${R##Ubuntu 15.04*}" ]; then
      SYSTEMINITDAEMON=systemd
    elif [ -z "${R##Debian*8.1*}" ]; then
      SYSTEMINITDAEMON=systemd
    fi
  else
    echo "WARNING: Unknown distribution, assuming defaults - this may fail." >&2
  fi
}

ensure_not_running()
{
  if [ -f /sys/devices/evdi/version ]; then
    local V=$(< /sys/devices/evdi/version)
    echo "WARNING: Version $V of EVDI kernel module is already running." >&2
    if [ -d $COREDIR ]; then
      echo "Please uninstall all other versions of $PRODUCT before attempting to install." >&2
    else
      echo "Please reboot before attempting to re-install $PRODUCT." >&2
    fi
    echo "Installation terminated." >&2
    exit 1
  fi
}

if [ $(id -u) != 0 ]; then
  echo "You need to be root to use this script." >&2
  exit 1
fi

echo "$PRODUCT $VERSION install script called: $*"
detect_distro
check_requirements

while [ -n "$1" ]; do
  case "$1" in
    install)
      ACTION="install"
      ;;

    uninstall)
      ACTION="uninstall"
      ;;

    *)
      usage
      ;;
  esac
  shift
done

if [ "$ACTION" == "install" ]; then
  ensure_not_running
  install
elif [ "$ACTION" == "uninstall" ]; then
  uninstall
fi

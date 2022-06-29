#!/bin/bash

mkdir -p module-signing
cd module-signing
if test -f MOK.priv; then
   echo "Found existing RSA key pair"
   evdi_ko=$(sudo modinfo -n evdi)
   if test -f $evdi_ko; then
      echo "Signing $evdi_ko"
      sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 MOK.priv MOK.der "$evdi_ko"
   else
      echo "Didn't find any evdi module to sign.  Did you forget to run the main script?"
   fi
else
   echo "Creating RSA key pair"
   openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=$HOSTNAME/"
   chmod 600 MOK.priv
   echo "You need to set one-time password to import your MOK into EFI."
   sudo mokutil --import MOK.der
   echo "When you reboot, your machine will enter MOK manager EFI utility.  Enroll MOK, Continue, Confirm, Enter Password, Reboot.  Come back here and run this script again."
   read -r -p "Reboot now? [Y/n] " response
   response=${response,,} # tolower
   if [[ $response =~ ^(yes|y) ]] || [[ -z $response ]]; then
      echo "yes!"
   fi
fi

You might not want to (or be able to) disable UEFI Secure Boot. In this case you can selfsign the evdi module.

[Øyvind Stegard](https://github.com/oyvindstegard) wrote a very clear and helpful [guide](http://web.archive.org/web/20191119232110/https://stegard.net/2016/10/virtualbox-secure-boot-ubuntu-fail/) for signing VirtualBox modules. You only have to replace step 5 by this:

`# nano /root/module-signing/sign-evdi-module.sh`
```
#!/bin/bash

for modfile in $(dirname $(modinfo -n evdi))/*.ko; do
  echo "Signing $modfile"
  /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 \
                                /root/module-signing/MOK.priv \
                                /root/module-signing/MOK.der "$modfile"
done
```
`# chmod 700 /root/module-signing/sign-evdi-module.sh`

And you can ignore step 7.

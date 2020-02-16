#!/bin/bash
apt-get install -y libdrm-dev libelf-dev
git clone https://github.com/DisplayLink/evdi.git
cd evdi
wget https://crazy.dev.frugalware.org/evdi-all-in-one-fixes.patch
patchPath="$(pwd)/evdi-all-in-one-fixes.patch"
patch -Np1<$patchPath
sed -E -e 's:SUBDIRS=([^ ]+) :M=\1 &:g' -i 'module/Makefile'
make
cd ..

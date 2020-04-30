#!/bin/bash
wget https://github.com/DisplayLink/evdi/archive/v1.6.4.tar.gz
tar -zxvf v1.6.4.tar.gz 
mv evdi-1.6.4/ evdi
cd evdi
wget https://crazy.dev.frugalware.org/evdi-all-in-one-fixes.patch
sed -i -E 's/\@\@ -26,6 \+26,8 \@\@ env:/\@\@ -25,6 \+25,9 \@\@ env:\n   \- KVER\=4.20/g' evdi-all-in-one-fixes.patch
sed -i -E 's/   \- KVER=5.2/\+  \- KVER=5.2/g' evdi-all-in-one-fixes.patch
patchPath="$(pwd)/evdi-all-in-one-fixes.patch"
patch -Np1<$patchPath
sed -E -e 's:SUBDIRS=([^ ]+) :M=\1 &:g' -i 'module/Makefile'
make
cd ..

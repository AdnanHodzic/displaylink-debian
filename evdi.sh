#!/bin/bash

apt-get install -y libdrm-dev libelf-dev

resourcesDir="$(pwd)/resources/"
evdiDir="$(pwd)/evdi/"
externalPatchDomain="https://crazy.dev.frugalware.org/"

#EVDI patch local resources
currentEvdiPatch="eaiof.patch"
patchFileName="evdi-all-in-one-fixes.patch"


#EVDI Web resources
externalPatchURL=$externalPatchDomain$patchFileName
evdiURL="https://github.com/DisplayLink/evdi.git"

#Patch paths 
currentPatchPath=$resourcesDir$currentEvdiPatch
commitPatchPath=$resourcesDir$patchFileName
finalPatchPath="$evdiDir$patchFileName"

#Triggers - whether we need to patch or not
performPatchCheck="false"
commitPatch="false"

#Check existing local resources
if [ ! -d $resourcesDir ] ; then
	echo "Making $resourcesDir"
	mkdir $resourcesDir
elif [ ! -f $currentPatchPath ] ; then
	echo "Will create new patch file"
else
	performPatchCheck="true"
fi


cd "$resourcesDir"
#remove all files except current local patch - if it's present
find . ! -name $currentEvdiPatch -delete

#download any new patch
echo "$externalPatchURL"

wget -N $externalPatchURL
#Check wget was successful
if [ $? -eq 0 ] ; then
	updateCurrentPatch="true"

	if [ "$performPatchCheck" = "true" ] ; then
		difFiles="$(ls | tr '\n' ' ')"
		if diff $difFiles &> /dev/null ; then
			updateCurrentPatch="false"
		fi
	fi
	
	if [ "$updateCurrentPatch" = "true" ]; then 
		cp $commitPatchPath $currentPatchPath
		##### APPLY THE PATCH TO EVDI #####
		commitPatch="true"
	fi
fi

cd ..

#Cleanup old EVDI folder
if [ -d $evdiDir ] ; then
	rm -rf $evdiDir
fi

git clone $evdiURL
cd "$evdiDir"
if [ "$commitPatch" = "true" ] ; then
	cp $commitPatchPath $evdiDir
	
	patch -Np1<$finalPatchPath
	sed -E -e 's:SUBDIRS=([^ ]+) :M=\1 &:g' -i 'module/Makefile'
fi

make
cd ..
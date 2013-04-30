#!/bin/bash
# -----------------------------------------------------------------------------------
# Bootcamp over VirtualBox Readme & License
# -----------------------------------------------------------------------------------
# Description:
#    Configure, setup a virtual machinefor Bootcamp Windows virtual machine over VirtualBox

# Command: vbobc.sh

# History:
#   Initial: Tony Liu, April 2013

# License:
# Bootcamp over VirtualBox is license under the Simplified BSD License – modified to forbid any
# commercial redistribution. Please contact with me if you want to use it for commercial purpose.

# Copyright (c) 2013, Tony Liu
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:

#    * Redistributions of source code must retain the above copyright notice, this list of 
#      conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice, this list
#      of conditions and the following disclaimer in the documentation and/or other materials
#      provided with the distribution.
#    * Any redistribution, use, or modification is done solely for personal benefit and not
#      for any commercial purpose or for monetary gain

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

#----------------------------------------------------------
# Thanks for Gianpaolo Del Matto and his document: Sharing Windows 7 between Boot Camp and VirtualBox

baseHTTP="http://download.virtualbox.org/virtualbox"

scriptname=`basename $0 .sh`
homepath=`echo ~`
workpath=`dirname $0`
currentUser=`whoami`
winVolumeName="Windows"
isVERBOSE=0
noDOWNLOAD=0
noINSTALL=0
isSecondStep=0
winIdentifier="disk0s4"
winIdentifierNumber="4"
winDriverNumber="0"

#--VM Info
vmcOSType="Windows7"
vmWinName="Win7"
ideController="PIIX4"
vmcMem=1200
vmcVRam=128

#--------------------------------------
#
usage() {   
   cat << EOF
This script Configure Bootcamp Windows virtual machine over VirtualBox.
Copyright Tony Liu, 2013, Version 0.1, Free for Educational or personal use.

Usage: $scriptname options

OPTIONS:
   -w      Windows volume Name, case sensitive
   -i      No install, will not install the latest version of VirtualBox.
   -d      Do not download
   -2      Second Step, set 
   -v      verbo mode
   -h      This help

EOF
}

#--------------------------------------
#
getHelps() {
   winVolumeName=
   while getopts “hvid2w:” OPTION
   do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         w)
             winVolumeName=$OPTARG
             ;;
         i)
             noINSTALL=1
             ;;
         d)
             noDOWNLOAD=1
             ;;
         v)
             isVERBOSE=1
             ;;
         2)
             isSecondStep=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
   done

   if [[ $isSecondStep -eq 1 ]]; then return 0; fi
   if [[ -z $winVolumeName ]]; then usage; exit 1; fi
}

#----------------------------------------------------------
# Download VirtualBox packages.
downloadVB() {
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: checking the latest version online."; fi

   latestVersion=`curl -s -L "$baseHTTP/LATEST.TXT"`
   if [ -z $latestVersion ]; then
  	noDOWNLOAD=1
		logger -i "$scriptname: cannot check latest version, internet connection problem."
		return 1
	else
		echo $latestVersion > LATEST.TXT;
	   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: save the latest version to LATEST.TXT file."; fi
	fi

   currentVersion=`cat packageVersion.txt`
   if [ $? -eq 0 ]; then
      latestVersion=${latestVersion%r*}
      currentVersion=${currentVersion%r*}
      if [ $currentVersion \< $latestVersion ]; then shouldUPDATE=1; else shouldUPDATE=0; fi
   fi
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: check current version <$currentVersion> with latest version <$latestVersion>, shouldUPDATE <$shouldUPDATE>."; fi

   if [ $noDOWNLOAD -lt 1 ]; then
      if [ $shouldUPDATE -gt 0 ]; then
         if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Start downloading VirtualBox package."; fi
	   	latestVersion=`cat LATEST.TXT`
		   vbFile=`curl -s -L "$baseHTTP/$latestVersion/" | grep -m 1 .dmg | awk -F "HREF=" '{print $2}' | awk -F \" '{print $2}'`
         if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: ... downloading VirtualBox package <$baseHTTP/$latestVersion/$vbFile>."; fi
         curl -s -L -o "$workpath/VirtualBox.dmg" "$baseHTTP/$latestVersion/$vbFile"
         if [ $? -gt 0 ]; then logger -i "$scriptname:(1) error downloading VirtualBox.DMG"; fi

		   extFile=`curl -s -L "$baseHTTP/$latestVersion/" | grep -m 1 .vbox-extpack | awk -F "HREF=" '{ print $2 }' | awk -F \" '{print $2}'`
         if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: ... downloading Extra pack <$baseHTTP/$latestVersion/$extFile>."; fi
         curl -s -L -o "$workpath/Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack" "$baseHTTP/$latestVersion/$extFile"
         if [ $? -gt 0 ]; then logger -i "$scriptname:(1) error downloading VB.vbox-extpack"; fi
         if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Finish downloading VirtualBox package."; fi
		fi
   fi
   if [ ! -e "$workpath/VirtualBox.dmg" ]; then logger -i "$scriptname:(1) VirtualBox.DMG wasn't downloaded correctly."; exit 1; fi
   if [ ! -e "$workpath/VirtualBox.dmg" ]; then logger -i "$scriptname:(1) VB.vbox-extpack wasn't downloaded  correctly."; exit 1; fi
	return 0
}

#----------------------------------------------------------
# Start to install VirtualBox.
installVB() {
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Start installing VirtualBox."; fi
   if [ $noINSTALL -gt 0 ]; then return; fi

   currentVersion=`VBoxManage -v`

   hdiutil detach -force -quiet $workpath/vbPackage
   mkdir -p $workpath/vbPackage
   hdiutil attach -readonly -noverify -noautofsck -noautoopen -mountpoint $workpath/vbPackage "$workpath/VirtualBox.dmg"

   sudo installer -pkg "$workpath/vbPackage/VirtualBox.pkg" -target /
   if [ $? -gt 0 ]; then logger -i "$scriptname:(2) VirtualBox installation error."; exit 2; fi
   # Install extra packs.
   VBoxManage -q extpack install "$workpath/Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack"
   if [ $? -gt 0 ]; then logger -i "$scriptname:(2) VirtualBox extpack installation error."; exit 2; fi
	hdiutil detach -force -quiet $workpath/vbPackage

   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Finish installing VirtualBox."; fi
}

#----------------------------------------------------------
# Find out Bootcamp disk number
findBCDisk() {
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Start getting Bootcamp volume info."; fi

   diskutil info -plist $winVolumeName > diskinfo.plist
   if [ $? -gt 0 ]; then logger "$scriptname:(3) Cannot find the Windows volume name <$winVolumeName>."; exit 3; fi
   winIdentifier=`defaults read $workpath/diskinfo DeviceIdentifier`
   winIdentifierNumber=`echo $winIdentifier | cut -c 5- | cut -d 's' -f 2`
   winDriverNumber=`echo $winIdentifier | cut -c 5- | cut -d 's' -f 1`
	
	defaults write "$workpath/config" Identifier -string "$winIdentifier"
	defaults write "$workpath/config" IdentifierNumber -int $winIdentifierNumber
	defaults write "$workpath/config" DriverNumber -int $winDriverNumber
	
   rm diskinfo.plist
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: ...<$winIdentifier>, <$winIdentifierNumber>, <$winDriverNumber>."; fi
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Finish getting Bootcamp volume info."; fi
}

#----------------------------------------------------------
# Prepare
creatVM() {
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Start creating rawdisk VMs files."; fi

		echo "$homepath/VirtualBox VMs/$vmWinName"
   # cd Win7onMBP
   sudo diskutil unmount $winIdentifier
   sudo chmod 777 "/dev/$winIdentifier"
   mkdir -p "$homepath/VirtualBox VMs/$vmWinName"
   # echo  VBoxManage internalcommands createrawvmdk -rawdisk "/dev/disk$winDriverNumber" -filename "$homepath/VirtualBox VMs/$vmWinName/$vmWinName.vmdk" -partitions $winIdentifierNumber
   #sudo VBoxManage internalcommands createrawvmdk -rawdisk "/dev/disk$winDriverNumber" -filename "$homepath/VirtualBox VMs/$vmWinName/$vmWinName.vmdk" -partitions $winIdentifierNumber
	sudo chown -R $currentUser "$homepath/VirtualBox VMs"
	sudo chmod -R 777 "$homepath/VirtualBox VMs"

   findVMS=`VBoxManage -q list vms | grep -num 1 $vmWinName`
	if [ "$findVMS" = ""  ]; then VboxManage createvm --name $vmWinName -register; fi
	# VboxManage showvminfo $vmWinName
	VboxManage -q modifyvm $vmWinName --ostype $vmcOSType --memory $vmcMem --vram $vmcVRam --acpi on --chipset ich9 --ioapic on --cpus 1 --cpuexecutioncap 90
	VboxManage -q modifyvm $vmWinName --accelerate3d off --pae on --hpet on --hwvirtex on --nic1 nat --nictype1 82540EM --cableconnected1 on  --accelerate2dvideo on
	VboxManage -q modifyvm $vmWinName --audio coreaudio --audiocontroller ac97 --clipboard bidirectional --usb on --usbehci on
	#VboxManage -q modifyvm $vmWinName

	VboxManage -q storagectl $vmWinName --name ideDrive --add ide --controller $ideController --bootable on
	VboxManage -q storageattach $vmWinName --storagectl ideDrive --port 0 --device 0 --type hdd --medium "$homepath/VirtualBox VMs/$vmWinName/$vmWinName.vmdk"
	VboxManage -q storageattach $vmWinName --storagectl ideDrive --port 0 --device 1 --type dvddrive --medium emptydrive
	
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Finish creating rawdisk VMs files."; fi
}

secondStep() {
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Start second step to modify VM."; fi
	if [ $ideController = "ICH9" ]; then
	   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Switch to SATA storage controller."; fi
		#VBoxManage -q storagectl $vmWinName --name ideDrive --remove
	   VBoxManage -q storagectl $vmWinName --name SATA --add sata --controller IntelAHCI --sataportcount 1 --hostiocache on --bootable on
		VBoxManage -q storageattach $vmWinName --storagectl SATA --port 0 --type hdd --medium "$homepath/VirtualBox VMs/$vmWinName/$vmWinName.vmdk"
		VBoxManage -q storageattach $vmWinName --storagectl SATA --port 1 --type dvddrive --medium emptydrive
	fi
   if [ $isVERBOSE -gt 0 ]; then echo "$scriptname: Finish second step to modify VM."; fi
}

# #######################
# Start!
getHelps $@
hwVersion=`system_profiler | grep "Model Identifier: " | awk '{ print $3 }'`
if [ "$hwVersion" \> "MacBookPro4,1" ]; then
	ideController="ICH9"
else
	ideController="PIIX4"
fi
defaults write "$workpath/config" ModelIdentifier -string "$hwVersion"
defaults write "$workpath/config" StorageController -string "$ideController"

if [ $isSecondStep -eq 1 ]; then 
	secondStep
else
	if [ $isVERBOSE -gt 0 ]; then echo "Make VirtualBox folder on Desktop."; fi
	mkdir -p $workpath
	cd $workpath
	downloadVB
	installVB
	findBCDisk
	creatVM
fi
exit 0

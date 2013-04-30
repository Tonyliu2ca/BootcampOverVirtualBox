BootcampOverVirtualBox
======================

Run Bootcamp windows as virtual machine in VirtualBox

Caution: This script is he first version which is experimental period for now.

What it does:
1. download VirtualBox packages to local and install
2. Find the correct BootCamp disk
3. Create a VM with all the parameters setup


For users:
----------
setup your windows (for now, this script assumes it's Windos 7) in BootCamp first. make sure Windows 7 can be loaded
and all BootCamp drivers are installed properly.

command options:
----------------
1. Must provide BootCamp partition name, the original is BOOTCAMP if it wasn't changed.
2. If VirutalBox is already downloaded, add -d option.
3. If you want to keep the current installed VirutalBox version, add -i option to skip installation.
4. verbo mode, sure for debug.

The command help screen:
------------------------
This script Configure Bootcamp Windows virtual machine over VirtualBox.
Copyright Tony Liu, 2013, Version 0.1, Free for Educational or personal use.

Usage: vbobc options

OPTIONS:
   -w      Windows volume Name, case sensitive
   -i      No install, will not install the latest version of VirtualBox.
   -d      Do not download
   -v      verbo mode
   -h      This help

common useage:
--------------
1. vbobc -w BOOTCAMP
2. vbobc -w BOOTCAMP -i -d

Bug report and suggestions please email to tonyliu2ca@gmail.com

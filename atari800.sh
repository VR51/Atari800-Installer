#!/bin/bash
clear
# set -x
###
#
#	Atari800 Installer 1.0.0
#
#	General installer & updater.
#	Compiles software from source and installs binaries and files to their expected locations.
#
#	For OS: Linux (Debian)
#	Tested With: Ubuntu flavours
#
#	Lead Author: Lee Hodson
#	Donate: https://paypal.me/vr51
#	Website: https://journalxtra.com/installers/zesarux/
#	This Release: 3rd Sep 2018
#	First Written: 3rd Sep 2018
#	First Release: 3rd Sep 2018
#
#	Copyright 2018 Lee Hodson <https://journalxtra.com>
#	License: GPL3
#
#	Programmer: Lee Hodson <journalxtra.com>, VR51 <vr51.com>
#
#	Use of this program is at your own risk
#
# INSTALLS OR UPDATES
#
#	Atari800 the Atari Emulator.
#
#	TO RUN:
#
#	Ensure the script is executable:
#
#	Right-click > properties > Executable
#	OR
#	chmod u+x Atari800.sh
#
#	Launch by clicking the script file or by typing bash atari800.sh at the command line.
#
#	Atari800 will be compiled in $HOME/src/atari800/src
#
#	Files that exist in $HOME/src/atari800 will be overwritten or updated by this program.
#
#	LIMITATIONS
#
#	You will need games and system ROMs to use this emulator enjoyably.
#	Visit https://journalxtra.com/gaming/download-complete-sets-of-mess-and-mame-roms/ to find some.
# Atari 8-bit game disk downloader is available at https://journalxtra.com/gaming/classic-atari-games-downloader/
#
###

##
#	Options
##

# Do not Use trailing slashes in URLs, URIs or directory paths

	package='Atari800' # Name of software installed by this installer

	repoloc='https://github.com/atari800/atari800' # Root location of the program. Equates to Github master URL. We need the repo address only. The rest of the address is added by the installer.
	srcloc='https://github.com/atari800/atari800.git' # Software source package git address
	dirsrc="$HOME/src/atari800" # Directory where the source code will be stored locally
	dirsrcbuild="$HOME/src/atari800/src" # Directory where the source code for the binary will be stored locally. Where will the binary be built?
	diricon="$HOME/src/atari800/data" # Directory where the application icon will be located.
	icon="atari2.svg" # Icon name
	docs="$HOME/src/atari800/DOC" # Location of program documents.
	configloc="$HOME/.atari800.cfg" # Location of user config file that stores the user's custom settings for the package.

	binary="atari800" # Name of the target binary.

	type='Application' # 
	cats='Game;Games' # Application launcher categories

# install='/usr/games' # Binary installation path. Where should the compiled binary be installed to? Exact path. # Not required for this installer.

	user=$(whoami) # Current User
	group=$(id -g -n $user) # Current user's primary group

# Internal Settings - These do not usually need to be manually changed

	declare -a conf
	declare -a menu # Menu options are set within installer_prompt()
	declare -a select # Menu options count
	declare -a message # Index indicates related conf, mode or menu item
	declare -a mode # Used for notices
	declare -a essentialpackages # Packages to install to help the build process
	
	conf[0]=0 # Essentials # Install build essential software. 0 = Not done, 1 = Done
	conf[1]=2 # Clean Stale # Do no cleaning or run make clean or delete source files? 0/1/2. 0 = No Clean, 1 = Soft Clean, 2 = Hard Clean.
	conf[2]=0 # Parallel jobs to run during build # Number of CPU cores + 1 is safe. Can be as high as 2*CPU cores. More jobs can shorten build time but not always and risks system stability. 0 = Auto.
	conf[3]=$(nproc) # Number of CPU cores the computer has.
	conf[4]=$($binary -v) # Installed package version
	# conf[4]=$($binary -v | grep "$package Version:") # Installed Version grep method 
	conf[5]=$(curl -v --silent "$repoloc/commit/master" --stderr - | grep '<relative-time datetime' | sed -E 's#<relative-time datetime="(.+)">.+$#\1#g' | tr -d '[:space:]' | tr '[:alpha:]' ' ')
	conf[6]=$(if test -f "$configloc" ; then echo "1"; fi)

	essentialpackages=( build-essential gcc g++ libqtwebkit-dev libsdl2* sdllib libqt5* qt5* autoconf zlib libpng curl )
	
## END Options

## BEGIN

	let safeproc=${conf[3]}+${conf[3]} # Safe number of parallel jobs, possibly.

# Other settings

	bold=$(tput bold)
	normal=$(tput sgr0)

# Locate where we are
	filepath="$( echo $PWD )"
# A Little precaution
	cd "$filepath"

# Make SRC directory if it does not already exist

	if test ! -d "$HOME/src"; then
		mkdir "$HOME/src"
	fi

# Functions

function installer_run() {
	# Check for terminal then run else just run program
	tty -s
	if test "$?" -ne 0 ; then
		installer_launch
	else
		installer_prompt "${menu[*]}"
	fi
	
}

function installer_prompt() {

	while true; do

		# Set Menu Options

		case ${conf[1]} in
		
			0)
				message[1]='No cleaning'
				menu[1]="Update $package. Do not clean build cache."
				mode[1]='MODE 1: Update. Press 3 to change mode.'
			;;

			1)
				message[1]='Clean Compiler Cache'
				menu[1]="Update $package. Clean cache before build."
				mode[1]='MODE 2: Update. Press 3 to change mode.'
			;;

			2)
				message[1]='Delete Source Files'
				menu[1]="Install $package. Delete old source code. Download fresh source code before build."
				mode[1]='MODE 3: Install. Press 3 to change mode.'
			;;

		esac

		menu[2]=''
		
		case "${conf[2]}" in
		
			0)
				menu[3]="Number of parallel jobs the installer should run. ${conf[3]} is Safe. $safeproc Max: Auto"
			;;
			
			*)
				menu[3]="Number of parallel jobs the installer should run ( Auto, Safe(${conf[3]}) or Max($safeproc) ): ${conf[2]}"
			;;
			
		esac
		
		menu[4]="Clean Level: ${message[1]}"
		menu[5]=''
		
		case "${conf[0]}" in

			0)
				menu[6]='Install Build Essential Software Packages'
				
				case ${conf[1]} in
				
					0) # Update - No spring clean. Update source files
						message[1]='\nIf installation fails Install Essential Build Packages and/or change to Mode 2 or 3 then try again.\n'
					;;
				
					1) # Update - spring clean first. Update source files
						message[1]='\nIf installation fails Install Essential Build Packages and/or change to Mode 3 try again.\n'
					;;
					
					2) # Clean install. Delete source files. Download fresh source files.
						message[1]='\nIf installation fails Install Essential Build Packages then try again.\n'
					;;
					
				esac
				
			;;
			
			1)
				menu[6]='Build Essential Software Packages already installed.'
			
			;;
			
		esac
		
		menu[7]=''
		
		case "${conf[6]}" in
		
			1)
				menu[8]="Reset $package saved configuration? This deletes saved $package settings."
				
			;;
			
		esac

		printf $bold
		printf "${mode[1]}\n"
		printf $normal
		
		printf "\nMENU\n\n"

		n=1
		for i in "${menu[@]}"; do
			if [ "$i" == '' ]; then
				printf "\n"
			else
				printf "$n) $i\n"
				select[$n]=$n
				let n=n+1
			fi
		done

		printf "\n0) Exit\n\n"

		# Notices

			printf $bold

			printf "${message[1]}"
			printf "\nIf the computer crashes during installation lower the number of parallel jobs used by the installer then try again.\n"

			printf "\nGENERAL INFO\n"
				
			printf $normal

			printf "\n System $package: ${conf[4]}"
			printf "\n Latest git commit: ${conf[5]}\n"

		printf $bold
			printf "\nChoose Wisely: "
		printf $normal
		read REPLY

		case $REPLY in

		${select[1]}) # Install / Update the package

			printf "\nInstalling $package This could take between a few moments and a long time or even a very long time. Go get a coffee.\n"

			cd "$HOME/src"

			# Test source files exist. Download them if not.
			if test -d "$dirsrc" ; then
				# Make sure we own the source files
				sudo chown -R $user:$group "$dirsrc"
				
				# Decide whether to update or install
				case ${conf[1]} in
				
					0) # Update - No spring clean. Update source files
						cd "$dirsrc"
						git pull -p
					;;
				
					1) # Update - spring clean first. Update source files
						cd "$dirsrc"
						make clean
						make distclean
						git pull -p
					;;
					
					2) # Clean install. Delete source files. Download fresh source files.
						rm -r -f "$dirsrc"
						git clone --depth 1 "$srcloc"
						cd "$dirsrc"
					;;
					
				esac

			else
				# Clean install necessary - Source files not present yet
				git clone --depth 1 "$srcloc"
				cd "$dirsrc"

			fi

			case "${conf[2]}" in
				0)
					jobs=''
				;;
				
				*)
					jobs="-j${conf[2]}"
				;;
			esac
			
			# Build Package
			cd "$dirsrcbuild"
			chmod u+x autogen.sh
			./autogen.sh
			./configure
			make $jobs

			# Compile then install the binary
			if test -f "$dirsrcbuild/$binary"; then
				chmod u+x "$dirsrcbuild/$binary"
				sudo make install
				# sudo ln -s "$dirsrcbuild/$binary" "$install/$binary" # We were going to softlink to the executable but the program wouldn't run as a link

				# Add desktop file for application menu if it does not already exist
				if test -f "$diricon/$icon"; then
					sudo mv "$diricon/$icon" "/usr/share/icons/$icon"
				fi
				
				if test ! -f "/usr/share/applications/$binary.desktop"; then
					echo -e "[Desktop Entry]\nType=$type\nCategories=$cats\nName=$package\nExec=$binary\nIcon=$icon\n" > "$dirsrcbuild/$binary.desktop"
					sudo mv "$dirsrcbuild/$binary.desktop" "/usr/share/applications/$binary.desktop"
				fi

				sudo ldconfig
				sudo updatedb
				
				conf[4]=$($binary -v) # Newly installed zesarux version
			
				# conf[4]=$($binary -v | grep "$package Version:") # Newly installed binary version grep method

				clear

				printf "\n$package is ready to use.\n"
				printf "\n$package Altirra BIOS-es for all emulated systems: 400/800, XL/XE, and 5200, as well as Altirra BASIC. No need to supply BIOS files or BASIC.\n"
				printf "\nRun by typing $binary into a terminal or find $binary in your applications manager.\n"
				printf "\nKeys: Press F1 to open the application's menu. F2 is Option. F3 is Select. F4 is Start. F5 is Reset. Shift+F5 is Reboot.\n"
				printf "\nRead $docs for more info. Type 'man $binary' for manual\n"

			else
				printf "\n\n$package installation failed. \n\n"
			fi

			printf "\nPress ANY key"
			read something
			clear

		;;

		${select[2]}) # Parallel jobs to run during build
		
			case "${conf[2]}" in
			
				$safeproc)

					let conf[2]=0
					sed -i -E "0,/conf\[2\]=[0-9]{1,2}/s/conf\[2\]=[0-9]{1,2}/conf\[2\]=${conf[2]}/" "$0"

				;;

				*)

					let conf[2]=${conf[2]}+1
					sed -i -E "0,/conf\[2\]=[0-9]{1,2}/s/conf\[2\]=[0-9]{1,2}/conf\[2\]=${conf[2]}/" "$0"
					
				;;

			esac

			clear

		;;

		${select[3]}) # Set update, install, clean flag
		
			case ${conf[1]} in
			
				0)
					sed -i -E "0,/conf\[1\]=0/s/conf\[1\]=0/conf\[1\]=1/" "$0"
					conf[1]=1
				;;

				1)
					sed -i -E "0,/conf\[1\]=1/s/conf\[1\]=1/conf\[1\]=2/" "$0"
					conf[1]=2
				;;

				2)
					sed -i -E "0,/conf\[1\]=2/s/conf\[1\]=2/conf\[1\]=0/" "$0"
					conf[1]=0
				;;

			esac

			clear
			
		;;

		${select[4]}) # Install software packages necessary to build the package
		
			case "${conf[0]}" in
			
				0)
		
					printf "\nThis will attempt to install the following packages:\n"

					for i in "${essentialpackages[@]}"; do
						printf "$i "
					done

					printf "\nContinue to install them: Yn:\n"
					read a

					while true; do
						case $a in

						y|Y)
						
							sudo apt-get update

							for i in "${essentialpackages[@]}"; do
								sudo apt-get build-dep -y -q $i
								sudo apt-get install -y -q --install-suggests $i
							done

							sed -i -E "0,/conf\[0\]=0/s/conf\[0\]=0/conf\[0\]=1/" "$0" # Edits the installer file to set the 'Essentials installed' flag i.e. conf[0]=1
							conf[0]=1

							printf "\nPress any key to continue\n"
							read something
							clear

						;;

						n|N)

							clear

						;;
						
						*)

						esac
						
					done
					
				;;
				
			esac

		;;
		
		${select[5]}) # Reset saved configuration
		
			clear
		
			if test -f "$configloc"; then
				rm "$configloc"
				conf[6]=$(if test -f "$configloc" ; then echo "1"; fi)
				printf "$package configuration reset.\n"
				printf "\nPress any key to continue\n"
				read something
			else
				printf "$package configuration file not found. Nothing to do. Nothing done.\n"
				printf "\nPress any key to continue\n"
				read something
			fi

			clear
		
		;;

		0) # Exit

			exit 0

		;;

		*)

		esac

  done
  
}


## launch terminal

function installer_launch() {

	terminal=( konsole gnome-terminal x-terminal-emulator xdg-terminal terminator urxvt rxvt Eterm aterm roxterm xfce4-terminal termite lxterminal xterm )
	for i in ${terminal[@]}; do
		if command -v $i > /dev/null 2>&1; then
			exec $i -e "$0"
			# break
		else
			printf "\nUnable to automatically determine the correct terminal program to run e.g Console or Konsole. Please run this program from the command line.\n"
			read something
			exit 1
		fi
	done
}

## Boot

installer_run "$@" # Loops back to the start. The script is read by BASH then installer_run is run. This ensures all functions are read into memory before anything happens.

# Exit is at end of installer_run()

# FOR DEBUGGING

# declare -p
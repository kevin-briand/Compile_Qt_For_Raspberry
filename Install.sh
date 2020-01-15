#!/bin/sh

#Saisie utilisateur
echo 'Automatic Compile Qt for Raspbian Script'

echo 'Select Qt version :'
echo '1 - 5.13.1'
read var
if [ $var = "1" ]
then
	version='5.13.1'
fi

echo 'Select Raspberry version : '
echo '1 - zero, 1'
echo '2 - 2'
echo '3 - 3'
read var
if [ $var = "1" ]
then
	RPIVersion='1'
elif [ $var = "2" ]
then
	RPIVersion='2'
elif [ $var = "3" ]
then
	RPIVersion='3'
else
	echo 'Bad Char !'
fi

echo 'Set RPI ip :'
read ip

echo 'Set RPI login :'
read login

echo 'Set RPI Password :'
read password


if [ $RPIVersion != "" ] && [ $ip != "" ] && [ $login != "" ] && [ $password != "" ] && [ $version != "" ]
then
	echo 'Install essntial'
	sudo apt-get install sshpass

	echo 'Run RPI_Step1'
	sshpass -p $password ssh $login@$ip '/home/pi/Compile_Qt_For_Raspberry/RPI_Step1'
	echo 'Wait 1 minutes...'
	sleep 1m
	echo 'Run RPI_Step3'
	sshpass -p $password ssh $login@$ip '/home/pi/Compile_Qt_For_Raspberry/RPI_Step3'

	echo ''
	sudo apt-get install git rsync make g++

	mkdir ~/raspi
	cd ~/raspi
	git clone https://github.com/raspberrypi/tools

	mkdir sysroot sysroot/usr sysroot/opt
	rsync -avz --rsh="sshpass -p $password ssh -o StrictHostKeyChecking=no -l $login" $ip:/lib sysroot
	rsync -avz --rsh="sshpass -p $password ssh -o StrictHostKeyChecking=no -l $login" $ip:/usr/include sysroot/usr
	rsync -avz --rsh="sshpass -p $password ssh -o StrictHostKeyChecking=no -l $login" $ip:/usr/lib sysroot/usr
	rsync -avz --rsh="sshpass -p $password ssh -o StrictHostKeyChecking=no -l $login" $ip:/opt/vc sysroot/opt

	wget https://raw.githubusercontent.com/Kukkimonsuta/rpi-buildqt/master/scripts/utils/sysroot-relativelinks.py
	chmod +x sysroot-relativelinks.py
	./sysroot-relativelinks.py sysroot

	git clone git://code.qt.io/qt/qtbase.git -b $version
	cd qtbase
	./configure -release -opengl es2 -device $RPIVersion -device-option CROSS_COMPILE=~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf- -sysroot ~/raspi/sysroot -opensource -confirm-license -make libs -prefix /usr/local/qt5pi -extprefix ~/raspi/qt5pi -hostprefix ~/raspi/qt5 -v -no-use-gold-linker

	make
	make install

	cd ..
	rsync -avz --rsh="sshpass -p $password ssh -o StrictHostKeyChecking=no -l $login" $ip:/usr/local

	echo 'Run RPI_Step 5'
	sshpass -p $password ssh $login@$ip '/home/pi/Compile_Qt_For_Raspberry/RPI_Step5'

	echo '
Go to Options -> Devices
  Add
    Generic Linux Device
    Enter IP address, user & password
    Finish

Go to Options -> Compilers
  Add
    GCC
    Compiler path: ~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-g++

Go to Options -> Debuggers
  Add
    ~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gdb

Go to Options -> Qt Versions
  Check if an entry with ~/raspi/qt5/bin/qmake shows up. If not, add it.

Go to Options -> Build & Run
  Kits
    Add
      Generic Linux Device
      Device: the one we just created
      Sysroot: ~/raspi/sysroot
      Compiler: the one we just created
      Debugger: the one we just created
      Qt version: the one we saw under Qt Versions
      Qt mkspec: leave empty

'
fi

#!/bin/bash

getting_username_function () {
clear

user_numbers=$(ls /home | wc -l)


#list users, will need to make it better here
if [ $user_numbers" == "1 ] ; then
  echo "We only have a username inside home Directory"
  username=`ls /home`
echo "Using $username as user"
  fi





echo ""
echo "We need a username to install the systemd service"
echo ""
echo "This will be your default username"
echo ""
echo "looking in /home for users"
echo ""
echo ""
echo "Press 1 for $username"
echo ""
echo "Press 2 for manual input"
echo ""
echo "Press 3 for exit"
echo ""


while true; do
    read -p "Choose an username to install sounds    (1/2/3) " username_answer
    case $username_answer in
        [1]* )
           echo $username
           #install_function
           break;;
         [2]* )
           echo "Please type your username and press Enter"
           read username
           echo "continue with $username username"

           break;;


        [3]* )
           echo "Will Now Exit! No Action Was Taken!"
           exit;;
        * ) echo "Please answer 1,2 or 3!";;
    esac
done







install_function


}

install_function () { ###############################################       main install function###############################################

echo "will now proceed installation!"

#######creating systemd services###############################

if [ ! -d "/etc/sounds" ]
then
    echo "Directory /etc/sounds does not exist, creating."
    mkdir  /etc/sounds
    fi


#copy sound files

cp USB-Remove.wav /etc/sounds/USB-Remove.wav
cp USB-Insert.wav /etc/sounds/USB-Insert.wav

touch /etc/systemd/system/usb-insert.service
touch /etc/systemd/system/usb-remove.service

{
echo '[Unit]'
echo 'Description=Play USB sound'
echo ""
echo '[Service]'
echo "User="$username""
echo 'Type=oneshot'
echo 'Environment="XDG_RUNTIME_DIR=/run/user/1000"'
echo 'ExecStart=/usr/bin/aplay /etc/sounds/USB-Insert.wav'
} > /etc/systemd/system/usb-insert.service


{
echo '[Unit]'
echo 'Description=Play USB sound'
echo ""
echo '[Service]'
echo "User="$username""
echo 'Type=oneshot'
echo 'Environment="XDG_RUNTIME_DIR=/run/user/1000"'
echo 'ExecStart=/usr/bin/aplay /etc/sounds/USB-Remove.wav'
} > /etc/systemd/system/usb-remove.service



############################################creating usb rules for sound
touch /etc/udev/rules.d/100-usb.rules

#touch 100-usb.rules

echo  'ACTION=="add", SUBSYSTEM=="usb", KERNEL=="*:1.0", RUN+="/bin/systemctl start usb-insert"' > /etc/udev/rules.d/100-usb.rules

echo 'ACTION=="remove", SUBSYSTEM=="usb", KERNEL=="*:1.0", RUN+="/bin/systemctl start usb-remove"' >> /etc/udev/rules.d/100-usb.rules
##########################################################################



#restarts systemd services
systemctl daemon-reload
#restarts systemd-udevd
systemctl restart systemd-udevd

}
#########################################################################end of install function!########################################################################################


##################################################################uninstall_function####################################################################################################
uninstall_function () {
rm /etc/systemd/system/usb-remove.service

rm /etc/systemd/system/usb-insert.service

rm /etc/udev/rules.d/100-usb.rules

#restarts systemd services
systemctl daemon-reload
#restarts systemd-udevd
systemctl restart systemd-udevd
}




#################################################################end of uninstall function##############################################################################################
clear
#clears the screen
echo ""
echo "Welcome"
echo ""

#check if you are root else exits
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
#######check dependency
echo "Checking dependencies"
echo ""
echo "We have root"
##systemd
 if hash systemctl 2>/dev/null;
    then
       echo ""
        echo "Systemd is installled, will continue"
    else
    echo "Systemd is NOT installled, will exit"
    exit
    fi
########aplay
if which aplay >/dev/null; then
echo ""
    echo "aplay in installed, will continue"
else
    echo "aplay missing, please install dependency and run script again!"
fi
echo                "########################################"
echo ""
echo "This will install sounds when you Connect/Disconnect a USB Device"
echo ""
echo "Choose one of the following options:"
echo ""
echo ""

echo "1-Install USB Event Sounds"
echo ""
echo "2-Uninstall USB Event Sounds"
echo ""
echo "3-Exit"
echo ""





while true; do
    read -p "Choose an action!   (1/2/3) " answer
    case $answer in
        [1]* )
           echo "Start Installation "
           #install_function
            getting_username_function
           break;;
         [2]* )
           echo "Start Uninstall"
           uninstall_function

           break;;


        [3]* )
           echo "Will Now Exit! No Action Was Taken!"
           exit;;
        * ) echo "Please answer 1,2 or 3!";;
    esac
done

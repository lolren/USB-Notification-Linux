#!/bin/bash

####define some colours for bash
#release  0.8
# changelog
#-add default answers

Color_Off='\033[0m'       # Text Reset
# Regular Colors

Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# High Intensity

IRed='\033[0;91m'         # Red
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue

getting_username_function () {
clear # clears the screen
user_numbers=$(ls /home | wc -l)

#list users, will need to make it better here
if [ $user_numbers" == "1 ] ; then
  echo "We only have a username inside home Directory"
  username=`ls /home`

echo -e "Using ${IRed}$username${Color_Off} as user!"
fi
echo ""
echo "We need a username to install the systemd service"
echo ""
echo "This will be your default username"
echo ""
echo "looking in /home for users"
echo ""
echo ""
echo -e  "${UCyan} Press 1 to use ${IRed}$username${Color_Off} ${UCyan} username${Color_Off} "
echo ""
echo -e  "${UYellow} Press 2  to manually input username${Color_Off} "
echo ""
echo -e " ${UPurple}Press 3 for exit${Color_Off} "
echo ""

while true; do
    read -e -p "Choose an username to install sounds: " -i 1  username_answer
    case $username_answer in
        [1]* )
           echo -e "username ${UCyan} $username ${Color_Off} was choosen. will use it"
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

install_function #go to install function

}

install_function () { ############################################### main install function###############################################
clear
echo ""
echo "The Installation will now proceed"

#####################################################################creating systemd services###############################

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
if [ "$install_notifications" == "1" ] ; then echo 'ExecStartPre=/bin/bash /etc/sounds/notify.sh Connected' ; fi
echo 'ExecStart=/usr/bin/aplay /etc/sounds/USB-Insert.wav'
echo "Environment="DISPLAY=:0" "XAUTHORITY=/home/"$username"/.Xauthority""
} > /etc/systemd/system/usb-insert.service


{
echo '[Unit]'
echo 'Description=Play USB sound'
echo ""
echo '[Service]'
echo "User="$username""
echo 'Type=oneshot'
echo 'Environment="XDG_RUNTIME_DIR=/run/user/1000"'
if [ "$install_notifications" == "1" ] ; then echo 'ExecStartPre=/bin/bash /etc/sounds/notify.sh Disconnected' ; fi
echo 'ExecStart=/usr/bin/aplay /etc/sounds/USB-Remove.wav'
if [ "$install_notifications" == "1" ] ; then echo "Environment="DISPLAY=:0" "XAUTHORITY=/home/"$username"/.Xauthority"" ; fi
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

#########################creating bash script############
###looking for kdialog or notify-send (libnotify)
                      if [ "$install_notifications" == "1" ] ; then
                                      {


                                                                                                        if which notify-send >/dev/null; then
                                                                                                                              echo ""
                                                                                                         echo -e "${BBlue}libnotify ${Color_Off}is installed. Will use ${BBlue} libnotify!${Color_Off} "
                                                                                                           use_kdialog=0
                                                                                                           use_libnotify=1;
                                                                                                           elif which kdialog >/dev/null; then
                                                                                                           {
 echo -e "${BBlue}kdialog ${Color_Off} is installed, will use ${BBlue} KDE ${Color_Off}notification SUBSYSTEM"
                                                                                                                                 use_kdialog=1
                                                                                                                                 use_libnotify=0;
                                                                                                           }
                                                                                                                             else
                                                                                                                                 {
                                                                                                                                 echo "No notification library was found. Will not install any of them!"
                                                                                                                                 echo "Please install ${BBlue}libnotify ${Color_Off} or ${BBlue}libnotify-bin${Color_Off}"
                                                                                                                                 use_kdialog=0
                                                                                                                                 use_libnotify=0;
                                                                                                                                 }
                                                                                                                                 fi

                                                            {
                                                            echo "#!/bin/bash"
                                                            echo 'export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${UID}/bus}"'
                                                            if [ $use_kdialog == "1" ] ; then  echo 'kdialog --passivepopup "USB Device $1" 2' ; fi
                                                            if [ $use_libnotify == "1" ] ; then  echo 'notify-send -t 2000 "USB Device $1" ' ; fi
                                                             } > /etc/sounds/notify.sh
                                                             chmod +x /etc/sounds/notify.sh



                                       } # end of install_notifications condition
                    fi
   echo ""
   echo -e "Successful Installation. Plug in a USB device to test."
   echo ""
 } # end of main function

#########################################################################end of install function!########################################################################################

############################################################################uninstall_function##########################################################################################
uninstall_function () {
rm /etc/systemd/system/usb-remove.service

rm /etc/systemd/system/usb-insert.service

rm /etc/udev/rules.d/100-usb.rules
rm /etc/sounds/notify.sh

#restarts systemd services
systemctl daemon-reload
#restarts systemd-udevd
systemctl restart systemd-udevd
}
#################################################################end of uninstall function##############################################################################################
clear
#clears the screen
echo ""
echo "Welcome. This script will install sounds on connecting/disconnecting a usb device."
echo "You can also choose to install a notification"
echo                "########################################"
#check if you are root else exits
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
########################################check dependency########################################
echo ""
echo "Sound Notification Dependencies"
##systemd
 if hash systemctl 2>/dev/null;
    then
    echo ""
    echo -e "${BBlue} Systemd${Color_Off} is installled"
    else
    echo -e "${BRed} Systemd${Color_Off} is NOT installled, will exit"
    exit
    fi
########aplay
if which aplay >/dev/null; then
echo ""
    echo -e "${BBlue} Aplay${Color_Off} is installed"
else
    echo -e "${BRed} Aplay${Color_Off} missing, please install dependency and run script again!"
fi
echo ""
echo -e "Visual Notification Dependencies "
echo ""
if which notify-send >/dev/null || which kdialog >/dev/null  ; then
{
echo -e " ${BBlue}libnotify${Color_Off} or ${BBlue}kdialog${Color_Off} are installed"
visuals=1
default_answer=0
}
else
{
echo -e "${BRed}libnotify${Color_Off} or ${BBlue}kdialog${Color_Off}  are  not installed"
default_answer=1
visuals=0
}
fi
echo ""


####################################################################################
echo                "########################################"
echo ""
echo ""
echo "Choose one of the following options:"
echo ""
if [ "$visuals" == "1" ] ; then  echo -e "${IYellow} 0-Install USB Event Sounds and notifications (Beta) ${Color_Off} " ; fi
echo ""
echo  -e "${IBlue} 1-Install USB Event Sounds only ${Color_Off}"
echo ""
echo -e " ${IRed}2-Uninstall USB Event Sounds ${Color_Off} "
echo ""
echo -e " ${UPurple}3-Exit${Color_Off} "
echo ""

while true; do
    read -e -p "Choose an action: " -i $default_answer answer
     case $answer in
        [0]* )
           echo  "Start Installation of Sounds and Notifications "
           install_notifications=1
            getting_username_function
           break;;
        [1]* )
           echo "Start Installation of Sounds only"
           install_notifications=0
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

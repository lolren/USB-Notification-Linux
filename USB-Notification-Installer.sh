#!/bin/bash

####define some colours for bash

Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
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
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White
###############################


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
    read -p "Choose an username to install sounds    (1/2/3) " username_answer
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
echo "will now proceed installation!"

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
    echo "aplay is installed, will continue"
else
    echo "aplay missing, please install dependency and run script again!"
fi
echo                "########################################"
echo ""
echo ""
echo "Choose one of the following options:"
echo ""
echo -e "${IYellow} 0-Install USB Event Sounds only ${Color_Off} "
echo ""
echo  -e "${IBlue} 1-Install USB Event Sounds  and notifications (Beta) ${Color_Off}"
echo ""
echo -e " ${IRed}2-Uninstall USB Event Sounds ${Color_Off} "
echo ""
echo -e " ${UPurple}3-Exit${Color_Off} "
echo ""

while true; do
    read -p "Choose an action!   (0/1/2/3) " answer
     case $answer in
        [0]* )
           echo  "Start Installation of Sounds only "
           #install_function
           install_notifications=0
            getting_username_function
           break;;
        [1]* )
           echo "Start Installation of Sounds and Notifications"
           #install_function
           install_notifications=1
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

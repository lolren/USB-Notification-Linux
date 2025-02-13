#!/bin/bash

# Release 0.9
# Configuration
use_names="true"
dmesg_conf_file="/etc/sysctl.d/10-local.conf"
dmesg_conf_line="kernel.dmesg_restrict = 0"

# Colors
Color_Off='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BBlue='\033[1;34m'
UBlue='\033[4;34m'
UPurple='\033[4;35m'
UCyan='\033[4;36m'
UYellow='\033[4;33m'

# Function to check dmesg access
check_dmesg_access() {
    # Check the current value of kernel.dmesg_restrict
    local current_value=$(sysctl -n kernel.dmesg_restrict 2>/dev/null || echo "1")

    if [ "$current_value" = "0" ]; then
        return 0  # dmesg is accessible (unrestricted)
    else
        return 1  # dmesg is restricted
    fi
}

# Function to fix dmesg access
fix_dmesg_access() {
    if [ ! -f "$dmesg_conf_file" ]; then
        touch "$dmesg_conf_file"
    fi
    if ! grep -q "^$dmesg_conf_line" "$dmesg_conf_file"; then
        echo "$dmesg_conf_line" >> "$dmesg_conf_file"
        sysctl -p "$dmesg_conf_file"
        echo -e "${BGreen}dmesg access has been enabled for all users${Color_Off}"
    fi
}

# Function to disable dmesg access
disable_dmesg_access() {
    if [ -f "$dmesg_conf_file" ]; then
        # First remove any existing dmesg_restrict settings
        sed -i '/kernel.dmesg_restrict/d' "$dmesg_conf_file"

        # Add the restrictive setting
        echo "kernel.dmesg_restrict = 1" >> "$dmesg_conf_file"

        # Apply changes
        sysctl -p "$dmesg_conf_file" || {
            echo -e "${BRed}Failed to apply dmesg restrictions${Color_Off}"
            return 1
        }

        # Verify the change
        if sysctl kernel.dmesg_restrict | grep -q "= 1"; then
            echo -e "${BGreen}dmesg access has been restricted${Color_Off}"
            sleep 2  # Give user time to read the message
        else
            echo -e "${BRed}Failed to restrict dmesg access${Color_Off}"
            return 1
        fi
    else
        echo -e "${BRed}Configuration file $dmesg_conf_file not found${Color_Off}"
        return 1
    fi
}
# Check dependencies function
check_dependencies() {
    echo -e "${BBlue}Checking dependencies...${Color_Off}"

    # Check systemd
    if hash systemctl 2>/dev/null; then
        echo -e "✓ ${BGreen}systemd${Color_Off} is installed"
    else
        echo -e "✗ ${BRed}systemd${Color_Off} is NOT installed"
        exit 1
    fi

    # Check aplay
    if which aplay >/dev/null; then
        echo -e "✓ ${BGreen}aplay${Color_Off} is installed"
    else
        echo -e "✗ ${BRed}aplay${Color_Off} is missing - please install alsa-utils"
        exit 1
    fi

    # Check dmesg access
    echo -e "\n${BBlue}Checking dmesg access...${Color_Off}"
    if check_dmesg_access; then
        echo -e "✓ ${BGreen}dmesg${Color_Off} is accessible without sudo"
    else
        echo -e "✗ ${BRed}dmesg${Color_Off} requires sudo access"
        echo -e "  ${BYellow}Note:${Color_Off} This affects USB device name detection"
        echo -e "  ${BYellow}You can enable user access to dmesg from the main menu${Color_Off}"
    fi

    # Check notification dependencies
    echo -e "\n${BBlue}Checking notification system...${Color_Off}"
    if which notify-send >/dev/null || which kdialog >/dev/null; then
        echo -e "✓ ${BGreen}notification system${Color_Off} is installed"
        visuals=1
        default_answer=1
    else
        echo -e "ℹ ${BYellow}notification system${Color_Off} is not installed (optional)"
        echo -e "  Install ${BCyan}libnotify-bin${Color_Off} or ${BCyan}kdialog${Color_Off} for notifications"
        visuals=0
        default_answer=2
    fi
}

# Filter system users function
filter_system_users() {
    local user="$1"
    if [[ "$user" == *"daemon"* ]] || [[ "$user" == *"sys"* ]] || [[ "$user" == *"root"* ]] || [[ "$user" == "nobody" ]]; then
        return 1
    fi
    local home_dir=$(getent passwd "$user" | cut -d: -f6)
    if [[ -d "$home_dir" && "$home_dir" == "/home/"* ]]; then
        return 0
    fi
    return 1
}

# Enhanced user detection function
getting_username_function() {
    clear
    echo -e "${BBlue}╔════════════════════════════════════╗${Color_Off}"
    echo -e "${BBlue}║       User Selection Menu          ║${Color_Off}"
    echo -e "${BBlue}╚════════════════════════════════════╝${Color_Off}"
    echo

    # Get all valid users with home directories (excluding system users)
    mapfile -t users < <(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read user; do
        if filter_system_users "$user"; then
            echo "$user"
        fi
    done)

    user_count=${#users[@]}

    if [ "$user_count" -eq 0 ]; then
        echo -e "${BRed}No valid users found!${Color_Off}"
        exit 1
    elif [ "$user_count" -eq 1 ]; then
        username=${users[0]}
        echo -e "Single user detected: ${BGreen}$username${Color_Off}"
        echo
        echo -e "${UCyan}1) Use detected user: ${BGreen}$username${Color_Off}"
    else
        echo -e "${BYellow}Multiple users detected:${Color_Off}"
        for i in "${!users[@]}"; do
            echo -e "${UCyan}$((i+1))) ${BGreen}${users[$i]}${Color_Off}"
        done
    fi

    echo -e "${UYellow}$((user_count+1))) Enter different username${Color_Off}"
    echo -e "${UPurple}$((user_count+2))) Exit${Color_Off}"
    echo

    while true; do
        read -e -p "Select an option: " user_choice
        if [ "$user_choice" -le "$user_count" ] && [ "$user_choice" -gt 0 ]; then
            username=${users[$((user_choice-1))]}
            break
        elif [ "$user_choice" -eq $((user_count+1)) ]; then
            echo -e "Enter username:"
            read -r username
            if id "$username" &>/dev/null; then
                break
            else
                echo -e "${BRed}Invalid username! Please try again.${Color_Off}"
            fi
        elif [ "$user_choice" -eq $((user_count+2)) ]; then
            echo -e "${BYellow}Exiting...${Color_Off}"
            exit 0
        else
            echo -e "${BRed}Invalid choice! Please try again.${Color_Off}"
        fi
    done

    echo -e "${BGreen}Selected user: $username${Color_Off}"
    sleep 1
}

# Setup notifications function
setup_notifications() {
    if which notify-send >/dev/null; then
        use_libnotify=1
        use_kdialog=0
        echo -e "Using ${BBlue}libnotify${Color_Off} for notifications"
    elif which kdialog >/dev/null; then
        use_libnotify=0
        use_kdialog=1
        echo -e "Using ${BBlue}KDE${Color_Off} notification system"
    else
        echo -e "${BRed}No notification system found!${Color_Off}"
        return 1
    fi

    {
        echo '#!/bin/bash'
        echo 'export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${UID}/bus}"'

        if [ "$use_names" == "true" ]; then
            echo 'product=$(dmesg | grep Product | tail -1 | grep -o "Product:.*" | awk -F Product: '\''{print $2}'\'')'
            echo 'serial=$(dmesg | tail -n 4 | grep "tty" | tail -n 1 | grep -o '\''\\w*tty\\w*'\'' | tail -n 1)'

            if [ "$use_kdialog" == "1" ]; then
                echo 'kdialog --passivepopup " $product $1" 2'
            fi
            if [ "$use_libnotify" == "1" ]; then
                echo 'notify-send -t 2000 " $product $1" "$serial" --app-name "USB-Notify" --icon "/etc/sounds/usb2.png"'
            fi
        else
            if [ "$use_kdialog" == "1" ]; then
                echo 'kdialog --passivepopup "USB Device $1" 2'
            fi
            if [ "$use_libnotify" == "1" ]; then
                echo 'notify-send -t 2000 "USB Device $1" --app-name "USB-Notify" --icon "/etc/sounds/usb2.png"'
            fi
        fi
    } > /etc/sounds/notify.sh

    chmod +x /etc/sounds/notify.sh
}

# Installation function
install_function() {
    clear
    echo -e "${BBlue}╔════════════════════════════════════╗${Color_Off}"
    echo -e "${BBlue}║      Installing USB Sounds         ║${Color_Off}"
    echo -e "${BBlue}╚════════════════════════════════════╝${Color_Off}"
    echo

    if [ ! -d "/etc/sounds" ]; then
        echo "Creating /etc/sounds directory..."
        mkdir -p /etc/sounds
    fi

    echo "Copying sound files and icon..."
    cp USB-Remove.wav /etc/sounds/USB-Remove.wav
    cp USB-Insert.wav /etc/sounds/USB-Insert.wav
    cp usb2.png /etc/sounds/usb2.png

    echo "Creating systemd service files..."
    {
        echo '[Unit]'
        echo 'Description=Play USB sound'
        echo
        echo '[Service]'
        echo "User=$username"
        echo 'Type=oneshot'
        echo 'Environment="XDG_RUNTIME_DIR=/run/user/1000"'
        if [ "$install_notifications" == "1" ]; then
            echo 'ExecStartPre=/bin/bash /etc/sounds/notify.sh Connected'
        fi
        echo 'ExecStart=/usr/bin/aplay /etc/sounds/USB-Insert.wav'
        echo "Environment=\"DISPLAY=:0\" \"XAUTHORITY=/home/$username/.Xauthority\""
    } > /etc/systemd/system/usb-insert.service

    {
        echo '[Unit]'
        echo 'Description=Play USB sound'
        echo
        echo '[Service]'
        echo "User=$username"
        echo 'Type=oneshot'
        echo 'Environment="XDG_RUNTIME_DIR=/run/user/1000"'
        if [ "$install_notifications" == "1" ]; then
            echo 'ExecStartPre=/bin/bash /etc/sounds/notify.sh Disconnected'
        fi
        echo 'ExecStart=/usr/bin/aplay /etc/sounds/USB-Remove.wav'
        if [ "$install_notifications" == "1" ]; then
            echo "Environment=\"DISPLAY=:0\" \"XAUTHORITY=/home/$username/.Xauthority\""
        fi
    } > /etc/systemd/system/usb-remove.service

    echo "Creating udev rules..."
    {
        echo 'ACTION=="add", SUBSYSTEM=="usb", KERNEL=="*:1.0", RUN+="/bin/systemctl start usb-insert"'
        echo 'ACTION=="remove", SUBSYSTEM=="usb", KERNEL=="*:1.0", RUN+="/bin/systemctl start usb-remove"'
    } > /etc/udev/rules.d/100-usb.rules

    if [ "$install_notifications" == "1" ]; then
        echo "Setting up notifications..."
        setup_notifications
    fi

    echo "Reloading systemd and udev..."
    systemctl daemon-reload
    systemctl restart systemd-udevd

    echo
    echo -e "${BGreen}Installation completed successfully!${Color_Off}"
    echo -e "${BYellow}Plug in a USB device to test the sounds.${Color_Off}"
    echo
}

# Uninstall function
uninstall_function() {
    clear
    echo -e "${BBlue}╔════════════════════════════════════╗${Color_Off}"
    echo -e "${BBlue}║      Uninstalling USB Sounds       ║${Color_Off}"
    echo -e "${BBlue}╚════════════════════════════════════╝${Color_Off}"
    echo

    echo "Removing service files..."
    rm -f /etc/systemd/system/usb-remove.service
    rm -f /etc/systemd/system/usb-insert.service

    echo "Removing udev rules..."
    rm -f /etc/udev/rules.d/100-usb.rules

    echo "Removing notification script..."
    rm -f /etc/sounds/notify.sh

    echo "Reloading systemd and udev..."
    systemctl daemon-reload
    systemctl restart systemd-udevd

    echo
    echo -e "${BGreen}Uninstallation completed successfully!${Color_Off}"
    echo
}

# Main menu function
show_main_menu() {
    clear
    echo -e "${BBlue}╔════════════════════════════════════╗${Color_Off}"
    echo -e "${BBlue}║    USB Sound Installation Menu     ║${Color_Off}"
    echo -e "${BBlue}╚════════════════════════════════════╝${Color_Off}"
    echo

    if ! check_dmesg_access; then
        echo -e "\n${BRed}Notice: dmesg access is restricted${Color_Off}"
        echo -e "${Yellow}This will affect USB device name detection${Color_Off}"
        echo -e "${UCyan}D) Enable dmesg access for all users${Color_Off}"
        echo
    else
        echo -e "\n${BGreen}dmesg access is enabled${Color_Off}"
        echo -e "${UCyan}D) Disable dmesg access${Color_Off}"
        echo
    fi

    check_dependencies
    echo

    echo -e "Choose an installation option:"
    echo
    if [ "$visuals" == "1" ]; then
        echo -e "${BYellow}1) Install USB sounds with notifications${Color_Off}"
        echo -e "${BBlue}2) Install USB sounds only${Color_Off}"
        echo -e "${BRed}3) Uninstall USB sounds${Color_Off}"
        echo -e "${UPurple}4) Exit${Color_Off}"
    else
        echo -e "${BBlue}1) Install USB sounds only${Color_Off}"
        echo -e "${BRed}2) Uninstall USB sounds${Color_Off}"
        echo -e "${UPurple}3) Exit${Color_Off}"
    fi
    echo

    while true; do
        read -e -p "Select an option: " -i "1" choice
        case $choice in
            [dD])
                if ! check_dmesg_access; then
                    echo -e "${BGreen}Enabling dmesg access for all users...${Color_Off}"
                    fix_dmesg_access
                else
                    echo -e "${BYellow}Disabling dmesg access...${Color_Off}"
                    disable_dmesg_access
                fi
                show_main_menu
                break
                ;;
            1)
                if [ "$visuals" == "1" ]; then
                    install_notifications=1
                else
                    install_notifications=0
                fi
                getting_username_function
                install_function
                break
                ;;
            2)
                if [ "$visuals" == "1" ]; then
                    install_notifications=0
                    getting_username_function
                    install_function
                else
                    uninstall_function
                fi
                break
                ;;
            3)
                if [ "$visuals" == "1" ]; then
                    uninstall_function
                else
                    echo -e "${BYellow}Exiting...${Color_Off}"
                    exit 0
                fi
                break
                ;;
            4)
                if [ "$visuals" == "1" ]; then
                    echo -e "${BYellow}Exiting...${Color_Off}"
                    exit 0
                else
                    echo -e "${BRed}Invalid option! Please try again.${Color_Off}"
                fi
                break
                ;;
            *)
                echo -e "${BRed}Invalid option! Please try again.${Color_Off}"
                ;;
        esac
    done
}

# Check root access
if (( $EUID != 0 )); then
    echo -e "${BRed}Please run as root${Color_Off}"
    exit 1
fi

# Start the script
show_main_menu

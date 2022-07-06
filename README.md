**The story**
I cannot believe that desktop enviroments don't put much accent to this. Having a sound and a notification when you insert a USB device is a basic OS functionality.
I have proposed this to the KDE devs ( Desktop Enviroment of my choice) many times!
So, in the end, I have deciced to make it myself. 

**How to install**

Download the content of this repository with either git or a manual download.

The git way:

`git clone https://github.com/lolren/USB-Notification-Linux`

`cd USB-Notification-Linux/`

`sudo chmod +x USB-Notification-Installer.sh`

`sudo ./USB-Notification-Installer.sh`

Then Follow the Menu!
N'joy!

***Requirements ***

This script require a system running **Systemd**
**aplay** is also required for playing sounds
**libnotify** or **libnotify-bin** if you want a notification when you insert/remove a USB device
Other than that should be distro/release agnostic.

**If you want your own sound files, just replace the two .WAV files with your own**. 


Tested on KDE Neon Distro
Should work on every systemd distro
The 2 sounds used are from https://invent.kde.org/raploz/blue-ocean-sound-theme , made by Guilherme Marçal Silva.

If you want your own sound files, just replace the 2 .WAV files with your own. 

P.S. I am a terrible coder. But what I write, usually works. Any improvements are welcome.
![This is an image](https://preview.redd.it/6ihfuz3c6q251.jpg?width=640&crop=smart&auto=webp&s=dad5b7caaaf0ed82425997bfc731433fa155ec9e)

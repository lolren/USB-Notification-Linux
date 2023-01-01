**The story**
I cannot believe that desktop enviroments don't put much accent to this. Having a sound and a notification when you insert a USB device is a basic OS functionality.
I have proposed this to the KDE devs ( Desktop Enviroment of my choice) many times!
So, in the end, I have deciced to make it myself. 




**NEW!!!!**

Now the script support USB names!
This is very handy!.
Be sure your distro supoorts dmesg without root acces ( without sudo). If not, edit the script and 




**How to install**

Download the content of this repository with either git or a manual download.

The git way:

`git clone https://github.com/lolren/USB-Notification-Linux`

`cd USB-Notification-Linux/`

`sudo chmod +x USB-Notification-Installer.sh`

`sudo ./USB-Notification-Installer.sh`

If you want to get devices names, ensure the dmesg command works without sudo. if it doesn't, set fix_dmesg_for_users="false" to fix_dmesg_for_users="true" 

Then Follow the Menu!
N'joy!

***Requirements ***

This script require a system running **Systemd**.
**Aplay** is also required for playing sounds.
Also, use **libnotify** or **libnotify-bin** if you want a notification when you insert/remove a USB device and you don't use KDE.
Other than that, this script should be distro/release agnostic.

**If you want your own sound files, just replace the two .WAV files with your own**. 


Tested on KDE Neon Distro
Should work on every systemd distro
The 2 sounds used are from https://invent.kde.org/raploz/blue-ocean-sound-theme , made by Guilherme Marçal Silva.

P.S. I am a terrible coder. But what I write, usually does the job. Any improvements are welcome.
![This is an image](https://preview.redd.it/6ihfuz3c6q251.jpg?width=640&crop=smart&auto=webp&s=dad5b7caaaf0ed82425997bfc731433fa155ec9e)

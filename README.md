# setup.sh
sudo apt install git -y

git clone https://github.com/laalaaala/setup.git
#
chmod +x setup.sh

sudo ./setup.sh

#
#Überprüfung
ls -l /home/pi/.config/openbox/autostart

ls -l /home/pi/start_chromium.sh

ls -l /etc/hostapd/hostapd.conf

ls -l /etc/dhcpcd.conf

ls -l /etc/dnsmasq.conf

ls -l /etc/X11/xorg.conf.d/10-monitor.conf

ls -l /etc/rc.local

ls -l /etc/systemd/system/hostapd-restart.service


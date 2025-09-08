# NUT client setup
This will listen for callouts from the nut server that tells the status off the ups battery, if power is down, the nut server will tell the clients this and the clients then decidce to shutdown

1. install nut client: `apt install nut-client`
2. change `/etc/nut/nut.conf`, `/etc/nut/upsmon.conf` and `/etc/nut/upssched.conf` according to the files in nut dir. Make sure to change password to correct slave password for user upsremote in `/etc/nut/upsmon.conf`
3. Create a new file called: `/etc/nut/upssched-cmd`, put the contents from nut/upssched-cmd in it
4. Make it executable: `chmod +x /etc/nut/upssched-cmd`
5. Restart nut-client with `systemctl restart nut-client`
6. Check status with `systemctl status nut-client` It should say something like: `UPS: ups@192.168.20.70 (secondary) (power value 1)`
Techno tim guide: https://technotim.live/posts/NUT-server-guide/
hardware haven: https://www.youtube.com/embed/dXSbURqdPfI

1. run `sudo apt install nut`

2. copy the contents of the files in nut dir to etc/nut (makesure to edit upsd.users amd upsmon.conf and set the password) (You can remove a hole line in nano with ctrl + k)

3. start nut by running `sudo systemctl enable nut-server nut-monitor` and `sudo systemctl start nut-server nut-monitor`

4. reboot

5. Test if ups is setup correctly by running `upsc ups` This should show alot of stats like this:
````
Init SSL without certificate database
battery.charge: 100
battery.charge.low: 0
battery.charge.warning: 20
battery.mfr.date: 1 
battery.runtime: 7860
...
..
.
````

1. Make sure to setup the nut clients on the other devices
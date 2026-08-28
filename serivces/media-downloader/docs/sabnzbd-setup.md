1. Start conatiner (sudo docker compose up -d)
2. Open config file config/sabnzbd.ini
3. Set host_whitelist=sabnzbd.local.jabbas.dev
4. Reboot containers
5. Go to https://sabnzbd.local.jabbas.dev and follow the wizzard.
6. Continue setup according to [Trash guides](https://trash-guides.info/Downloaders/SABnzbd/Basic-Setup/)
7. Click on the [General config page](https://sabnzbd.local.jabbas.dev/config/general/) and in the "Tuning" settings set "Maximum line speed" to 15 MB/s (This is beacuse I have 250Mbit/s internet connection and want it to still be usable, I would say to cap it to max internet connections speed - 10MB or something)
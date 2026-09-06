1. Deploy the stack from Dockhand.
2. Open SABnzbd **by IP** the first time: `http://10.0.20.80:8080`. SABnzbd's hostname verification
   always allows direct-IP access, so the wizard works before the Traefik hostname is whitelisted.
3. Follow the wizzard and add the usenet provider credentials.
4. Go to Config -> Specials and add `sabnzbd.local.jabbas.dev` to `host_whitelist`, then save.
   Entries must be lowercase. Without this Traefik forwards `Host: sabnzbd.local.jabbas.dev` and
   SABnzbd answers `Access denied - Hostname verification failed`.
5. https://sabnzbd.local.jabbas.dev now works. Continue setup according to
   [Trash guides](https://trash-guides.info/Downloaders/SABnzbd/Basic-Setup/)
6. Go to Config -> Folders and set the container paths (`/mnt/data/usenet` on the host):
   - Temporary Download Folder: `/data/usenet/incomplete`
   - Completed Download Folder: `/data/usenet/complete`
7. Click on the [General config page](https://sabnzbd.local.jabbas.dev/config/general/) and in the "Tuning" settings set "Maximum line speed" to 100 MB/s (This is beacuse I have 1000Mbit/s internet connection and want it to still be usable, I would say to cap it to max internet connections speed - 100Mbit or something)

`/config` is the named Docker volume `sabnzbd_config`, not a bind mount, so there is no
`config/sabnzbd.ini` path on the host. Everything above is doable from the UI. If you ever do need
the file directly it is `/config/sabnzbd.ini` inside the container — stop the container first, since
SABnzbd rewrites the file on shutdown and would overwrite the edit.

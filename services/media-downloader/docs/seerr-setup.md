In the setuop screen it will say that `The /app/config volume mount was not configured properly. All data will be cleared when the container is stopped or restarted.` This is not true and can be disregarded beacuse we use docker volumes and the app does not know that.

1. Inital setup
   1. Select "Confighure Jellyfin"
   2. Put in "jellyfin.local.jabbas.dev" in Jellyfin URL and check "Use SSL"
   3. Leave "URL Base" empty
   4. Put in any email adress
   5. Put in Jellyfin username
   6. Put in Jellyfin password
   7. Click "Continue"
   8. Click "Sync Libraries" and check both Movies and Shows
   9. Click "Start Scan"
   10. Click "Continue"
   11. Add Radarr and Sonarr servers. Seerr is **not** in the gluetun namespace, so `localhos` doesnot reach them. Use local domain names:
    - Radarr: radarr.local.jabbas.dev, port: 443, SSL: check
    - Sonarr: sonarr.local.jabbas.dev, port: 443, SSL: check

       Leave SSL unchecked for both. Set the root folder to `/data/media/movies` for Radarr and
       `/data/media/tv` for Sonarr, and pick the quality profile Recyclarr created.

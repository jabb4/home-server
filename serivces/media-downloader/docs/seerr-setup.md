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
   11. Add Radarr and Sonarr servers. Seerr is **not** in the gluetun namespace, so `localhost` does
       not reach them — use the host IP (see
       [Networking](../README.md#networking--which-url-to-use-where)):
       - Radarr: hostname `10.0.20.80`, port `7878`
       - Sonarr: hostname `10.0.20.80`, port `8989`

       Leave SSL unchecked for both. Set the root folder to `/data/media/movies` for Radarr and
       `/data/media/tv` for Sonarr, and pick the quality profile Recyclarr created.

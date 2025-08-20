1. Initial setup
   1. Select English for language
   2. set username and password
   3. Click on "Add Media Library"
      1. Set "Content type" to "Movies"
      2. Click "+" next to Folders and set to /data/movies
      3. Click on "OK"
   4. Click on "Add Media Library" again
      1. Set "Content type" to "Shows"
      2. Click "+" next to Folders and set to /data/tvshows
      3. Click on "OK"
   5. Click "Next"
   6. Select English and United States for Metadat Language and press "Next"
   7. Check "Allow remote connections to this server" and dont check "Enable automatic port mapping"
   8. Click "Next"
   9. Click "Finish"

2.  Plugins
    1.  Go to [Dashboard -> Catalouge (Plugins)](https://jellyfin.local.jabbas.dev/web/index.html#/dashboard/plugins/catalog)
    2.  Click on the cogg in the top left corner
    3.  Click on the "+"
    4.  Set repository name to "Intro Skipper" and Repository URL to https://intro-skipper.org/manifest.json
    5.  Click "Save" and "Ok"
    6.  Go back to Catalouge section
    7. Install plugins:
       1. Intro Skipper
       2. TheTVDB
    8. Restart Jellyfin
    9. Go to [Dashboard -> My Plugins](https://jellyfin.local.jabbas.dev/web/index.html#/dashboard/plugins)
    10. Click on "TheTVDB" and check "Update Series", "Update Season", "Update Episode", "Update Movie", "Update Person" at the button
    11. Click "Save"
    12. Go to [Dashboard -> Libraries](https://jellyfin.local.jabbas.dev/web/index.html#/dashboard/libraries)
    13. For both Movies and Shows do:
        1.  Scroll to "Metadata downloaders"
        2.  Check "TheTVDB" and make sure its at the top of the list
        3.  Scroll to "Image fetchers"
        4.  Check "TheTVDB" and make sure its at the top of the list
        5.  If there are any other metadata settings, enable TheTVDB and put it in the top.
    14. Restart Jellyfin
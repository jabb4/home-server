1. Enable authentication and put in username and password.
2. Add indexer NZBgeek, altHUB, drunkenslug, ninjacentral 
3. Add Radarr and Sonarr in the Settings -> Apps section. Use the shared gluetun namespace, not the
   Traefik hostnames
   - Radarr: `http://localhost:7878`
   - Sonarr: `http://localhost:8989`

   The API key for each comes from the env

# ForwardAuth with Traefik & Authentik

This guide explains how to set up **Authentik** with **Forward Authentication** for services using **Traefik**.

- This guide has been updated and test for **Authentik** version `2025.6.4` and **Traefik** version `3.5`

---
## 1. Initial Authentik setup

### 1. Setup inital admin account
1. Go to `http://<your server's IP or hostname>:9000/if/flow/initial-setup/`
2. Put in email: `admin@authentik.me` (or whatever mail you want)
3. Put in a good password

### 2. Create new admin account
1. Go to **Authentik Admin interface**
2. In the sidbar, go to:   
   Directory → Users
3. Click on "Create"
4. Put in username
5. User type: Internal
6. Click "Create"
7. Click on the new user and under recover click **"Set password"**
8. Fill in the password and click **"Update password"**
9. In the topbar of the new user, click on **"Groups"**
10. Click **"Add to existing group"**
11. Click the + button and select "authentik Admins" group and click "Add"
12. Click "Add"
13. Sign out from authentik and in to your new account.
14. In the **User interface** go to settings (the cogg)
15. Click on MFA Devices and add your MFA Device
16. Go to **Authentik Admin interface**
17. In the sidbar, go to:   
   Directory → Users
18. Click on "akadmin"
19. Under: "User info" - Actions, click on "Deactivate" and "Update"

### 3. Extend Authentik sessions time
- [Authentik Docs](https://docs.goauthentik.io/docs/flow/stages/user_login/)
1. Go to **Authentik Admin interface**
2. In the sidbar, go to:   
   Flows and Stages → Stages
3. Edit **default-authentication-login**
4. Set **Session duration** field to `weeks=4`
5. Click **Update**

### 4. Configure the Authentik Embedded Outpost

1. Go to:  
   Applications → Outposts  
2. Click Edit on the Embedded Outpost.  
3. Open Advanced Settings.  
4. Ensure the following is set:  
   authentik_host: https://auth.local.jabbas.dev  
5. Click Update.

---

## 2. Add a Forward Auth Application

### Step 1 — Create Traefik Middleware + config

In your Traefik configuration (config.yml), add a middleware for forward authentication:
- This is how i needs to look like and make sure that Traefik and authentik-server is on the same docker network

````
http:  
   middlewares:  
    forwardAuth-authentik:
      forwardAuth:
        address: "http://authentik-server:9000/outpost.goauthentik.io/auth/traefik"
        trustForwardHeader: true
        authResponseHeaders:
          - X-authentik-username
          - X-authentik-groups
          - X-authentik-entitlements
          - X-authentik-email
          - X-authentik-name
          - X-authentik-uid
          - X-authentik-jwt
          - X-authentik-meta-jwks
          - X-authentik-meta-outpost
          - X-authentik-meta-provider
          - X-authentik-meta-app
          - X-authentik-meta-version
````

You also need to add the middleware to your routes in trafiks `config.yml` or as docker lables.

- **Example for routes in config.yml:**  
  -  Add **forwardAuth-authentik** in the middlewares
  ````
  http:
  routers:
    <service>:
      entryPoints:
        - "https"
      rule: "Host(`<service>.local.jabbas.dev`)"
      middlewares:
        - disallow-iframe-embedding
        - default-headers
        - https-redirectscheme
        - forwardAuth-authentik
      tls: {}
      service: <service>
  ````
- **Example with docker lables:**  
  -  Add **forwardAuth-authentik** in the middlewares
  ````
  labels:
      - "traefik.http.routers.<service>.middlewares=forwardAuth-authentik@file"
  ````

---

### Step 2 — Create Application & Provider in Authentik

1. In **Authentik**, go to:   
   Applications → Applications and click Create with Provider. 
2. Fill in the details: 
   - Application Name: Service name (e.g. Sonarr)  
   - Slug: Service name (e.g. sonarr)  
3. Create a Provider for the application: 
   - Provider Type: Proxy Provider  
   - Provider Name: Provider for \<service\> (e.g. Provider for sonarr)  
   - Authorization Flow: default-provider-authorization-implicit-consent  
   - Forward Auth Type: Forward Auth (Single Application)   
   - External Host: https://\<service\>.local.jabbas.dev 

---

#### Optional Settings

If the service needs unauthenticated API access (e.g., for homepage dashboards):  
- Go to Advanced Protocol Settings → Unauthenticated Paths  
- Add paths (one per line), e.g.:  
  ^/api/.*

If the service supports HTTP Basic Auth:  
- Go to Authentication Settings:  
  - Enable Send HTTP-Basic Authentication  
  - HTTP-Basic Username Key: <service>_username  
  - HTTP-Basic Password Key: <service>_password  

---

### Step 3 — Finishing up
1. Click "Next"
2. Click "Next"
3. Click "Submit"

---

### Step 4 (If using basic auth) — Create an Access Group

1. Go to: Directory → Groups → Create 
2. Name it: \<service\>_access  
3. Under Attributes, add:  
   \<service\>_username: \<basic_auth_username\>  
   \<service\>_password: \<basic_auth_password\>  
4. Click "Create Group"
5. Open the newly created group:  
   - Go to Users → Add Existing User  
   - Add users who should have access.  

---

### Step 5 — Link the Application to the Outpost

1. Go to: Applications → Outposts  
2. Edit the "authentik Embedded Outpost"  
3. In the "Applications" section double click on the newly created application in the "Available Applications" list. This should move it to the "Selected Applications" list.
4. Click "Update"

---

✅ Setup complete!  
Your new service is now protected with ForwardAuth via Authentik and Traefik.

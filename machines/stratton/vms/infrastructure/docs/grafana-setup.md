# How to setup Grafana
1. Start container wite rootless docker: `docker compose up -d`
2. Go to https://grafana.local.jabbas.dev/login and login with default credentials: 
   ````
   username=admin
   password=admin
   ````
3. Set a strong admin password (you will automaticly be prompted for this)
4. Import dashboard by going to https://grafana.local.jabbas.dev/dashboard/import Copy & paste the contents of `homeserverstats.json` in to "Import via dashboard JSON model" text box
5. Click on **"Load"** button and then **"Import button"**

## Connect data source
1. Make sure prometheus container is running
1. In the sidepanel navigate to:
   [Connections -> Data sources](https://grafana.local.jabbas.dev/connections/datasources/new)
2. Find **"Prometheus"** and click on it
3. Name it `prometheus`
4. In the connection add the prometheus url: https://prometheus.local.jabbas.dev
5. Scroll to the button and click **"Save & test"**
6. Go to your dashboard and then, on your all your "cards" you have to click on the three dots -> Edit & click **"Run queries"**¨
7. In the top right corner click on **"Save dashboard"**
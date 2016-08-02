# Let's Encrypt for Nginx on Ubuntu

## Prerequisities

```sh
sudo apt-get update
sudo apt-get install git bc
sudo git clone https://github.com/certbot/certbot /opt/certbot
```

## Add new host

### Without proxy_pass

1. `sudo nano /etc/nginx/sites-available/myhost.com`

  Add following to your `server{}` block

  ```
  location ~ /.well-known {
    allow all;
  }
  ```

2. Reload nginx conf with `sudo service nginx reload`

3. Request a certificate with 
`/opt/certbot/certbot-auto certonly -a webroot --w=/home/myhost/public -d www.myhost.com -d myhost.com`

4. Add your e-mail to the prompt and agree to the terms (first time only)

### With proxy_pass

If you are using proxy_pass we can't just create files in the root, because there is no root. For this we need to create a dummy root.

1. Create a dummy directory for the response files

  ```
  sudo mkdir -p /var/www/proxypass/myhost.com
  ```

2. Add the dummy directory

  ```
  location ~ /.well-known {
    allow all;
    root /var/www/proxypass/myhost.com;
  }
  ```

3. Reload nginx conf with `sudo service nginx reload`

4. Now you can generate a cert with 
`/opt/certbot/certbot-auto certonly -a webroot -w=/var/www/proxypass/myhost.com -d www.myhost.com -d myhost.com`

### Use the issued certificate

1. `sudo nano /etc/nginx/sites-available/myhost.com`

  Make your server block look something like this to use the generated certificates

  ```
  server {
    listen 80; # Redirect all port 80 traffic to https
    server_name myhost.com www.myhost.com;
    return 301 https://$host$request_uri;
  }
  server {
    listen 0.0.0.0:443 ssl;
    listen [::]:443 ipv6only=on ssl default_server;
    server_name myhost.com www.myhost.com;
    server_tokens off;
    root /home/myhost/public;

    location ~ /.well-known {
      allow all;
    }

    ssl on;
    ssl_certificate /etc/letsencrypt/live/myhost.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myhost.com/privkey.pem;
  }
  ```

2. Reload nginx conf again with `sudo service nginx reload`

## Auto renew

Open up crontab `sudo crontab -e` and add the following

```
# Let's Encrypt refresh
27 */12 * * * /opt/certbot/certbot-auto renew --quiet --no-self-upgrade >> /var/log/letsencrypt-crontab.log
32 */12 * * * /etc/init.d/nginx reload
```

This will renew certificates two times a day (00:27 and 12:27) and then reload the nginx configuration 5 minutes later. 

From the documentation:

> If you're setting up a cron or systemd job, we recommend running it twice per day (it won't do anything until your certificates are due for renewal or revoked, but running it regularly would give your site a chance of staying online in case a Let's Encrypt-initiated revocation happened for some reason). Please select a random minute within the hour for your renewal tasks.

## More reading
* [Let's encrypt](https://letsencrypt.org/)
* [Certbot documentation](https://certbot.eff.org/docs/)
* [Strong SSL Security on nginx](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html)

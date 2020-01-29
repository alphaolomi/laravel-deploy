# Steps to deploy Laravel apps

Assuming you have setup LEMP stack alreeady if not see https://github.com/alphaolomi/yai

> DISLAIMER: .....


## Step 1 — Installing Required PHP modules

```bash
sudo apt update
sudo apt install php-cli php-mbstring php-xml php-bcmath php-mysql composer unzip curl git
```

## Step 2 — Creating a Database for the Application
```bash
sudo useradd cooluser
passwd cooluser
```


```bash
sudo mysql
```

```sql
-- cerate db
CREATE DATABASE coolapp;

-- create user
CREATE USER 'cooluser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON coolapp.* TO 'cooluser'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
exit
```

```bash
mysql -u cooluser -p
# password
SHOW DATABASES;
exit
```

## Step 3 — Creating a New Laravel Application


```bash
cd ~
git clone https://github.com/alphaolomi/coolapp.git
cd coolapp
composer install --optimize-autoloader
php artisan


cp .env.example .env
php artisan key:generate

php artisan config:cache
php artisan route:cache
nano .env
php artisan migrate
```

Update .env

```env
APP_ENV=production
APP_DEBUG=false
APP_KEY=b809vCwvtawRbsG0BmP1tWgnlXQypSKf
APP_URL=http://192.168.##.##

DB_HOST=127.0.0.1
DB_DATABASE=coolapp
DB_USERNAME=coolapp
DB_PASSWORD=pAsSwOrD123
```


move the application
```bash
sudo mv ~/coolapp /var/www/coolapp
```

give permission for logs and storage
```bash
# use this
sudo chown -R www-data:www-data /var/www/coolapp/storage
sudo chown -R www-data.www-data /var/www/coolapp/bootstrap/cache
```

```bash
sudo nano /etc/nginx/sites-available/coolapp-web

# root  /var/www/html/coolapp/public;
# server_name 192.168.###.###

sudo ln -s /etc/nginx/sites-available/coolapp-web /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Happy Hacking :)
#/bin/bash

APP_REPO=git@github.com:alphaolomi/wazo.git
APP_NAME=DEMO
APP_NAME_SHORT=demo
APP_ENV=production
APP_DEBUG=false
APP_URL=http://ip
DB_DATABASE=demo_db
DB_USERNAME=laravel
DB_PASSWORD=laravel

SYS_USER_NAME=demo_user
SYS_USER_PASS=demo_pass

echo "[+] Step 1 — Installing Required PHP modules"
echo ""
echo "- upadting system.."
sudo apt update
echo "- Installing php deps..."
sudo apt install php-cli php-mbstring php-xml php-bcmath php-mysql composer unzip curl git
echo ""

echo "[+] Step 2 — Creating a New User"
echo ""
echo "- quietly adding a user without password.."
adduser --quiet --disabled-password --shell /bin/bash --home /home/$SYS_USER_NAME --gecos "Alpha" $SYS_USER_NAME
echo  "- setting password..."
echo "$SYS_USER_NAME:$SYS_USER_PASS" | chpasswd
echo ""


echo "[+] Step 2 — Creating a Database for the Application"
echo ""
echo "- creating databse: $DB_DATABASE"
sudo sh -c "sudo mysql -e \"CREATE DATABASE $DB_DATABASE;\""
echo "- granting all permission to: $DB_USER"
sudo sh -c "sudo mysql -e \"GRANT ALL ON $DB_DATABASE.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;\""
echo ""


echo "[+] Step - Adding a public SSH key to the authenticated user's GitHub account. "
echo ""
GITHUB_TOKEN=2cfbc35fded94c58451c93f9102d7a4fa69e415b
APP_NAME_SHORT=demo
KEY_TITLE="$APP_NAME_SHORT\@$SUDO_USER\@HOSTNAME"
echo "key comment : $KEY_TITLE"
echo "- generating key..."
yes y | ssh-keygen -q -t rsa -N '' -b 4096 -C $KEY_TITLE >/dev/null

# check if key exist
ssh-add ~/.ssh/id_rsa
echo "- loading key..."
PUB_KEY=$(</home/alpha/.ssh/id_rsa.pub)
echo "- uploading key ot github..."
curl -X POST -u $GITHUB_TOKEN:x-oauth-basic -H 'Content-Type: application/json' -d '{"title": "$KEY_TITLE","key": "$PUB_KEY"}' https://api.github.com/user/keys
echo ""


echo "[+] Step 3 — Creating a New Laravel Application"
echo ""
cd ~
echo "- cloning repo to $APP_NAME_SHORT"
git clone $APP_REPO $APP_NAME_SHORT
cd $APP_NAME_SHORT
composer install --optimize-autoloader


echo "- create envs"
cat > ./.env <<EOF
APP_NAME=$APP_NAME
APP_ENV=$APP_ENV
APP_KEY=
APP_DEBUG=$APP_DEBUG
APP_URL=$APP_URL

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=$DB_DATABASE
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
EOF

echo "- generating new app key"
php artisan key:generate

echo "- clearing config cache... "
php artisan config:clear

echo "- migrating databse..."
php artisan migrate > /home/alpha/migration.log

echo "[+] Step 5 MOVE"
echo ""
echo "- moving app to /opt/www/"
sudo mv ~/$APP_NAME_SHORT /var/www/$APP_NAME_SHORT
sleep 2
echo "- upadting permissions for www-data"
sudo chown -R www-data.www-data /var/www/$APP_NAME_SHORT/storage
sudo chown -R www-data.www-data /var/www/$APP_NAME_SHORT/bootstrap/cache

echo "[+] Step 6 — Setting Up Nginx"
echo ""

echo "- creating a new virtual host configuration for $APP_NAME_SHORT"
cat > /etc/nginx/sites-available/$APP_NAME_SHORT <<EOF
server {
    listen 80;
    server_name $APP_URL;
    root /var/www/$APP_NAME_SHORT/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

echo "- creating a symbolic link to $APP_NAME_SHORT in sites-enabled:"
sudo ln -s /etc/nginx/sites-available/$APP_NAME_SHORT /etc/nginx/sites-enabled/

echo "- confirming that the configuration doesn’t contain any syntax errors"
sudo nginx -t;

echo "- applying changes and reloading Nginx Serive"
sudo systemctl reload nginx;

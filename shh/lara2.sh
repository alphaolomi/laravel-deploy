#!/bin/bash
# Laravel Installer for Debian
# Author: Alpha Olomi <hello@alphaolomi.com>
# Version: 0.0.1-beta
set -e

cat << 'EOF'
    _                              _   ___           _        _ _
   | |    __ _ _ __ __ ___   _____| | |_ _|_ __  ___| |_ __ _| | | ___ _ __
   | |   / _` | '__/ _` \ \ / / _ \ |  | || '_ \/ __| __/ _` | | |/ _ \ '__|
   | |__| (_| | | | (_| |\ V /  __/ |  | || | | \__ \ || (_| | | |  __/ |
   |_____\__,_|_|  \__,_| \_/ \___|_| |___|_| |_|___/\__\__,_|_|_|\___|_|
                                                        Author: C0d3r
EOF
echo ""
printf "\tLaravel Installer for Debian\n"
printf "\t Version 0.0.1-beta\n"
echo ""
echo ""
echo "[+] Step 0 - init"
if [ "$EUID" -ne 0 ]
  then echo "! Please run as root"
  exit
fi

APP_REPO=git@github.com:alphaolomi/ucsaf.git
APP_NAME=UCSAF
APP_NAME_SHORT=ucsaf
APP_ENV=production
APP_DEBUG=false
APP_URL=http://139.59.16.184
DB_DATABASE=${APP_NAME_SHORT}_db
DB_USERNAME=${APP_NAME_SHORT}_user
DB_PASSWORD="$(openssl rand -base64 12)"

SYS_USER_NAME=${APP_NAME_SHORT}_user
SYS_USER_PASS="$(openssl rand -base64 12)"

echo "Project: $APP_REPO"
echo ""
echo "User: $SYS_USER_NAME"
echo "Pass: $SYS_USER_PASS"
echo ""
echo "User: $DB_USERNAME"
echo "User: $DB_PASSWORD"
echo ""
echo ""

echo "- save info to txt files"
echo "Project: $APP_REPO" >> app.txt
echo "" >> app.txt
echo "User: $SYS_USER_NAME" >> app.txt
echo "Pass: $SYS_USER_PASS" >> app.txt
echo "" >> app.txt
echo "User: $DB_USERNAME" >> app.txt
echo "User: $DB_PASSWORD" >> app.txt
echo "" >> app.txt
echo "" >> app.txt

echo "[+] Step 1 — Installing Required PHP modules"
echo ""
echo "- upadating system..."
sudo apt update
echo "- installing php deps..."
sudo apt install php-cli php-mbstring php-xml php-bcmath php-mysql -y
echo "- installing composer unzip curl git..."
sudo apt install composer unzip curl git -y
echo ""


echo "[+] Step 2 — Creating a New User"
echo ""
if ! id -u $SYS_USER_NAME > /dev/null 2>&1; then
    echo "! $SYS_USER_NAME user does not exist"
    echo "- creating sys user : $SYS_USER_NAME ..."
    adduser --quiet --disabled-password --shell /bin/bash --home /home/$SYS_USER_NAME --gecos "Alpha" $SYS_USER_NAME
    echo  "- setting password..."
    echo "$SYS_USER_NAME:$SYS_USER_PASS" | chpasswd
    echo ""
fi

echo "[+] Step 2 — Creating a Database for the Application"
echo ""
echo "- creating databse: $DB_DATABASE"
sudo sh -c "sudo mysql -e \"DROP DATABASE IF EXISTS $DB_DATABASE;CREATE DATABASE $DB_DATABASE;\""

echo "- creating db_User: $DB_USERNAME"
sudo sh -c "sudo mysql -e \"DROP USER IF EXISTS $DB_USERNAME; CREATE USER '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD';\""

echo "- granting all permission to: $DB_USERNAME"
sudo sh -c "sudo mysql -e \"GRANT ALL ON $DB_DATABASE.* TO '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;\""
echo "- flush privileges"
sudo sh -c "sudo mysql -e \"FLUSH PRIVILEGES;\""
echo ""


echo "[+] Step - Adding a public SSH key to the authenticated user's GitHub account."
echo ""
GITHUB_TOKEN=
KEY_TITLE="$APP_NAME_SHORT@$HOSTNAME"
echo "key comment : $KEY_TITLE"
echo ""



if [ ! -d ~/.ssh ]; then
   mkdir -p ~/.ssh/
fi


# Check for existence of passphrase
if [ ! -f ~/.ssh/id_rsa.pub ]; then
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        echo "- executing ssh-keygen --[done]"
fi

if [ ! -f ~/.ssh/authorized_keys ]; then
        touch ~/.ssh/authorized_keys
        echo "- creating ~/.ssh/authorized_keys --[done]"        
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        echo "- appending the public keys id_rsa into authorized keys --[done]"        
fi


if [ ! -f ~/.ssh/config ]; then
        touch ~/.ssh/config
        echo "Host github.com" > ~/.ssh/config
        echo "StrictHostKeyChecking no" >> ~/.ssh/config
        echo "- diabling StrictHostKeyChecking no --[done]"        
fi

echo ""
echo "- starting shh-agent and adding key..."
ssh-agent sh -c 'ssh-add ~/.ssh/id_rsa'
echo "- loading key --[done]..."
PUB_KEY=$(<~/.ssh/id_rsa.pub)
echo "- uploading key to github..."
curl -X POST -u $GITHUB_TOKEN:x-oauth-basic -H 'Content-Type: application/json' -d "{\"title\": \"$KEY_TITLE\",\"key\": \"$PUB_KEY\"}" https://api.github.com/user/keys
echo ""
echo "- done with ssh"


echo "[+] Step 3 — Creating a New Laravel Application"
echo ""
cd ~
echo "- cloning repo to $APP_NAME_SHORT"
sudo rm -rf $APP_NAME_SHORT
git clone $APP_REPO $APP_NAME_SHORT
cd $APP_NAME_SHORT
composer install --optimize-autoloader

cd $APP_NAME_SHORT
echo "- creating .env"
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

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

MIX_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
MIX_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"
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
sudo rm -rf /var/www/$APP_NAME_SHORT
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
        try_files \$uri \$uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /$realpath_root\$fastcgi_script_name;
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

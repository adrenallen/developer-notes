#!/bin/bash
set -e

# 🌈 Colors for our beautiful chaos
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color (boring)

PROGRESS_FILE=".setup-progress"
VARS_FILE=".setup-vars"

# Create files if they don't exist (they probably don't, you slacker)
touch "$PROGRESS_FILE"
touch "$VARS_FILE"

# Source variables file if it exists (miracles do happen)
if [[ -f "$VARS_FILE" ]]; then
    source "$VARS_FILE"
fi

# 💀 BEHOLD THE CURSED LARAVEL SETUP SCRIPT 💀
cat << "EOF"
 ██████╗██╗   ██╗██████╗ ███████╗███████╗██████╗ 
██╔════╝██║   ██║██╔══██╗██╔════╝██╔════╝██╔══██╗
██║     ██║   ██║██████╔╝███████╗█████╗  ██║  ██║
██║     ██║   ██║██╔══██╗╚════██║██╔══╝  ██║  ██║
╚██████╗╚██████╔╝██║  ██║███████║███████╗██████╔╝
 ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ 
                                                   
██╗      █████╗ ██████╗  █████╗ ██╗   ██╗███████╗██╗     
██║     ██╔══██╗██╔══██╗██╔══██╗██║   ██║██╔════╝██║     
██║     ███████║██████╔╝███████║██║   ██║█████╗  ██║     
██║     ██╔══██║██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║     
███████╗██║  ██║██║  ██║██║  ██║ ╚████╔╝ ███████╗███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝
                                                          
███████╗███████╗████████╗██╗   ██╗██████╗ 
██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
███████╗█████╗     ██║   ██║   ██║██████╔╝
╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ 
███████║███████╗   ██║   ╚██████╔╝██║     
╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     
EOF

echo -e "${PURPLE}🔮 Welcome to the most CURSED Laravel setup script ever written! 🔮${NC}"
echo -e "${CYAN}💀 This script will summon a Laravel app from the digital void 💀${NC}"
echo -e "${YELLOW}⚡ Hold onto your keyboard, we're about to break the laws of DevOps! ⚡${NC}"
echo ""

prompt_if_empty() {
    local var_name=$1
    local prompt=$2
    local current_value="${!var_name}"
    
    if [[ -z "$current_value" ]]; then
        read -p "🤔 $prompt: " value
        if [[ -n "$value" ]]; then
            export "$var_name"="$value"
            echo "$var_name=\"$value\"" >> "$VARS_FILE"
        fi
    else
        export "$var_name"="$current_value"
        echo -e "${YELLOW}🎯 Using saved value for $var_name: $current_value (you lazy genius!)${NC}"
    fi
}

# 📝 Time to collect your digital soul fragments (configuration)
echo -e "${PURPLE}🧙‍♂️ Let's gather the mystical configuration ingredients...${NC}"
prompt_if_empty "APP_NAME" "🚀 What shall we name this beautiful disaster? (e.g. searchcarriers)"
prompt_if_empty "LINUX_USER" "👤 Who's the chosen one? (Linux user to create/manage, e.g. laravel)"
prompt_if_empty "DB_NAME" "🗄️ What's the name of your data prison? (PostgreSQL database name)"
prompt_if_empty "DB_USER" "🔐 Who gets the keys to the data kingdom? (PostgreSQL database user)"

if [[ -z "$DB_PASS" ]]; then
    read -s -p "🔒 Whisper the secret incantation (PostgreSQL password for user '$DB_USER'): " DB_PASS
    echo ""
    echo "DB_PASS=\"$DB_PASS\"" >> "$VARS_FILE"
fi

prompt_if_empty "GIT_REPO" "📦 Where's your code treasure buried? (Git repo SSH URL to clone)"

if [[ -z "$DOMAIN_NAME" ]]; then
    read -p "🌐 Got a fancy domain name? (leave blank if you're too cool for domains): " DOMAIN_NAME
    echo "DOMAIN_NAME=\"$DOMAIN_NAME\"" >> "$VARS_FILE"
fi

# 🧬 Set derived variables (the dark magic begins)
APP_PATH="/var/www/$APP_NAME"
PHP_VERSION="8.4"

# 🚨 Validate required variables (because chaos needs some rules)
if [[ -z "$APP_NAME" || -z "$LINUX_USER" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" || -z "$GIT_REPO" ]]; then
    echo -e "${RED}💥 ERROR: Missing required magical ingredients! Run this cursed script again! 💥${NC}"
    exit 1
fi

echo -e "${GREEN}🎭 BEHOLD YOUR CURSED CONFIGURATION:${NC}"
echo "🚀 App Name: $APP_NAME"
echo "👤 Linux User: $LINUX_USER"
echo "🗄️ Database: $DB_NAME"
echo "🔐 DB User: $DB_USER"
echo "📦 Git Repo: $GIT_REPO"
echo "🌐 Domain: ${DOMAIN_NAME:-'(too cool for domains)'}"
echo "📁 App Path: $APP_PATH"
echo ""

STEP() {
    local name=$1
    shift
    
    if grep -q "^$name$" "$PROGRESS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⏭️ Skipping $name (already conquered this demon!)${NC}"
        return 0
    fi
    
    echo -e "${PURPLE}🔥 SUMMONING STEP: $name 🔥${NC}"
    
    if eval "$@"; then
        echo "$name" >> "$PROGRESS_FILE"
        echo -e "${GREEN}✅ VICTORY: $name has been TAMED!${NC}"
    else
        echo -e "${RED}💀 EPIC FAIL: $name has defeated us! Time to debug! 💀${NC}"
        exit 1
    fi
}

# 🔄 System update (feeding the Linux beast)
STEP "system_update" '
echo "🍽️ Feeding the Linux beast with fresh packages..." &&
sudo apt update && 
sudo apt upgrade -y && 
sudo apt install -y curl git unzip zip software-properties-common lsb-release ca-certificates apt-transport-https gnupg &&
echo "🎉 Linux beast is now well-fed and happy!"
'

# 🌐 Install Nginx (the web traffic conductor)
STEP "nginx_install" '
echo "🎭 Summoning the mystical Nginx web server..." &&
sudo apt install -y nginx &&
sudo systemctl enable nginx &&
sudo systemctl start nginx &&
echo "🌐 Nginx has awakened and is ready to serve your digital magic!"
'

# 🐘 Install PHP (the elephant in the room, but a good one)
STEP "php_install" '
echo "🐘 Releasing the PHP kraken (version '"$PHP_VERSION"')..." &&
sudo add-apt-repository ppa:ondrej/php -y &&
sudo apt update &&
sudo apt install -y php'"$PHP_VERSION"' php'"$PHP_VERSION"'-fpm php'"$PHP_VERSION"'-cli php'"$PHP_VERSION"'-mbstring php'"$PHP_VERSION"'-xml php'"$PHP_VERSION"'-curl php'"$PHP_VERSION"'-pgsql php'"$PHP_VERSION"'-sqlite3 php'"$PHP_VERSION"'-bcmath php'"$PHP_VERSION"'-zip php'"$PHP_VERSION"'-gd php'"$PHP_VERSION"'-common &&
sudo systemctl enable php'"$PHP_VERSION"'-fpm &&
sudo systemctl start php'"$PHP_VERSION"'-fpm &&
echo "🐘 PHP kraken has been tamed and is ready to serve your Laravel magic!"
'

# 🎼 Install Composer (the dependency wizard)
STEP "composer_install" '
echo "🎼 Summoning the legendary Composer (dependency wizard)..." &&
curl -sS https://getcomposer.org/installer | php &&
sudo mv composer.phar /usr/local/bin/composer &&
sudo chmod +x /usr/local/bin/composer &&
echo "🎼 Composer has been installed and is ready to orchestrate your dependencies!"
'

# 🐘 Install PostgreSQL (the data elephant)
STEP "postgres_install" '
echo "🐘 Awakening the PostgreSQL data elephant..." &&
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg &&
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list &&
sudo apt update &&
sudo apt install -y postgresql-17 postgresql-client-17 &&
sudo systemctl enable postgresql &&
sudo systemctl start postgresql &&
echo "🐘 PostgreSQL elephant is now stomping around, ready to store your precious data!"
'

# 👤 Create user (birth of a digital being)
STEP "user_create" '
echo "👤 Creating digital being: $LINUX_USER..." &&
if ! id "$LINUX_USER" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" "$LINUX_USER" &&
    sudo usermod -aG www-data "$LINUX_USER" &&
    echo "🎉 Digital being $LINUX_USER has been born into this world!"
else
    echo "👤 Digital being $LINUX_USER already exists (probably plotting world domination)"
fi
'

# 🔑 Generate SSH key (forging the digital key of power)
STEP "ssh_keygen" '
echo "🔑 Forging the mystical SSH key of power..." &&
sudo -u "$LINUX_USER" mkdir -p /home/"$LINUX_USER"/.ssh &&
sudo -u "$LINUX_USER" chmod 700 /home/"$LINUX_USER"/.ssh &&
if [[ ! -f /home/"$LINUX_USER"/.ssh/id_ed25519 ]]; then
    sudo -u "$LINUX_USER" ssh-keygen -t ed25519 -N "" -f /home/"$LINUX_USER"/.ssh/id_ed25519 &&
    echo "🔑 SSH key of power has been forged!"
else
    echo "🔑 SSH key of power already exists (wise precaution)"
fi
'

# 🔑 SSH key upload prompt (the ritual of trust)
if ! grep -q "^ssh_key_uploaded$" "$PROGRESS_FILE"; then
    echo ""
    echo -e "${CYAN}🔮 === THE RITUAL OF TRUST === 🔮${NC}"
    echo -e "${YELLOW}📜 Copy this magical SSH key and sacrifice it to your Git provider:${NC}"
    echo ""
    sudo cat /home/"$LINUX_USER"/.ssh/id_ed25519.pub
    echo ""
    echo -e "${PURPLE}⚡ Once you've completed the ritual, the repository will bend to your will! ⚡${NC}"
    read -p "🎯 Press ENTER after uploading the key and verifying the ritual was successful..."
    echo "ssh_key_uploaded" >> "$PROGRESS_FILE"
    echo -e "${GREEN}✅ The ritual is complete! Your Git provider now trusts us!${NC}"
fi

# 📦 Install NVM and Node.js (summoning the JavaScript spirits)
STEP "nvm_install" '
echo "📦 Summoning the JavaScript spirits via NVM..." &&
sudo -u "$LINUX_USER" bash -c "
export NVM_DIR=\"/home/$LINUX_USER/.nvm\" &&
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash &&
source \"/home/$LINUX_USER/.nvm/nvm.sh\" &&
nvm install --lts &&
nvm use --lts &&
echo \"📦 JavaScript spirits have been summoned and are ready to serve!\"
"
'

# 🏗️ Clone repository (stealing... I mean acquiring the code treasure)
STEP "repo_clone" '
echo "🏴‍☠️ Acquiring the legendary code treasure..." &&
sudo mkdir -p "$APP_PATH" &&
sudo chown -R "$LINUX_USER":"$LINUX_USER" "$APP_PATH" &&
sudo -u "$LINUX_USER" bash -c "
cd /home/$LINUX_USER &&
ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null || true &&
ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts 2>/dev/null || true &&
git clone \"$GIT_REPO\" \"$APP_PATH\" &&
echo \"🏴‍☠️ Code treasure has been successfully plundered!\"
"
'

# 🗄️ Configure PostgreSQL (teaching the elephant to dance)
STEP "postgres_config" '
echo "🗄️ Teaching the PostgreSQL elephant to dance with our database..." &&
sudo -i -u postgres psql <<EOF
CREATE DATABASE "$DB_NAME";
CREATE USER "$DB_USER" WITH PASSWORD '"'"'$DB_PASS'"'"';
GRANT ALL PRIVILEGES ON DATABASE "$DB_NAME" TO "$DB_USER";
\c "$DB_NAME"
GRANT USAGE, CREATE ON SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$DB_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$DB_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$DB_USER";
EOF
echo "🗄️ PostgreSQL elephant has learned to dance beautifully!"
'

# 📦 Install Laravel dependencies (gathering the PHP minions)
STEP "composer_dependencies" '
echo "📦 Gathering the PHP minions for our Laravel army..." &&
cd "$APP_PATH" &&
sudo -u "$LINUX_USER" composer install --no-dev --optimize-autoloader &&
echo "📦 PHP minions have assembled and are ready for battle!"
'

# ⚙️ Configure Laravel environment (casting the configuration spell)
STEP "laravel_env_config" '
echo "⚙️ Casting the mystical configuration spell on Laravel..." &&
cd "$APP_PATH" &&
if [[ ! -f .env && -f .env.example ]]; then
    sudo -u "$LINUX_USER" cp .env.example .env &&
    echo "📋 .env file materialized from the example template!"
fi &&
sudo -u "$LINUX_USER" php artisan key:generate --force &&
echo "🔑 Laravel app key generated with dark magic!" &&
# Set production environment settings
sudo -u "$LINUX_USER" sed -i "s/^#*APP_ENV=.*/APP_ENV=production/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*APP_DEBUG=.*/APP_DEBUG=false/" .env &&
echo "🚀 Environment set to PRODUCTION mode (no more debug traces for hackers!)" &&
# Configure database connection for PostgreSQL
# Handle both commented (#DB_CONNECTION) and uncommented (DB_CONNECTION) lines
sudo -u "$LINUX_USER" sed -i "s/^#*DB_CONNECTION=.*/DB_CONNECTION=pgsql/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_HOST=.*/DB_HOST=127.0.0.1/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_PORT=.*/DB_PORT=5432/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env &&
echo "🗄️ Database connection spells have been inscribed!" &&
# If the lines don'"'"'t exist at all, add them
if ! grep -q "^APP_ENV=" .env; then
    echo "APP_ENV=production" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^APP_DEBUG=" .env; then
    echo "APP_DEBUG=false" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^DB_CONNECTION=" .env; then
    echo "DB_CONNECTION=pgsql" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^DB_HOST=" .env; then
    echo "DB_HOST=127.0.0.1" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^DB_PORT=" .env; then
    echo "DB_PORT=5432" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^DB_DATABASE=" .env; then
    echo "DB_DATABASE=$DB_NAME" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^DB_USERNAME=" .env; then
    echo "DB_USERNAME=$DB_USER" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
if ! grep -q "^DB_PASSWORD=" .env; then
    echo "DB_PASSWORD=$DB_PASS" | sudo -u "$LINUX_USER" tee -a .env > /dev/null
fi &&
echo "⚙️ Laravel environment configuration spell has been successfully cast!"
'

# 🗄️ Run database migrations and optimize Laravel (awakening the database schema)
STEP "laravel_database_setup" '
echo "🗄️ Awakening the database schema from its eternal slumber..." &&
cd "$APP_PATH" &&
echo "🔮 Casting migration spells..." &&
sudo -u "$LINUX_USER" php artisan migrate --force &&
echo "⚡ Optimizing Laravel with performance enchantments..." &&
sudo -u "$LINUX_USER" php artisan config:cache &&
sudo -u "$LINUX_USER" php artisan route:cache &&
sudo -u "$LINUX_USER" php artisan view:cache &&
echo "🗄️ Database schema has awakened and Laravel is now TURBOCHARGED!"
'

# 🎨 Build frontend assets (summoning the CSS/JS demons)
STEP "frontend_build" '
echo "🎨 Time to summon the CSS and JavaScript demons..." &&
cd "$APP_PATH" &&
if [[ -f package.json ]]; then
    echo "📦 Feeding the Node.js dependencies to our JavaScript spirits..." &&
    sudo -u "$LINUX_USER" bash -c "
    source /home/$LINUX_USER/.nvm/nvm.sh &&
    npm install &&
    echo \"📦 JavaScript spirits are well-fed and content!\"
    " &&
    echo "🏗️ Building the frontend kingdom..." &&
    sudo -u "$LINUX_USER" bash -c "
    source /home/$LINUX_USER/.nvm/nvm.sh &&
    npm run build &&
    echo \"🏗️ Frontend kingdom has been built with sweat, tears, and JavaScript!\"
    "
else
    echo "📦 No package.json found - either you'"'"'re too cool for frontend or forgot to commit it! 😎"
fi
'

# 🔒 Set permissions (establishing the digital hierarchy)
STEP "permissions_config" '
echo "🔒 Establishing the digital hierarchy of file permissions..." &&
sudo chown -R "$LINUX_USER":www-data "$APP_PATH" &&
sudo find "$APP_PATH" -type d -exec chmod 755 {} \; &&
sudo find "$APP_PATH" -path "$APP_PATH/node_modules" -prune -o -type f -exec chmod 644 {} \; &&
echo "📁 Basic file permissions have been bestowed upon the masses!" &&
if [[ -d "$APP_PATH/storage" ]]; then
    sudo chmod -R 775 "$APP_PATH/storage" &&
    sudo chown -R "$LINUX_USER":www-data "$APP_PATH/storage" &&
    echo "🗄️ Storage directory has been blessed with write permissions!"
fi &&
if [[ -d "$APP_PATH/bootstrap/cache" ]]; then
    sudo chmod -R 775 "$APP_PATH/bootstrap/cache" &&
    sudo chown -R "$LINUX_USER":www-data "$APP_PATH/bootstrap/cache" &&
    echo "⚡ Bootstrap cache has been granted the power of caching!"
fi &&
echo "🔒 Digital hierarchy established! All files know their place!"
'

# 🌐 Configure Nginx (teaching the web server to speak Laravel)
STEP "nginx_config" '
echo "🌐 Teaching Nginx to speak fluent Laravel..." &&
sudo rm -f /etc/nginx/sites-enabled/default &&
SERVER_NAME_BLOCK="_" &&
if [[ -n "$DOMAIN_NAME" ]]; then
    SERVER_NAME_BLOCK="$DOMAIN_NAME www.$DOMAIN_NAME _"
fi &&
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME" &&
echo "📝 Writing the sacred Nginx configuration scroll..." &&
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80 default_server;
    server_name $SERVER_NAME_BLOCK;

    root $APP_PATH/public;
    index index.php index.html;

    access_log /var/log/nginx/$APP_NAME.access.log;
    error_log /var/log/nginx/$APP_NAME.error.log;

    # Client and buffer settings (because size matters)
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 32k;
    large_client_header_buffers 8 32k;

    # FastCGI buffer settings for handling large headers (no header shame here)
    fastcgi_buffer_size 32k;
    fastcgi_buffers 8 32k;
    fastcgi_busy_buffers_size 64k;
    fastcgi_temp_file_write_size 64k;

    # Security headers (keeping the bad guys out)
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        
        # FastCGI buffer settings (duplicate for this location block)
        fastcgi_buffer_size 32k;
        fastcgi_buffers 8 32k;
        fastcgi_busy_buffers_size 64k;
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        
        include fastcgi_params;
    }

    # Deny access to hidden files (no peeking!)
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Deny access to sensitive files (top secret stuff)
    location ~* \.(htaccess|htpasswd|ini|log|sh|sql|conf)\$ {
        deny all;
    }
}
EOF
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ &&
sudo nginx -t &&
sudo systemctl reload nginx &&
echo "🌐 Nginx has learned to speak Laravel fluently! Communication established!"
'

# 👁️ Install and configure Supervisor (the all-seeing process manager)
STEP "supervisor_install" '
echo "👁️ Summoning the all-seeing Supervisor (process overlord)..." &&
sudo apt install -y supervisor &&
sudo systemctl enable supervisor &&
sudo systemctl start supervisor &&
echo "👁️ Supervisor is now watching everything with its digital eyes!"
'

# ⚡ Configure Supervisor for Laravel queues (enslaving the background workers)
STEP "supervisor_config" '
echo "⚡ Enslaving the Laravel queue workers to Supervisor..." &&
SUPERVISOR_CONF="/etc/supervisor/conf.d/laravel-worker.conf" &&
sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $APP_PATH/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=$LINUX_USER
numprocs=1
redirect_stderr=true
stdout_logfile=$APP_PATH/storage/logs/worker.log
stopwaitsecs=3600
EOF
sudo supervisorctl reread &&
sudo supervisorctl update &&
sudo supervisorctl start laravel-worker:* &&
echo "⚡ Queue workers have been enslaved and are now working 24/7 for you!"
'

# ⏰ Configure Laravel Scheduler Cron Job (binding time itself to our will)
STEP "laravel_cron_config" '
echo "⏰ Binding the very fabric of time to serve our Laravel scheduler..." &&
CRON_COMMAND="* * * * * cd $APP_PATH && php artisan schedule:run >> /dev/null 2>&1" &&
# Check if cron job already exists to avoid duplicates
sudo -u "$LINUX_USER" bash -c "
if ! crontab -l 2>/dev/null | grep -F \"$APP_PATH && php artisan schedule:run\" > /dev/null; then
    (crontab -l 2>/dev/null; echo \"$CRON_COMMAND\") | crontab -
    echo \"⏰ Time itself has been enslaved to run our Laravel scheduler every minute!\"
else
    echo \"⏰ Time is already under our control (scheduler already exists)\"
fi
" &&
echo "⏰ The Laravel scheduler now controls the passage of time itself!"
'

echo ""
echo -e "${PURPLE}🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉${NC}"
echo -e "${GREEN}💀 THE RITUAL IS COMPLETE! 💀${NC}"
echo -e "${CYAN}🔮 Your cursed Laravel app '$APP_NAME' has been summoned from the digital void! 🔮${NC}"
echo -e "${YELLOW}🌐 Behold its earthly manifestation: http://$(curl -s ifconfig.me) 🌐${NC}"
if [[ -n "$DOMAIN_NAME" ]]; then
    echo -e "${PURPLE}🏰 Or visit its noble domain: http://$DOMAIN_NAME 🏰${NC}"
fi
echo -e "${PURPLE}🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉${NC}"

echo ""
echo -e "${YELLOW}🔮 THE SACRED NEXT STEPS OF DIGITAL ENLIGHTENMENT: 🔮${NC}"
echo -e "${CYAN}   🏰 Configure thy domain's DNS to point to this mystical server${NC}"
echo -e "${GREEN}   🔒 Bind SSL/TLS magic with: sudo certbot --nginx${NC}"
echo -e "${PURPLE}   ⚙️ Review thy Laravel .env scrolls for any remaining secrets${NC}"
echo -e "${YELLOW}   💾 Establish backup rituals for thy database and sacred files${NC}"
echo -e "${RED}   ⏰ The Laravel scheduler now awakens every minute like clockwork${NC}"
echo ""
echo -e "${PURPLE}🧙‍♂️ May your Laravel app serve you well, master of the digital arts! 🧙‍♂️${NC}"

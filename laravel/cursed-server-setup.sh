#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROGRESS_FILE=".setup-progress"
VARS_FILE=".setup-vars"

# Create files if they don't exist
touch "$PROGRESS_FILE"
touch "$VARS_FILE"

# Source variables file if it exists
if [[ -f "$VARS_FILE" ]]; then
    source "$VARS_FILE"
fi

echo -e "${GREEN}=== Laravel Server Provisioning Script ===${NC}"

prompt_if_empty() {
    local var_name=$1
    local prompt=$2
    local current_value="${!var_name}"
    
    if [[ -z "$current_value" ]]; then
        read -p "$prompt: " value
        if [[ -n "$value" ]]; then
            export "$var_name"="$value"
            echo "$var_name=\"$value\"" >> "$VARS_FILE"
        fi
    else
        export "$var_name"="$current_value"
        echo -e "${YELLOW}Using saved value for $var_name: $current_value${NC}"
    fi
}

# Collect all required variables
prompt_if_empty "APP_NAME" "Enter app name (e.g. searchcarriers)"
prompt_if_empty "LINUX_USER" "Enter Linux user to create/manage (e.g. laravel)"
prompt_if_empty "DB_NAME" "Enter PostgreSQL database name"
prompt_if_empty "DB_USER" "Enter PostgreSQL database user"

if [[ -z "$DB_PASS" ]]; then
    read -s -p "Enter PostgreSQL password for user '$DB_USER': " DB_PASS
    echo ""
    echo "DB_PASS=\"$DB_PASS\"" >> "$VARS_FILE"
fi

prompt_if_empty "GIT_REPO" "Enter Git repo SSH URL to clone"

if [[ -z "$DOMAIN_NAME" ]]; then
    read -p "Enter domain (leave blank for default): " DOMAIN_NAME
    echo "DOMAIN_NAME=\"$DOMAIN_NAME\"" >> "$VARS_FILE"
fi

# Set derived variables
APP_PATH="/var/www/$APP_NAME"
PHP_VERSION="8.4"

# Validate required variables
if [[ -z "$APP_NAME" || -z "$LINUX_USER" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" || -z "$GIT_REPO" ]]; then
    echo -e "${RED}Error: Missing required variables. Please run the script again.${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "App Name: $APP_NAME"
echo "Linux User: $LINUX_USER"
echo "Database: $DB_NAME"
echo "DB User: $DB_USER"
echo "Git Repo: $GIT_REPO"
echo "Domain: ${DOMAIN_NAME:-'(default)'}"
echo "App Path: $APP_PATH"
echo ""

STEP() {
    local name=$1
    shift
    
    if grep -q "^$name$" "$PROGRESS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}✓ Skipping $name (already done)${NC}"
        return 0
    fi
    
    echo -e "${GREEN}=== Running step: $name ===${NC}"
    
    if eval "$@"; then
        echo "$name" >> "$PROGRESS_FILE"
        echo -e "${GREEN}✓ Completed: $name${NC}"
    else
        echo -e "${RED}✗ Failed: $name${NC}"
        exit 1
    fi
}

# System update
STEP "system_update" '
sudo apt update && 
sudo apt upgrade -y && 
sudo apt install -y curl git unzip zip software-properties-common lsb-release ca-certificates apt-transport-https gnupg
'

# Install Nginx
STEP "nginx_install" '
sudo apt install -y nginx &&
sudo systemctl enable nginx &&
sudo systemctl start nginx
'

# Install PHP
STEP "php_install" '
sudo add-apt-repository ppa:ondrej/php -y &&
sudo apt update &&
sudo apt install -y php'"$PHP_VERSION"' php'"$PHP_VERSION"'-fpm php'"$PHP_VERSION"'-cli php'"$PHP_VERSION"'-mbstring php'"$PHP_VERSION"'-xml php'"$PHP_VERSION"'-curl php'"$PHP_VERSION"'-pgsql php'"$PHP_VERSION"'-bcmath php'"$PHP_VERSION"'-zip php'"$PHP_VERSION"'-gd php'"$PHP_VERSION"'-common &&
sudo systemctl enable php'"$PHP_VERSION"'-fpm &&
sudo systemctl start php'"$PHP_VERSION"'-fpm
'

# Install Composer
STEP "composer_install" '
curl -sS https://getcomposer.org/installer | php &&
sudo mv composer.phar /usr/local/bin/composer &&
sudo chmod +x /usr/local/bin/composer
'

# Install PostgreSQL
STEP "postgres_install" '
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg &&
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list &&
sudo apt update &&
sudo apt install -y postgresql-17 postgresql-client-17 &&
sudo systemctl enable postgresql &&
sudo systemctl start postgresql
'

# Create user
STEP "user_create" '
if ! id "$LINUX_USER" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" "$LINUX_USER" &&
    sudo usermod -aG www-data "$LINUX_USER"
fi
'

# Generate SSH key
STEP "ssh_keygen" '
sudo -u "$LINUX_USER" mkdir -p /home/"$LINUX_USER"/.ssh &&
sudo -u "$LINUX_USER" chmod 700 /home/"$LINUX_USER"/.ssh &&
if [[ ! -f /home/"$LINUX_USER"/.ssh/id_ed25519 ]]; then
    sudo -u "$LINUX_USER" ssh-keygen -t ed25519 -N "" -f /home/"$LINUX_USER"/.ssh/id_ed25519
fi
'

# SSH key upload prompt
if ! grep -q "^ssh_key_uploaded$" "$PROGRESS_FILE"; then
    echo -e "${YELLOW}=== Upload this SSH key to your Git provider before continuing ===${NC}"
    sudo cat /home/"$LINUX_USER"/.ssh/id_ed25519.pub
    echo ""
    read -p "Press ENTER after uploading the key and verifying access to the repo..."
    echo "ssh_key_uploaded" >> "$PROGRESS_FILE"
fi

# Install NVM and Node.js
STEP "nvm_install" '
sudo -u "$LINUX_USER" bash -c "
export NVM_DIR=\"/home/$LINUX_USER/.nvm\" &&
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash &&
source \"/home/$LINUX_USER/.nvm/nvm.sh\" &&
nvm install --lts &&
nvm use --lts
"
'

# Clone repository
STEP "repo_clone" '
sudo mkdir -p "$APP_PATH" &&
sudo chown -R "$LINUX_USER":"$LINUX_USER" "$APP_PATH" &&
sudo -u "$LINUX_USER" bash -c "
cd /home/$LINUX_USER &&
ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null || true &&
ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts 2>/dev/null || true &&
git clone \"$GIT_REPO\" \"$APP_PATH\"
"
'

# Configure PostgreSQL
STEP "postgres_config" '
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
'

# Install Laravel dependencies
STEP "composer_dependencies" '
cd "$APP_PATH" &&
sudo -u "$LINUX_USER" composer install --no-dev --optimize-autoloader
'

# Configure Laravel environment
STEP "laravel_env_config" '
cd "$APP_PATH" &&
if [[ ! -f .env && -f .env.example ]]; then
    sudo -u "$LINUX_USER" cp .env.example .env
fi &&
sudo -u "$LINUX_USER" php artisan key:generate --force &&
# Set production environment settings
sudo -u "$LINUX_USER" sed -i "s/^#*APP_ENV=.*/APP_ENV=production/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*APP_DEBUG=.*/APP_DEBUG=false/" .env &&
# Configure database connection for PostgreSQL
# Handle both commented (#DB_CONNECTION) and uncommented (DB_CONNECTION) lines
sudo -u "$LINUX_USER" sed -i "s/^#*DB_CONNECTION=.*/DB_CONNECTION=pgsql/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_HOST=.*/DB_HOST=127.0.0.1/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_PORT=.*/DB_PORT=5432/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env &&
sudo -u "$LINUX_USER" sed -i "s/^#*DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env &&
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
echo "Laravel environment configured for production"
'

# Run database migrations and optimize Laravel
STEP "laravel_database_setup" '
cd "$APP_PATH" &&
echo "Running database migrations..." &&
sudo -u "$LINUX_USER" php artisan migrate --force &&
echo "Optimizing Laravel..." &&
sudo -u "$LINUX_USER" php artisan config:cache &&
sudo -u "$LINUX_USER" php artisan route:cache &&
sudo -u "$LINUX_USER" php artisan view:cache
'

# Build frontend assets
STEP "frontend_build" '
cd "$APP_PATH" &&
if [[ -f package.json ]]; then
    echo "Installing Node.js dependencies..." &&
    sudo -u "$LINUX_USER" bash -c "
    source /home/$LINUX_USER/.nvm/nvm.sh &&
    npm install
    " &&
    echo "Building frontend assets..." &&
    sudo -u "$LINUX_USER" bash -c "
    source /home/$LINUX_USER/.nvm/nvm.sh &&
    npm run build
    "
else
    echo "No package.json found, skipping frontend build"
fi
'

# Set permissions
STEP "permissions_config" '
sudo chown -R "$LINUX_USER":www-data "$APP_PATH" &&
sudo find "$APP_PATH" -type d -exec chmod 755 {} \; &&
sudo find "$APP_PATH" -type f -exec chmod 644 {} \; &&
if [[ -d "$APP_PATH/storage" ]]; then
    sudo chmod -R 775 "$APP_PATH/storage" &&
    sudo chown -R "$LINUX_USER":www-data "$APP_PATH/storage"
fi &&
if [[ -d "$APP_PATH/bootstrap/cache" ]]; then
    sudo chmod -R 775 "$APP_PATH/bootstrap/cache" &&
    sudo chown -R "$LINUX_USER":www-data "$APP_PATH/bootstrap/cache"
fi
'

# Configure Nginx
STEP "nginx_config" '
sudo rm -f /etc/nginx/sites-enabled/default &&
SERVER_NAME_BLOCK="_" &&
if [[ -n "$DOMAIN_NAME" ]]; then
    SERVER_NAME_BLOCK="$DOMAIN_NAME www.$DOMAIN_NAME _"
fi &&
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME" &&
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80 default_server;
    server_name $SERVER_NAME_BLOCK;

    root $APP_PATH/public;
    index index.php index.html;

    access_log /var/log/nginx/$APP_NAME.access.log;
    error_log /var/log/nginx/$APP_NAME.error.log;

    # Client and buffer settings
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 32k;
    large_client_header_buffers 8 32k;

    # FastCGI buffer settings for handling large headers
    fastcgi_buffer_size 32k;
    fastcgi_buffers 8 32k;
    fastcgi_busy_buffers_size 64k;
    fastcgi_temp_file_write_size 64k;

    # Security headers
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

    # Deny access to hidden files
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|otf)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        log_not_found off;
    }

    # Deny access to sensitive files
    location ~* \.(htaccess|htpasswd|ini|log|sh|sql|conf)\$ {
        deny all;
    }
}
EOF
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ &&
sudo nginx -t &&
sudo systemctl reload nginx
'

# Install and configure Supervisor
STEP "supervisor_install" '
sudo apt install -y supervisor &&
sudo systemctl enable supervisor &&
sudo systemctl start supervisor
'

# Configure Supervisor for Laravel queues
STEP "supervisor_config" '
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
sudo supervisorctl start laravel-worker:*
'

# Configure Laravel Scheduler Cron Job
STEP "laravel_cron_config" '
echo "Setting up Laravel scheduler cron job..." &&
CRON_COMMAND="* * * * * cd $APP_PATH && php artisan schedule:run >> /dev/null 2>&1" &&
# Check if cron job already exists to avoid duplicates
sudo -u "$LINUX_USER" bash -c "
if ! crontab -l 2>/dev/null | grep -F \"$APP_PATH && php artisan schedule:run\" > /dev/null; then
    (crontab -l 2>/dev/null; echo \"$CRON_COMMAND\") | crontab -
    echo \"Laravel scheduler cron job added successfully\"
else
    echo \"Laravel scheduler cron job already exists\"
fi
"
'

echo ""
echo -e "${GREEN}✅ All done! Laravel app '$APP_NAME' is deployed and ready!${NC}"
echo -e "${GREEN}🌐 You can access your app at: http://$(curl -s ifconfig.me)${NC}"
if [[ -n "$DOMAIN_NAME" ]]; then
    echo -e "${GREEN}🌐 Or at your domain: http://$DOMAIN_NAME${NC}"
fi
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "   - Configure your domain's DNS to point to this server"
echo "   - Set up SSL/TLS with Let's Encrypt: sudo certbot --nginx"
echo "   - Review your Laravel .env configuration"
echo "   - Set up backups for your database and files"
echo "   - Laravel scheduler is now configured to run every minute"

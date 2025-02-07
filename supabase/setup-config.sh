#!/bin/bash
# @Author Sergey Durmanov
# @Version 2025-02-07

# Function to show progress
show_progress() {
    echo "➜ $1"
}

# Download setting files
echo "Downloading setting files..."
wget https://raw.githubusercontent.com/tecspda/timeweb/refs/heads/main/supabase/.env -O ./docker/.env
wget https://raw.githubusercontent.com/tecspda/timeweb/refs/heads/main/supabase/docker-compose.yml -O ./docker/docker-compose.yml

# Collect input values
echo "Please enter the following configuration values:"
read -p "Enter JWT_SECRET: " INPUT_JWT_SECRET
read -p "Enter ANON_KEY: " INPUT_ANON_KEY
read -p "Enter SERVICE_ROLE_KEY: " INPUT_SERVICE_ROLE_KEY
read -p "Enter POSTGRES_PASSWORD: " INPUT_POSTGRES_PASSWORD
read -p "Enter DASHBOARD_PASSWORD: " INPUT_DASHBOARD_PASSWORD
read -p "Enter your VPS IP (e.g., 111.222.333.444): " INPUT_IP_YOUR_VPS

# Validate IP address format
if ! [[ $INPUT_IP_YOUR_VPS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid IP address format"
    exit 1
fi

# Processing docker/.env file
show_progress "Updating PostgreSQL password..."
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$INPUT_POSTGRES_PASSWORD/" ./docker/.env

show_progress "Updating Dashboard password..."
sed -i "s/DASHBOARD_PASSWORD=.*/DASHBOARD_PASSWORD=$INPUT_DASHBOARD_PASSWORD/" ./docker/.env

show_progress "Updating Vault encryption key..."
sed -i "s/VAULT_ENC_KEY=.*/VAULT_ENC_KEY=none/" ./docker/.env

show_progress "Updating JWT secret..."
sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$INPUT_JWT_SECRET/" ./docker/.env

show_progress "Updating site URLs..."
sed -i "s/SITE_URL=.*/SITE_URL=http:\/\/$INPUT_IP_YOUR_VPS/" ./docker/.env
sed -i "s/API_EXTERNAL_URL=.*/API_EXTERNAL_URL=http:\/\/$INPUT_IP_YOUR_VPS:8000/" ./docker/.env
sed -i "s/SUPABASE_PUBLIC_URL=.*/SUPABASE_PUBLIC_URL=http:\/\/$INPUT_IP_YOUR_VPS:8000/" ./docker/.env

show_progress "Updating authentication keys..."
sed -i "s/ANON_KEY=.*/ANON_KEY=$INPUT_ANON_KEY/" ./docker/.env
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$INPUT_JWT_SECRET/" ./docker/.env
sed -i "s/SERVICE_ROLE_KEY=.*/SERVICE_ROLE_KEY=$INPUT_SERVICE_ROLE_KEY/" ./docker/.env

show_progress "Disabling email signup..."
sed -i "s/ENABLE_EMAIL_SIGNUP=.*/ENABLE_EMAIL_SIGNUP=false/" ./docker/.env

show_progress "Updating IP addresses in configuration files..."
sed -i -E "s/111.111.111.111/$INPUT_IP_YOUR_VPS/g" ./docker/docker-compose.yml
sed -i -E "s/111.111.111.111/$INPUT_IP_YOUR_VPS/g" ./docker/.env

show_progress "Updating boolean format in docker-compose.yml..."
sed -i -E 's/(: *)true/\1"true"/g' ./docker/docker-compose.yml

echo "✅ Configuration update completed successfully!"

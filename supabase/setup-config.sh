#!/bin/bash
# @Author Sergey Durmanov
# @Version 2025-02-07

# Function to show progress
show_progress() {
    echo "➜ $1"
}

#!/bin/bash

validate_ip() {
    # Проверка формата XXX.XXX.XXX.XXX
    if ! [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 1
    fi
    
    # Разбиваем IP на части и проверяем каждую
    IFS='.' read -r -a quads <<< "$1"
    
    # Проверяем каждую часть
    for quad in "${quads[@]}"; do
        # Преобразуем строку в число, удаляя ведущие нули
        num=$((10#$quad))
        
        # Проверяем условия:
        # 1. Число должно быть между 0 и 255
        # 2. Исходная строка не должна иметь ведущих нулей (кроме самого числа 0)
        if ((num < 0 || num > 255)) || 
           ([ "$quad" != "0" ] && [[ $quad =~ ^0[0-9] ]]); then
            return 1
        fi
    done
    
    return 0
}

# Download setting files
echo "Downloading setting files..."
wget -q https://raw.githubusercontent.com/tecspda/timeweb/refs/heads/main/supabase/.env -O ./docker/.env
wget -q https://raw.githubusercontent.com/tecspda/timeweb/refs/heads/main/supabase/docker-compose.yml -O ./docker/docker-compose.yml

# Collect input values
echo "Please enter the following configuration values:"
read -s -p "Enter JWT_SECRET: " INPUT_JWT_SECRET
printf "\n"
read -s -p "Enter ANON_KEY: " INPUT_ANON_KEY
printf "\n"
read -s -p "Enter SERVICE_ROLE_KEY: " INPUT_SERVICE_ROLE_KEY
printf "\n"
read -s -p "Enter POSTGRES_PASSWORD: " INPUT_POSTGRES_PASSWORD
printf "\n"
read -s -p "Enter DASHBOARD_PASSWORD: " INPUT_DASHBOARD_PASSWORD
printf "\n"
read -p "Enter your VPS IP (e.g., 111.222.333.444): " INPUT_IP_YOUR_VPS
printf "\n"

# Validate IP address format
if ! validate_ip "$INPUT_IP_YOUR_VPS"; then
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
sed -i "s/SITE_URL=.*/SITE_URL=http:\/\/$INPUT_IP_YOUR_VPS:3000/" ./docker/.env
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

#!/bin/bash

# Initialize Let's Encrypt certificates for Beifong

if [ -z "$DOMAIN" ]; then
    echo "Error: DOMAIN environment variable is not set"
    echo "Please set DOMAIN in your .env file or export it before running this script"
    echo "Example: export DOMAIN=yourdomain.com"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "Error: EMAIL environment variable is not set"
    echo "Please set EMAIL in your .env file or export it before running this script"
    echo "Example: export EMAIL=your@email.com"
    exit 1
fi

echo "Initializing Let's Encrypt certificates for $DOMAIN"
echo "Email: $EMAIL"
echo ""

# Check if certificates already exist
if [ -d "./certbot/conf/live/$DOMAIN" ]; then
    echo "Certificates already exist for $DOMAIN"
    read -p "Do you want to recreate them? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping certificate creation"
        exit 0
    fi
    echo "Removing existing certificates..."
    rm -rf "./certbot/conf/live/$DOMAIN"
fi

# Create dummy certificate to start nginx
echo "Creating dummy certificate for $DOMAIN..."
mkdir -p "./certbot/conf/live/$DOMAIN"
openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout "./certbot/conf/live/$DOMAIN/privkey.pem" \
    -out "./certbot/conf/live/$DOMAIN/fullchain.pem" \
    -subj "/CN=$DOMAIN"

echo "Starting nginx..."
docker-compose up -d nginx

echo "Removing dummy certificate..."
docker-compose run --rm --entrypoint "\
    rm -rf /etc/letsencrypt/live/$DOMAIN && \
    rm -rf /etc/letsencrypt/archive/$DOMAIN && \
    rm -rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "Requesting Let's Encrypt certificate..."
docker-compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN" certbot

if [ $? -eq 0 ]; then
    echo "Certificate obtained successfully!"
    echo "Reloading nginx..."
    docker-compose restart nginx
    echo ""
    echo "HTTPS setup complete! Your site is now available at:"
    echo "https://$DOMAIN"
else
    echo "Failed to obtain certificate. Please check:"
    echo "1. Your domain $DOMAIN is pointing to this server"
    echo "2. Ports 80 and 443 are accessible from the internet"
    echo "3. You have a valid email address"
    exit 1
fi

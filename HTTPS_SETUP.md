# HTTPS Setup Guide

This guide explains how to set up HTTPS for the Beifong application using Let's Encrypt certificates and Nginx.

## Prerequisites

Before setting up HTTPS, ensure you have:

1. **A domain name** pointing to your server's IP address
2. **Ports 80 and 443** open and accessible from the internet
3. **Docker and Docker Compose** installed on your server
4. **A valid email address** for Let's Encrypt notifications

## Configuration

### 1. Update Environment Variables

Edit your `.env` file and add the following required variables:

```bash
DOMAIN=yourdomain.com
EMAIL=your@email.com
```

Replace `yourdomain.com` with your actual domain name and `your@email.com` with your email address.

### 2. DNS Configuration

Ensure your domain's DNS A record points to your server's public IP address:

```
A    yourdomain.com    ->    YOUR_SERVER_IP
```

You can verify this with:

```bash
dig yourdomain.com
# or
nslookup yourdomain.com
```

## Installation

### Initial Certificate Setup

Run the initialization script to obtain your SSL certificates:

```bash
./init-letsencrypt.sh
```

This script will:
1. Create a temporary self-signed certificate
2. Start the nginx service
3. Request a real certificate from Let's Encrypt
4. Replace the temporary certificate with the real one
5. Reload nginx with the new certificates

### Start All Services

After obtaining certificates, start all services:

```bash
docker-compose up -d
```

Your application will now be available at:
- **Frontend**: `https://yourdomain.com`
- **Backend API**: `https://yourdomain.com/api`

## Architecture

The HTTPS setup uses the following architecture:

```
Internet → Nginx (ports 80/443) → Frontend (port 3000)
                                 → Backend API (port 7000)
```

- **Nginx** handles SSL/TLS termination and acts as a reverse proxy
- **Port 80** redirects all HTTP traffic to HTTPS
- **Port 443** serves HTTPS traffic
- **Backend and Frontend** are only accessible through nginx (not directly exposed)

## Certificate Renewal

Let's Encrypt certificates are valid for 90 days. The `certbot` service automatically renews certificates twice daily. No manual intervention is required.

To manually renew certificates:

```bash
docker-compose run --rm certbot renew
docker-compose restart nginx
```

## Nginx Configuration

The nginx configuration includes:

- **HTTP to HTTPS redirect**: All HTTP traffic is automatically redirected to HTTPS
- **SSL/TLS settings**: Modern TLS 1.2/1.3 protocols with secure ciphers
- **Security headers**: HSTS, X-Frame-Options, X-Content-Type-Options, etc.
- **API proxy**: `/api/*` requests are proxied to the backend service
- **WebSocket support**: `/ws/*` for WebSocket connections if needed
- **Frontend proxy**: All other requests are proxied to the frontend service

## Troubleshooting

### Certificate Initialization Fails

If the initialization script fails:

1. **Check domain DNS**: Ensure your domain points to the server
   ```bash
   dig yourdomain.com
   ```

2. **Check port accessibility**: Ensure ports 80 and 443 are open
   ```bash
   curl http://yourdomain.com
   ```

3. **Check nginx logs**:
   ```bash
   docker-compose logs nginx
   ```

4. **Check certbot logs**:
   ```bash
   docker-compose logs certbot
   ```

### Rate Limiting

Let's Encrypt has rate limits (5 certificates per domain per week). If you hit the limit:
- Wait for a week to retry
- Use the Let's Encrypt staging environment for testing:
  - Edit `init-letsencrypt.sh` and add `--staging` flag to certbot command

### Browser Security Warnings

If you see security warnings:
- Ensure certificates are properly installed: `docker-compose logs nginx`
- Check certificate expiration: `docker-compose run --rm certbot certificates`
- Verify domain matches certificate: The domain in your browser should match `DOMAIN` in `.env`

## Development vs Production

For **local development** without a domain:
- You can use self-signed certificates (the script creates them initially)
- Browsers will show security warnings (this is expected)
- To skip warnings: Use `http://localhost:80` instead (nginx will redirect)

For **production**:
- Always use a valid domain name
- Always use Let's Encrypt certificates
- Never skip certificate validation

## Security Considerations

1. **Keep certificates secure**: Don't commit `certbot/conf` directory to git
2. **Use strong passwords**: For any admin interfaces
3. **Keep Docker images updated**: Regularly update nginx and certbot images
4. **Monitor certificate expiration**: Check logs to ensure auto-renewal works
5. **Use environment variables**: Never hardcode sensitive data

## File Structure

```
.
├── docker-compose.yml          # Main Docker Compose configuration
├── nginx/
│   ├── nginx.conf             # Main nginx configuration
│   └── conf.d/
│       └── app.conf           # Application-specific nginx config
├── certbot/
│   ├── conf/                  # SSL certificates (auto-generated)
│   └── www/                   # ACME challenge files
├── init-letsencrypt.sh        # Certificate initialization script
└── .env                       # Environment variables (DOMAIN, EMAIL, etc.)
```

## Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)

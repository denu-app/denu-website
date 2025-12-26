# Denu Static Website - Nginx-based static file server
FROM nginx:alpine

# Build argument for environment (dev or prod)
ARG BUILD_ENV=dev

# Copy static website files
COPY . /usr/share/nginx/html/

# Swap HTML files based on environment (prod versions have denu.app URLs)
RUN if [ "$BUILD_ENV" = "prod" ]; then \
        cd /usr/share/nginx/html && \
        cp about.html.prod about.html && \
        cp contact.html.prod contact.html && \
        cp index.html.prod index.html && \
        rm -f *.html.prod; \
    else \
        rm -f /usr/share/nginx/html/*.html.prod; \
    fi

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set proper permissions for non-root nginx
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    chmod -R 755 /usr/share/nginx/html && \
    chmod 755 /var/cache/nginx && \
    chmod 755 /var/log/nginx && \
    chmod 755 /etc/nginx/conf.d && \
    # Create all temporary directories with proper permissions
    mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R nginx:nginx /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chmod -R 755 /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

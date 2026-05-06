FROM nginx:1.27-alpine

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy our static site
COPY dist/ /usr/share/nginx/html/

# Custom nginx config (clean URLs, gzip, security headers)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Default nginx CMD is fine

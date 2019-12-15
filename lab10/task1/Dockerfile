FROM alpine:3.9.4
MAINTAINER mbfx
RUN apk add --update nginx \
        && adduser -D -g 'www' www \
        && mkdir /www \
        && chown -R www:www /var/lib/nginx \
        && chown -R www:www /www \
        && mkdir -p /run/nginx/
COPY nginx.conf /etc/nginx/
COPY index.html /www/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

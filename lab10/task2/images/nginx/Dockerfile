FROM nginx:latest
MAINTAINER mbfx
RUN rm /etc/nginx/conf.d/default.conf
COPY ./conf /etc/nginx/conf.d/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

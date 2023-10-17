FROM nginx:alpine
WORKDIR /app
RUN adduser -D -u 1001 -g www www && \
#    mkdir /app && \
    mkdir /run/nginx && \
    chown -R www:www /app &&\
    chown -R www:www /run/nginx && \
    chown -R www:www /var/log/nginx && \
    chown -R www:www /var/cache/nginx
COPY index.html /app/index.html
COPY nginx.conf /etc/nginx/nginx.conf
USER 1001
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
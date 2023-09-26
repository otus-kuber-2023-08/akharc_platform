FROM nginx:alpine
RUN adduser -D -u 1001 -g www www && \
    mkdir /app && \
    mkdir /run/nginx && \
    chown -R www:www /app &&\
    chown -R www:www /run/nginx && \
    chown -R www:www /var/log/nginx && \
    chown -R www:www /var/cache/nginx
RUN wget -O- https://tinyurl.com/otus-k8s-intro | sh
COPY nginx.conf /etc/nginx/nginx.conf
USER 1001
EXPOSE 8000
CMD ["nginx", "-g", "daemon off;"]
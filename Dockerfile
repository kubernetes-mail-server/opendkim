FROM alpine:latest

ARG TZ=/etc/localtime

COPY opendbx /app/opendbx
COPY supervisord-conf /etc/
# apparently don't need this anymore
# echo "@edge ${ALPINE_MIRROR}/edge/main" >> /etc/apk/repositories; \
RUN apk update \
    && apk add --virtual .build alpine-sdk git sudo \
    && adduser -D build \
    && addgroup build abuild \
    && mkdir -p /etc/sudoers.d \
    && echo 'build ALL=(ALL) NOPASSWD: /bin/mkdir, /bin/cp' > /etc/sudoers.d/build

RUN sudo -u build abuild-keygen -a -n -i \
    && rm /etc/sudoers.d/build \
    && chown -R build /app \
    && chmod -R 777 /app/opendbx 

RUN cd /app/opendbx \
    && sudo -u build abuild checksum \
    && sudo -u build abuild -r

RUN cd /tmp \
    && sudo -u build git init \
    && sudo -u build git config --global --add safe.directory /tmp \
    && sudo -u build git remote add origin -f git://git.alpinelinux.org/aports \
    && sudo -u build git config core.sparsecheckout true \
    && echo "community/opendkim/*" >> .git/info/sparse-checkout \
    && sudo -u build git pull origin master \
    && echo '/home/build/packages/app' >> /etc/apk/repositories \
    && apk update \
    && mv /tmp/community/opendkim /app/opendkim

RUN cd /app/opendkim/ \
    && apkgrel -a . \
    && sudo -u build abuild checksum && sudo -u build abuild -r \
    && apk add --no-cache opendkim supervisor rsyslog tzdata

RUN cd /app/opendkim/ \
    && apk del .build \
    && deluser --remove-home build \
    && rm -Rf /app /tmp/community /tmp/.git \
    && install -d -o opendkim -g opendkim /run/opendkim

COPY config /etc/opendkim
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8891/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord","--configuration","/etc/supervisord.conf"]
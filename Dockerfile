FROM alpine:3.8

ARG TZ=/etc/localtime
ARG ALPINE_VERSION=3.8
ARG ALPINE_MIRROR=http://nl.alpinelinux.org/alpine

COPY opendbx /app/opendbx
COPY supervisord-conf /etc/

RUN set -xe; \
    echo ${ALPINE_MIRROR}/v${ALPINE_VERSION}/main > /etc/apk/repositories; \
    echo ${ALPINE_MIRROR}/v${ALPINE_VERSION}/community >> /etc/apk/repositories; \
    echo "@edge ${ALPINE_MIRROR}/edge/main" >> /etc/apk/repositories; \
    cat /etc/apk/repositories; \
    apk update; \
    apk add --virtual .build alpine-sdk git; \
    adduser -D build; \
    addgroup build abuild; \
    echo 'build ALL=(ALL) NOPASSWD: /bin/mkdir, /bin/cp' > /etc/sudoers.d/build; \
    sudo -u build abuild-keygen -a -n -i; \
    rm /etc/sudoers.d/build; \
    chown -R build /app; \
    cd /app/opendbx; \
    chmod -R 777 /app/opendbx; \
    sudo -u build abuild checksum && sudo -u build abuild -r; \
    cd /tmp; \
    sudo -u build git init; \
    sudo -u build git remote add origin -f git://git.alpinelinux.org/aports; \
    sudo -u build git config core.sparsecheckout true; \
    echo "community/opendkim/*" >> .git/info/sparse-checkout; \
    sudo -u build git pull origin 3.8-stable; \
    echo '/home/build/packages/app' >> /etc/apk/repositories; \
    apk update; \
    mv /tmp/community/opendkim /app/opendkim; \
    cd /app/opendkim/; \
    sed -i '/sysconfdir.*/a \\t\t--with-odbx \\' APKBUILD; \
    sed -i 's/\(makedepends="\)/\1opendbx-dev /' APKBUILD; \
    apkgrel -a .; \
    sudo -u build abuild checksum && sudo -u build abuild -r; \
    apk add --no-cache opendkim supervisor rsyslog tzdata; \
    apk del .build; \
    deluser --remove-home build; \
    rm -Rf /app /tmp/community /tmp/.git; \
    install -d -o opendkim -g opendkim /run/opendkim

COPY config /etc/opendkim
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8891/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord","--configuration","/etc/supervisord.conf"]
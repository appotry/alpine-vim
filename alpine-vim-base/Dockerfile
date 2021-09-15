# Multistage builds to reduce image size to ~37MB
# by tuanhtrng
FROM alpine:latest as builder

MAINTAINER andy <andycrusoe@gmail.com>

WORKDIR /tmp

COPY *.ttc /usr/share/fonts/

ARG CA_BUNDLE_SOURCE=https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
ARG CA_BUNDLE_DESTINATION=/usr/local/share/ca-certificates/rds-combined-ca-bundle.pem
ADD $CA_BUNDLE_SOURCE $CA_BUNDLE_DESTINATION
RUN cat $CA_BUNDLE_DESTINATION >> /etc/ssl/certs/ca-certificates.crt && \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
        ca-certificates \
        wget \
        curl \
        ttf-dejavu \
        font-adobe-100dpi && \
    update-ca-certificates 2>/dev/null || true && \
    fc-cache -f && \
    fc-list

ENV LANG=C.UTF-8
# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.34-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Install build tools
RUN echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/main' > /etc/apk/repositories && \
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community' >> /etc/apk/repositories && \
    apk add --no-cache zlib-dev bzip2-dev pcre-dev openssl-dev ncurses-dev sqlite-dev readline-dev tk-dev && \
    apk add --no-cache gcc g++ make cmake

# Install dependencies
RUN apk add --no-cache \
    build-base \
    ctags \
    git \
    libx11-dev \
    libxpm-dev \
    libxt-dev \
    ncurses-dev \
    python3 \
    python3-dev \
    py-pip

# Build vim from git source
ENV pythonver=3.9
RUN git clone https://github.com/vim/vim \
 && cd vim \
 && ./configure \
    --disable-gui \
    --disable-netbeans \
    --enable-multibyte \
    --enable-pythoninterp \
    --with-features=big \
    --enable-pythoninterp=yes \
    --enable-cscope \
    --enable-fontset \
    --with-python3-config-dir=/usr/lib/python${pythonver}/config-${pythonver}-x86_64-linux-musl/ \
    --enable-python3interp=yes \
    --with-python3-command=python${pythonver} \
 && make install
 
 FROM alpine:latest
 
 COPY --from=builder /usr/local/bin/ /usr/local/bin
 COPY --from=builder /usr/local/share/vim/ /usr/local/share/vim/
 # NOTE: man page is ignored
 
 RUN apk add --no-cache \
    diffutils \
    libice \
    libsm \
    libx11 \
    libxt \
    ncurses

ENTRYPOINT ["vim"]

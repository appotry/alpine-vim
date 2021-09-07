# Multistage builds to reduce image size to ~37MB
# by tuanhtrng
FROM alpine:latest as builder

MAINTAINER andy <andycrusoe@gmail.com>

WORKDIR /tmp

# Install dependencies
RUN echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/main' > /etc/apk/repositories && \
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community' >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
    build-base \
    ctags \
    git \
    libx11-dev \
    libxpm-dev \
    libxt-dev \
    make \
    ncurses-dev \
    python3 \
    python3-dev
    
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py

# Build vim from git source
RUN git clone https://github.com/vim/vim \
 && cd vim \
 && ./configure \
    --disable-gui \
    --disable-netbeans \
    --enable-multibyte \
    --enable-pythoninterp \
    --with-features=big \
    --with-python-config-dir=/usr/lib/python2.7/config \
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

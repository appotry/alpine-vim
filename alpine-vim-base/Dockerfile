# Multistage builds to reduce image size to ~37MB
# by tuanhtrng
FROM alpine:latest as builder

MAINTAINER andy <andycrusoe@gmail.com>

WORKDIR /tmp

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
ENV pythonver=3.10
ENV LDFLAGS="-rdynamic"
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

FROM bloodstar/alpine-vim-base:latest

# chinese font
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

# chinese locale
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

# User config
ENV UID="1000" \
    UNAME="developer" \
    GID="1000" \
    GNAME="developer" \
    SHELL="/bin/bash" \
    UHOME=/home/developer

# Used to configure YouCompleteMe
ENV GOROOT="/usr/lib/go"
ENV GOBIN="$GOROOT/bin"
ENV GOPATH="$UHOME/workspace"
ENV PATH="$PATH:$GOBIN:$GOPATH/bin"

# User
RUN echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/main' > /etc/apk/repositories && \
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community' >> /etc/apk/repositories && \
    apk update && \
    apk --no-cache add sudo \
# Create HOME dir
    && mkdir -p "${UHOME}" \
    && chown "${UID}":"${GID}" "${UHOME}" \
# Create user
    && echo "${UNAME}:x:${UID}:${GID}:${UNAME},,,:${UHOME}:${SHELL}" \
    >> /etc/passwd \
    && echo "${UNAME}::17032:0:99999:7:::" \
    >> /etc/shadow \
# No password sudo
    && echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" \
    > "/etc/sudoers.d/${UNAME}" \
    && chmod 0440 "/etc/sudoers.d/${UNAME}" \
# Create group
    && echo "${GNAME}:x:${GID}:${UNAME}" \
    >> /etc/group

# Install Pathogen
RUN apk --no-cache add curl \
    && mkdir -p \
    $UHOME/bundle \
    $UHOME/.vim/autoload \
    $UHOME/.vim_runtime/temp_dirs \
    && curl -LSso \
    $UHOME/.vim/autoload/pathogen.vim \
    https://tpo.pe/pathogen.vim \
    && echo "execute pathogen#infect('$UHOME/bundle/{}')" \
    > $UHOME/.vimrc \
    && echo "syntax on " \
    >> $UHOME/.vimrc \
    && echo "filetype plugin indent on " \
    >> $UHOME/.vimrc \
# Cleanup
    && apk del curl

# Vim wrapper
COPY run /usr/local/bin/
#custom .vimrc stub
RUN mkdir -p /ext  && echo " " > /ext/.vimrc

COPY .vimrc $UHOME/my.vimrc

COPY .bashrc $UHOME/.bashrc

# Vim plugins deps
RUN apk --update --no-cache add \
    bash \
    ctags \
    curl \
    git \
    ncurses-terminfo \
    python3 \
    python3-dev \
    py-pip \
    linux-headers \
# YouCompleteMe
    && echo "install build env" \
    && apk add --no-cache --virtual build-deps \
    build-base \
    cmake \
    go \
    llvm \
    perl \
    python3-dev \
    && git clone --depth 1  https://github.com/Valloric/YouCompleteMe \
    $UHOME/bundle/YouCompleteMe/ \
    && cd $UHOME/bundle/YouCompleteMe \
    && git submodule update --init --recursive \
    && $UHOME/bundle/YouCompleteMe/install.py --gocode-completer \
# Install and compile procvim.vim  
    && echo "Install and compile procvim.vim" \
    && git clone --depth 1 https://github.com/Shougo/vimproc.vim \
    $UHOME/bundle/vimproc.vim \
    && cd $UHOME/bundle/vimproc.vim \
    && make \
    && chown $UID:$GID -R $UHOME \
# Cleanup
    && echo "Cleanup" \
    && apk del build-deps \
    && apk add --no-cache \
    libxt \
    libx11 \
    libstdc++ \
    && rm -rf \
    $UHOME/bundle/YouCompleteMe/third_party/ycmd/clang_includes \
    $UHOME/bundle/YouCompleteMe/third_party/ycmd/cpp \
    /usr/lib/go \
    /var/cache/* \
    /var/log/* \
    /var/tmp/* \
    && mkdir /var/cache/apk

USER $UNAME

# Plugins
RUN cd $UHOME/bundle/ \
    && git clone --depth 1 https://github.com/pangloss/vim-javascript \
    && git clone --depth 1 https://github.com/scrooloose/nerdcommenter \
    && git clone --depth 1 https://github.com/godlygeek/tabular \
    && git clone --depth 1 https://github.com/Raimondi/delimitMate \
    && git clone --depth 1 https://github.com/nathanaelkane/vim-indent-guides \
    && git clone --depth 1 https://github.com/groenewege/vim-less \
    && git clone --depth 1 https://github.com/othree/html5.vim \
    && git clone --depth 1 https://github.com/elzr/vim-json \
    && git clone --depth 1 https://github.com/bling/vim-airline \
    && git clone --depth 1 https://github.com/easymotion/vim-easymotion \
    && git clone --depth 1 https://github.com/mbbill/undotree \
    && git clone --depth 1 https://github.com/majutsushi/tagbar \
    && git clone --depth 1 https://github.com/vim-scripts/EasyGrep \
    && git clone --depth 1 https://github.com/jlanzarotta/bufexplorer \
    && git clone --depth 1 https://github.com/kien/ctrlp.vim \
    && git clone --depth 1 https://github.com/scrooloose/nerdtree \
    && git clone --depth 1 https://github.com/jistr/vim-nerdtree-tabs \
    && git clone --depth 1 https://github.com/scrooloose/syntastic \
    && git clone --depth 1 https://github.com/tomtom/tlib_vim \
    && git clone --depth 1 https://github.com/marcweber/vim-addon-mw-utils \
    && git clone --depth 1 https://github.com/vim-scripts/taglist.vim \
    && git clone --depth 1 https://github.com/terryma/vim-expand-region \
    && git clone --depth 1 https://github.com/tpope/vim-fugitive \
    && git clone --depth 1 https://github.com/airblade/vim-gitgutter \
    && git clone --depth 1 https://github.com/fatih/vim-go \
    && git clone --depth 1 https://github.com/plasticboy/vim-markdown \
    && git clone --depth 1 https://github.com/michaeljsmith/vim-indent-object \
    && git clone --depth 1 https://github.com/terryma/vim-multiple-cursors \
    && git clone --depth 1 https://github.com/tpope/vim-repeat \
    && git clone --depth 1 https://github.com/tpope/vim-surround \
    && git clone --depth 1 https://github.com/vim-scripts/mru.vim \
    && git clone --depth 1 https://github.com/vim-scripts/YankRing.vim \
    && git clone --depth 1 https://github.com/tpope/vim-haml \
    && git clone --depth 1 https://github.com/SirVer/ultisnips \
    && git clone --depth 1 https://github.com/honza/vim-snippets \
    && git clone --depth 1 https://github.com/derekwyatt/vim-scala \
    && git clone --depth 1 https://github.com/christoomey/vim-tmux-navigator \
    && git clone --depth 1 https://github.com/ekalinin/Dockerfile.vim \
# Theme
    && git clone --depth 1 \
    https://github.com/altercation/vim-colors-solarized
    
# Build default .vimrc
RUN  mv -f $UHOME/.vimrc $UHOME/.vimrc~ \
     && curl -s \
     https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim \
     >> $UHOME/.vimrc~ \
     && curl -s \
     https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/extended.vim \
     >> $UHOME/.vimrc~ \
     && cat  $UHOME/my.vimrc \
     >> $UHOME/.vimrc~ \
     && rm $UHOME/my.vimrc \
     && sed -i '/colorscheme peaksea/d' $UHOME/.vimrc~

# Pathogen help tags generation
RUN vim -E -c 'execute pathogen#helptags()' -c q ; return 0

ENV TERM=xterm-256color

# List of Vim plugins to disable
ENV DISABLE=""

ENTRYPOINT ["sh", "/usr/local/bin/run"]

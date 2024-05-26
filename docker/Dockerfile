FROM debian:12-slim

ARG CONTAINER_GID=10000
ARG CONTAINER_UID=10000

ENV DEBIAN_FRONTEND "noninteractive"
ENV STEAM_APP_ID "2089300"
ENV HOME "/home/steam"
ENV STEAM_PATH "/home/steam/Steam"
ENV ICARUS_PATH "/home/steam/icarus"
ENV GE_PROTON_VERSION "8-30"
ENV GE_PROTON_URL "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${GE_PROTON_VERSION}/GE-Proton${GE_PROTON_VERSION}.tar.gz"
ENV STEAM_COMPAT_CLIENT_INSTALL_PATH "$STEAM_PATH"
ENV STEAM_COMPAT_DATA_PATH "${STEAM_PATH}/steamapps/compatdata/${STEAM_APP_ID}"
ENV ULWGL_ID 0

# Default Environment Vars
ENV SERVERNAME="Icarus Server"
ENV PORT=17777
ENV QUERYPORT=27015

# Server Settings
ENV JOIN_PASSWORD=""
ENV MAX_PLAYERS=8
ENV ADMIN_PASSWORD="admin"
ENV SHUTDOWN_NOT_JOINED_FOR=-1
ENV SHUTDOWN_EMPTY_FOR=-1
ENV ALLOW_NON_ADMINS_LAUNCH="True"
ENV ALLOW_NON_ADMINS_DELETE="False"
ENV LOAD_PROSPECT=""
ENV CREATE_PROSPECT=""
ENV RESUME_PROSPECT="True"

# Engine.ini Async Timeout
ENV STEAM_ASYNC_TIMEOUT=120

RUN groupadd -g $CONTAINER_GID steam \
    && useradd -g $CONTAINER_GID -u $CONTAINER_UID -m steam \
    && sed -i 's#^Components: .*#Components: main non-free contrib#g' /etc/apt/sources.list.d/debian.sources \
    && echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        procps \
        ca-certificates \
        winbind \
        dbus \
        libfreetype6 \
        wget \
        jq \
        locales \
        lib32gcc-s1 \
        steamcmd \
    && ln -s /usr/games/steamcmd /usr/bin/steamcmd \
    && echo 'LANG="en_US.UTF-8"' > /etc/default/locale \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && rm -f /etc/machine-id \
    && dbus-uuidgen --ensure=/etc/machine-id \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y 

USER steam

RUN mkdir "$ICARUS_PATH" \
    && mkdir -p "${ICARUS_PATH}/Icarus/Saved/Config/WindowsServer" \
    && mkdir -p "${STEAM_PATH}/compatibilitytools.d" \
    && mkdir -p "${STEAM_PATH}/steamapps/compatdata/${STEAM_APP_ID}" \
    && mkdir -p "${HOME}/.steam" \
    && steamcmd +quit \
    && ln -s "${HOME}/.local/share/Steam/steamcmd/linux32" "${HOME}/.steam/sdk32" \
    && ln -s "${HOME}/.local/share/Steam/steamcmd/linux64" "${HOME}/.steam/sdk64" \
    && ln -s "${HOME}/.steam/sdk32/steamclient.so" "${HOME}/.steam/sdk32/steamservice.so" \
    && ln -s "${HOME}/.steam/sdk64/steamclient.so" "${HOME}/.steam/sdk64/steamservice.so" \
    && wget "$GE_PROTON_URL" -O "/home/steam/GE-Proton${GE_PROTON_VERSION}.tgz" \
    && tar -x -C "${STEAM_PATH}/compatibilitytools.d/" -f "/home/steam/GE-Proton${GE_PROTON_VERSION}.tgz" \
    && rm "/home/steam/GE-Proton${GE_PROTON_VERSION}.tgz"
    
COPY entrypoint.sh /home/steam/entrypoint.sh

WORKDIR /home/steam

CMD ["/home/steam/entrypoint.sh"]

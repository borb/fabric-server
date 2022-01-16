FROM alpine:3.15

LABEL org.opencontainers.image.description="Minecraft server with the Fabric modloader"

RUN \
  apk update && \
  apk upgrade && \
  apk add openjdk17-jre-headless curl

# create a user account with uid of 2000 to avoid colliding with any system users potentially made
RUN \
  adduser -DH -u 2000 -h /var/lib/craftserver craftserver && \
  echo 'craftserver:*' | chpasswd -e

COPY docker-entry.sh /usr/local/bin

RUN \
  chmod 755 /usr/local/bin/docker-entry.sh

RUN \
  mkdir /opt/fabric_server_assets && \
  cd /opt/fabric_server_assets && \
  curl -o fabric_server.jar https://meta.fabricmc.net/v2/versions/loader/1.18.1/0.12.12/0.10.2/server/jar && \
  java -jar fabric_server.jar --nogui --initSettings

# expost both java & bedrock ports; especially useful if using the geyser plugin for fabric
EXPOSE 25565/tcp
EXPOSE 19132/udp

VOLUME ["/fabric_server"]
VOLUME ["/fabric_server/mods"]
VOLUME ["/fabric_server/logs"]

ENTRYPOINT ["/usr/local/bin/docker-entry.sh"]

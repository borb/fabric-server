# fabric-server

## what is it?

a minecraft server image for docker, with the fabric loader ready for modding.

## how do i use it?

```shell
$ docker run -e 'MINECRAFT_EULA=true' ghcr.io/borb/fabric-server
```

note: by adding `MINECRAFT_EULA=true` to the run action, you are acknowledging that you agree to the end user license agreement of the minecraft server. you should ensure you read [the eula](https://account.mojang.com/documents/minecraft_eula) prior to acceptance. ignorance implies acceptance.

## what else should i know?

the [Dockerfile](./Dockerfile) specifies three volumes for persistent data storage:

```Dockerfile
VOLUME ["/fabric_server"]
VOLUME ["/fabric_server/mods"]
VOLUME ["/fabric_server/logs"]
```

the first contains the data path. during first boot, the [entry script](./docker-entry.sh) will prepare the eula acceptance (if specified), symlink the server jar and fabric, minecraft server jar paths into this directory, and then run the server. this ensures that whilst this path contains symbolic links which may only make sense in the context of this container, it does not contain server binaries and is suitable for backup. **at no point should this data path be mounted on two concurrently executing servers** - if it does work (which it may not, thanks to the lock file), it can cause **catastrophic damage** to your world and is strongly discouraged.

the second contains the modifications loaded into the minecraft server by the fabric loader: at the very least, for any modifications to work, this _must_ contain the fabric-api. this is specified as a volume so that in the instance you want to share these files with another running minecraft server instance, this can be done by mounting the volume in another container.

the third contains the log files for this instance. this should **not** be shared between running minecraft server instances, and very likely not between any other instance since confusing context between instances may cause misinterpretation of the logs. the purpose for its existence is so that the logs can be mounted into another container for reading outside of the server container.

## how do i edit the configuration files?

**stop the server container**, then mount the (first) fabric server volume in a scratch container. edit the configurations as required. if you want to make the adjustments prior to first start, pull `/opt/fabric_server_assets/server.properties` from the fabric-server container image and place it in the root of the volume (don't worry, permissions will be fixed on startup) and make any required adjustments.

## how do i use the fabric server console?

use `docker attach` and speak directly to the commandline. ensure you use the correct detach sequence to disconnect from the server console - **do not press ctrl-c** otherwise it will shut your server down.

## how do i import my world into this server? or adjust any files in the server data tree, such as server icon?

create (or mount) the server data volume and use a scratch container to adjust the volume contents. place your `world` directory in the root of the container. this should contain your world data, e.g. `icon.png`, `level.dat`, `region`, `playerdata`, etc. - the fabric server container will fix up any permissions before startup, so don't worry about those.

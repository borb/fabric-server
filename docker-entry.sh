#!/bin/sh
if [ -n "$@" ]; then
    exec $@
fi

_mc_basedir="/fabric_server"
_mc_eula="${_mc_basedir}/eula.txt"
_java_args="${JAVA_ARGUMENTS:--Xms2G -Xmx2G}"

# permissions
{
    echo -n "Resetting permissions on ${_mc_basedir}: "
    chown -PR craftserver:craftserver ${_mc_basedir}
    echo "done."
}

# eula
{
    if [ -r "${_mc_eula}" ]; then
        echo "Found EULA file in server tree - not touching"
    elif [ -n "$MINECRAFT_EULA" -a ! -e "${_mc_eula}" ]; then
        echo -n "Didn't find EULA file in server tree - creating with acceptance value of \"$MINECRAFT_EULA\": "
        ( echo -n "# eula accepted during container creation, date: "; date; echo "eula=$MINECRAFT_EULA" ) > "${_mc_eula}"
        echo "created."
    else
        echo -e "WARNING! Could not find Minecraft EULA file in server tree (\"${_mc_eula}\") - server may not start." \
            "You may need to manually create or adjust this file to start the server.\n" \
            "Ensure you read https://account.mojang.com/documents/minecraft_eula prior to acceptance!"
    fi
}

# check if the server tree has been built or not (if it's an empty server, this will likely lack a server.properties file)
{
    if [ ! -r "${_mc_basedir}/server.properties" ]; then
        echo -n "Building initial server layout: "
        cd "${_mc_basedir}"

        # build the server base files (symbolic link to the java server path)
        find /opt/fabric_server_assets \
            -mindepth 1 \
            -maxdepth 1 \
            ! -name eula.txt \
            -a ! -name server.properties \
            -a ! -name logs \
            -a ! -name mods \
            -a ! -name .fabric \
            -exec ln -s {} \;

        # build the remaining important paths (these may exist already)
        mkdir -p logs mods .fabric
        chown craftserver:craftserver logs mods .fabric

        # link in paths from .fabric subdir
        (
            cd .fabric
            find /opt/fabric_server_assets/.fabric \
                -mindepth 1 \
                -maxdepth 1 \
                -exec ln -s {} \;
        )

        echo "done."
    fi
}

# start the server
{
    echo "About to start Minecraft server. Messages from the server software will follow."
    cd "${_mc_basedir}"
    exec su craftserver -c -- "java ${_java_args} -jar fabric_server.jar --nogui"
}

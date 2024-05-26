#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

configPath="${ICARUS_PATH}/Icarus/Saved/Config/WindowsServer"

# Install/Update Icarus
echo "$(timestamp) INFO: Updating Icarus Dedicated Server"
steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$ICARUS_PATH" +login anonymous +app_update ${STEAM_APP_ID} validate +quit

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Enshrouded"
    exit 1
fi

# Check for proper save permissions
if ! touch "${ICARUS_PATH}/Icarus/Saved/Config/WindowsServer/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of /home/steam/icarus/Icarus/Saved/Config/WindowsServer is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by 10000:10000"
    echo "from your container host attempt the following command 'chown -R 10000:10000 /your/icarus/folder'"
    echo ""
    exit 1
fi

rm "${ICARUS_PATH}/Icarus/Saved/Config/WindowsServer/test"


echo ==============================================================
echo Setting Steam Async Timeout value in Engine.ini to $STEAM_ASYNC_TIMEOUT
echo ==============================================================

# Modify server config to match our arguments
engineIni="${configPath}/Engine.ini"
if [[ ! -e ${engineIni} ]]; then
  mkdir -p ${configPath}
  touch ${engineIni}
fi

if ! grep -Fq "[OnlineSubsystemSteam]" ${engineIni}
then
    echo '[OnlineSubsystemSteam]' >> ${engineIni}
    echo 'AsyncTaskTimeout=' >> ${engineIni}
fi

sedCommand="/AsyncTaskTimeout=/c\AsyncTaskTimeout=${STEAM_ASYNC_TIMEOUT}"
sed -i ${sedCommand} ${engineIni}

echo ==============================================================
echo Setting Server settings in GameUserSettings.ini
echo ==============================================================

echo Session Name       : $SERVERNAME
echo Max Players        : $MAX_PLAYERS
echo Shutdown If Not Joined For : $SHUTDOWN_NOT_JOINED_FOR
echo Shutdown If Empty For      : $SHUTDOWN_EMPTY_FOR
echo Allow Non Admins To Launch Prospects : $ALLOW_NON_ADMINS_LAUNCH
echo Allow Non Admins To Delete Prospects : $ALLOW_NON_ADMINS_DELETE
echo Load Prospect      : $LOAD_PROSPECT
echo Create Prospect    : $CREATE_PROSPECT
echo Resume Prospect    : $RESUME_PROSPECT

serverSettingsIni="${configPath}/ServerSettings.ini"
if [[ ! -e ${serverSettingsIni} ]]; then
  touch ${serverSettingsIni}
fi
chown -R "${STEAM_USERID}":"${STEAM_GROUPID}" ${serverSettingsIni}

if ! grep -Fq "[/Script/Icarus.DedicatedServerSettings]" ${serverSettingsIni}
then
    echo '[/Script/Icarus.DedicatedServerSettings]' >> ${serverSettingsIni}
    echo "SessionName=${SERVERNAME}" >> ${serverSettingsIni}
    echo "JoinPassword=${JOIN_PASSWORD}" >> ${serverSettingsIni}
    echo "MaxPlayers=${MAX_PLAYERS}" >> ${serverSettingsIni}
    echo "AdminPassword=${ADMIN_PASSWORD}" >> ${serverSettingsIni}
    echo "ShutdownIfNotJoinedFor=${SHUTDOWN_NOT_JOINED_FOR}" >> ${serverSettingsIni}
    echo "ShutdownIfEmptyFor=${SHUTDOWN_EMPTY_FOR}" >> ${serverSettingsIni}
    echo "AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_LAUNCH}" >> ${serverSettingsIni}
    echo "AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_DELETE}" >> ${serverSettingsIni}
    echo "LoadProspect=${LOAD_PROSPECT}" >> ${serverSettingsIni}
    echo "CreateProspect=${CREATE_PROSPECT}" >> ${serverSettingsIni}
    echo "ResumeProspect=${RESUME_PROSPECT}" >> ${serverSettingsIni}
fi

sed -i "/SessionName=/c\SessionName=${SERVERNAME}" ${serverSettingsIni}
sed -i "/JoinPassword=/c\JoinPassword=${JOIN_PASSWORD}" ${serverSettingsIni}
sed -i "/MaxPlayers=/c\MaxPlayers=${MAX_PLAYERS}" ${serverSettingsIni}
sed -i "/AdminPassword=/c\AdminPassword=${ADMIN_PASSWORD}" ${serverSettingsIni}
sed -i "/ShutdownIfNotJoinedFor=/c\ShutdownIfNotJoinedFor=${SHUTDOWN_NOT_JOINED_FOR}" ${serverSettingsIni}
sed -i "/ShutdownIfEmptyFor=/c\ShutdownIfEmptyFor=${SHUTDOWN_EMPTY_FOR}" ${serverSettingsIni}
sed -i "/AllowNonAdminsToLaunchProspects=/c\AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_LAUNCH}" ${serverSettingsIni}
sed -i "/AllowNonAdminsToDeleteProspects=/c\AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_DELETE}" ${serverSettingsIni}
sed -i "/LoadProspect=/c\LoadProspect=${LOAD_PROSPECT}" ${serverSettingsIni}
sed -i "/CreateProspect=/c\CreateProspect=${CREATE_PROSPECT}" ${serverSettingsIni}
sed -i "/ResumeProspect=/c\ResumeProspect=${RESUME_PROSPECT}" ${serverSettingsIni}

# Link logfile to stdout of pid 1 so we can see logs
ln -sf /proc/1/fd/1 "${ICARUS_PATH}/Icarus/Saved/Logs/Icarus.log"

# Launch Icarus
echo "$(timestamp) INFO: Starting Icarus Dedicated Server"

${STEAM_PATH}/compatibilitytools.d/GE-Proton${GE_PROTON_VERSION}/proton run ${ICARUS_PATH}/Icarus/Binaries/Win64/IcarusServer-Win64-Shipping.exe \
  -Log \
  -SteamServerName="${SERVERNAME}" \
  -PORT="${PORT}" \
  -QueryPort="${QUERYPORT}" \
 &

 # Find pid for IcarusServer-Win64-Shipping.exe
timeout=0
while [ $timeout -lt 11 ]; do
    if ps -e | grep "IcarusServer-Win64-Shipping.exe"; then
        icarus_pid=$(ps -e | grep "IcarusServer-Win64-Shipping.exe" | awk '{print $1}')
        break
    elif [ $timeout -eq 10 ]; then
        echo "$(timestamp) ERROR: Timed out waiting for IcarusServer-Win64-Shipping.exe to be running"
        exit 1
    fi
    sleep 6
    ((timeout++))
    echo "$(timestamp) INFO: Waiting for IcarusServer-Win64-Shipping.exe to be running"
done

# I don't love this but I can't use `wait` because it's not a child of our shell
tail --pid=$icarus_pid -f /dev/null

# If we lose our pid, exit container
echo "$(timestamp) ERROR: He's dead, Jim"
exit 1

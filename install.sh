#!/usr/bin/bash
#check for arch flag
if [ "$1" == "arm64" ]; then
    feishin_arch="arm64"
else
    feishin_arch="x64"
fi

feishin_latest_version=$(wget github.com/jeffvli/feishin/releases/latest -q -O - | grep "<title>" | grep -o '[0-9]*[.][0-9]*[.]*[0-9]*\+')
install_dir=$HOME/.local/share/feishin

cd /tmp
rm -Rf feishin* Feishin* icon.png
wget https://github.com/jeffvli/feishin/releases/download/v${feishin_latest_version}/feishin-${feishin_latest_version}-linux-${feishin_arch}.tar.xz
wget https://github.com/jeffvli/feishin/blob/development/assets/icons/icon.png
mkdir -p ${install_dir}

if [ -f feishin-${feishin_latest_version}-linux-${feishin_arch}.tar.xz ];then
    rm -Rf ${install_dir}/*
    tar -xf feishin-${feishin_latest_version}-linux-${feishin_arch}.tar.xz
    mv Feishin-${feishin_latest_version}-linux-${feishin_arch}/* ${install_dir}/
    mv icon.png ${install_dir}/
    rm -Rf Feishin*
else
    echo "erro download"
    exit 2
fi

echo ${feishin_latest_version} > ${install_dir}/version
echo ${feishin_arch} > ${install_dir}/arch

#Create update.sh
cat > ${install_dir}/update.sh <<UPDATESH
#!/bin/bash
install_dir=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
current_version=\$(wget github.com/jeffvli/feishin/releases/latest -q -O - | grep "<title>" | grep -o '[0-9]*[.][0-9]*[.]*[0-9]*\+')
local_version=\$(cat \${install_dir}/version)
local_arch=\$(cat \${install_dir}/arch)
if [ \${current_version} == \${local_version} ] || [ \${current_version} == \"\" ]; then
    notify-send -a feishin -i \${install_dir}/icon.png -t 1 "Latest version installed!"
else
    notify-send -a feishin -i \${install_dir}/icon.png -t 1 "Download new version...!"
    curl https://raw.githubusercontent.com/zicstardust/feishin-linux-installer/main/install.sh | bash -s \${local_arch}
    if [ \$? == "0" ]; then
        notify-send -a feishin -i \${install_dir}/icon.png -t 1 "New version installed!"
    else
        notify-send -a feishin -i \${install_dir}/icon.png -t 1 "error, new version not instaled!"
    fi
fi
exit 2

UPDATESH
chmod +x ${install_dir}/update.sh

#Create uninstall.sh
cat > ${install_dir}/uninstall.sh <<UNINSTALLSH
#!/usr/bin/env bash
install_dir=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
rm -Rf \${install_dir}
rm -f \${HOME}/.local/share/applications/feishin.desktop
notify-send -a feishin -t 1 "feishin removed!"
exit 2

UNINSTALLSH
chmod +x ${install_dir}/uninstall.sh

#Create feishin.desktop
cat > ${HOME}/.local/share/applications/feishin.desktop <<DESKTOPENTRY
[Desktop Entry]
version=${feishin_latest_version}
Name=feishin
Comment=A full-featured Subsonic/Jellyfin compatible desktop music player.
Type=Application
Terminal=false
Exec=${install_dir}/feishin
StartupNotify=true
Icon=${install_dir}/icon.png
Categories=Media;Music;Media;Player;
Keywords=music;player;media;feishin;jellyfin;subsonic;
StartupWMClass=feishin
Actions=Update;Uninstall;
[Desktop Action Update]
Name=Check Update
Exec=${install_dir}/update.sh
[Desktop Action Uninstall]
Name=Uninstall
Exec=${install_dir}/uninstall.sh
DESKTOPENTRY
chmod +x ${HOME}/.local/share/applications/feishin.desktop

echo ""
echo "feishin ${feishin_latest_version} ${feishin_arch} installed!"

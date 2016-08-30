#!/bin/bash

PACKAGENAME="spotifywebplayer"
VERSION="0.8.19"
MAINTAINER="Matthew James"
EMAIL="Quacky2200@hotmail.com"

ELECTRON_VER="1.0.0"
X64_BUILD=1

#TODO: use Electron 1.3.4
if [ "$X64_BUILD" -eq 1 ]; then
	ELECTRON="https://github.com/electron/electron/releases/download/v$ELECTRON_VER/electron-v$ELECTRON_VER-linux-x64.zip"
else
	ELECTRON="https://github.com/electron/electron/releases/download/v$ELECTRON_VER/electron-v$ELECTRON_VER-linux-ia32.zip"
fi

echo "Build $PACKAGENAME.deb"

mkdir -p "$PACKAGENAME/usr/bin"
mkdir -p "$PACKAGENAME/usr/share/pixmaps"
mkdir -p "$PACKAGENAME/usr/share/applications"
mkdir -p "$PACKAGENAME/usr/share/spotifywebplayer"
mkdir -p "$PACKAGENAME/usr/share/spotifywebplayer/lib/electron"

wget -nc -O - "https://github.com/vincent-t/Spotify-Web-Player-for-Linux/archive/master.tar.gz" | tar -xvzf - -C "$PACKAGENAME/usr/bin/spotifywebplayer" --strip-components=1 --exclude='package.json' --exclude='README.md' --exclude='make_release.sh' --exclude='spotifywebplayer.sh' --exclude='plugins_ia32'

wget -nc -O tmp.zip "$ELECTRON" && unzip tmp.zip -d "$PACKAGENAME/usr/bin/spotifywebplayer/lib/electron" && rm tmp.zip


mv "$PACKAGENAME/usr/share/spotifywebplayer/spotify-large-transparent.png" "$PACKAGENAME/usr/share/pixmaps/spotify-web-player.png"


tee "$PACKAGENAME/usr/share/applications/spotifywebplayer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Spotify
GenericName=Spotify Web Player
Comment=Music for every moment. Spotify is a digital music service that gives you access to millions of songs.
Exec=spotifywebplayer
TryExec=spotifywebplayer
Icon=spotify-web-player
Terminal=false
Categories=GNOME;AudioVideo;Player;GTK;Audio;
StartupNotify=false
Actions=Play;Pause;Next;Previous;

[Desktop Action Play]
Name=Play/Pause
Exec=dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotifywebplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause

[Desktop Action Next]
Name=Next
Exec=dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotifywebplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next

[Desktop Action Previous]
Name=Previous
Exec=dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotifywebplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
EOF

#Download and build node modules
pushd "$PACKAGENAME/usr/share/spotifywebplayer"
npm install electron-rebuild --save-dev
npm install userhome
./node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install dbus
./node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install dbus-native
./node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install electron-cookies
./node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install mpris-service
./node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER

rm -rf $(ls -Ad node_modules/* | grep -Ev '^node_modules/userhome$|^node_modules/dbus$|^node_modules/dbus-native$|^node_modules/electron-cookies$|^node_modules/mpris-service$')
popd

#
tee "$PACKAGENAME/usr/bin/spotifywebplayer" << EOF
#!/bin/bash
/usr/share/spotifywebplayer/lib/electron/electron .
EOF

chmod 755 "$PACKAGENAME/usr/bin/spotifywebplayer"

PACKAGESIZE=`du -c $PACKAGENAME | egrep -i 'total|insgesamt' | cut -f1`

mkdir $PACKAGENAME/DEBIAN
tee "$PACKAGENAME/DEBIAN/control" << EOF
Package: $PACKAGENAME
Version: $VERSION
#Architecture: all
#Architecture: i386
Architecture: amd64
Maintainer: $MAINTAINER <$EMAIL>
Installed-Size: $PACKAGESIZE
#Depends: libappindicator, libnotify4, notify-osd, wget, unzip
Depends: libappindicator, libnotify4, notify-osd
Section: base
Priority: optional
Homepage: https://github.com/Quacky2200/Spotify-Web-Player-for-Linux
Description: spotifywebplayer
 A minimal Electron application Music for every moment. Spotify is a digital music service that gives you access to millions of songs.
EOF

fakeroot dpkg-deb --build $PACKAGENAME
rm -rf $PACKAGENAME
echo "$PACKAGENAME.deb successfully build!"

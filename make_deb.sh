#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="spotifywebplayer"
PACKAGE_VERSION="1.0.1"
PACKAGE_MAINTAINER=""
MAINTAINER_EMAIL=""

ELECTRON_VER="1.3.4"
NODE_VER="6.5.0"
FLASH_VER="23.0.0.207"

ELECTRON_TMPFILE="$(mktemp)"
NODE_TMPFILE="$(mktemp)"
FLASH_TMPFILE="$(mktemp)"

if [ "$(uname -m)" = "x86_64" ]; then
	PACKAGE_ARCHITECTURE="amd64"
	ELECTRON_LINK="https://github.com/electron/electron/releases/download/v$ELECTRON_VER/electron-v$ELECTRON_VER-linux-x64.zip"
	NODE_LINK="https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-x64.tar.xz"
	FLASH_LINK="https://fpdownload.adobe.com/pub/flashplayer/pdc/$FLASH_VER/flash_player_ppapi_linux.x86_64.tar.gz"
else
	PACKAGE_ARCHITECTURE="i386"
	ELECTRON_LINK="https://github.com/electron/electron/releases/download/v$ELECTRON_VER/electron-v$ELECTRON_VER-linux-ia32.zip"
	NODE_LINK="https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-x86.tar.xz"
	FLASH_LINK="https://fpdownload.adobe.com/pub/flashplayer/pdc/$FLASH_VER/flash_player_ppapi_linux.i386.tar.gz"
fi

echo "Build $PACKAGE_NAME.deb"

#Create folders
mkdir -p "$DIR/build/$PACKAGE_NAME/usr/bin" "$DIR/build/$PACKAGE_NAME/usr/share/pixmaps" "$DIR/build/$PACKAGE_NAME/usr/share/applications" "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs/electron" "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/plugins"

#Get electron
wget -nc -O "$ELECTRON_TMPFILE" "$ELECTRON_LINK"
unzip "$ELECTRON_TMPFILE" -x \*default_app.asar\* -d "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs/electron"
rm "$ELECTRON_TMPFILE"

#Rename binary
mv "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs/electron/electron" "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs/electron/spotifywebplayer"

#Get node
wget -nc -O "$NODE_TMPFILE" "$NODE_LINK"
tar -xf "$NODE_TMPFILE" -C "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs"
mv "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs/node*" "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/libs/node"
rm "$NODE_TMPFILE"

#Get flashplugin
wget -nc -O "$FLASH_TMPFILE" "$FLASH_LINK"
tar -xvzf "$FLASH_TMPFILE" -C "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/plugins" --strip-components=1 --exclude='LGPL' --exclude='manifest.json' --exclude='README'
rm "$FLASH_TMPFILE"

#Get application
wget -nc -O - "https://github.com/vincent-t/Spotify-Web-Player-for-Linux/archive/master.tar.gz" | tar -xvzf - -C "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" --strip-components=1 --exclude='.gitignore' --exclude='LICENSE' --exclude='make_deb.sh' --exclude='package.json' --exclude='README.md'

cp "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/icons/spotify.png" "$DIR/build/$PACKAGE_NAME/usr/share/pixmaps/spotifywebplayer.png"

tee "$DIR/build/$PACKAGE_NAME/usr/share/applications/spotifywebplayer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Spotify Web Player
GenericName=Spotify
Comment=A minimal Electron application which wraps Spotify Web Player into an application.
Icon=spotifywebplayer
Categories=GNOME;GTK;AudioVideo;Audio;Player;
Exec=spotifywebplayer %U
TryExec=spotifywebplayer
Terminal=false
StartupWMClass=Spotify Web Player
Actions=PlayPause;Next;Previous

[Desktop Action PlayPause]
Name=Play/Pause
Exec=dbus-send --print-reply --reply-timeout=2500 --session --dest=org.mpris.MediaPlayer2.spotifywebplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause

[Desktop Action Next]
Name=Next
Exec=dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotifywebplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next

[Desktop Action Previous]
Name=Previous
Exec=dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotifywebplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
EOF

#Download and build node modules
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" electron-rebuild --save-dev
#auto-launch
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" auto-launch
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#dbus
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" dbus
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#electron-cookies
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" electron-cookies
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#freedesktop-notifications
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" freedesktop-notifications
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#mpris-service
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" mpris-service
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#node-unofficialmxm
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" git+https://github.com/Quacky2200/node-unofficialmxm.git
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#request
npm install --prefix "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME" request
"./$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"

pushd "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME"
rm -rf $(ls -Ad node_modules/* | grep -Ev '^node_modules/auto-launch$|^node_modules/electron-cookies$|^node_modules/dbus$|^node_modules/freedesktop-notifications$|^node_modules/mpris-service$|^node_modules/node-unofficialmxm$|^node_modules/request$')
rm -rf "node_modules/.bin"
popd

rmdir "$DIR/build/$PACKAGE_NAME/opt/$PACKAGE_NAME/etc"

#Create run script
tee "$DIR/build/$PACKAGE_NAME/usr/bin/spotifywebplayer" << EOF
#!/bin/bash
/opt/$PACKAGE_NAME/spotifywebplayer "\$1"
EOF
chmod 755 "$DIR/build/$PACKAGE_NAME/usr/bin/spotifywebplayer"

PACKAGE_SIZE="$(du -c "$DIR/build/$PACKAGE_NAME" | egrep -i 'total|insgesamt' | cut -f1)

mkdir "$DIR/build/$PACKAGE_NAME/DEBIAN"
tee "$DIR/build/$PACKAGE_NAME/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Architecture: $PACKAGE_ARCHITECTURE
Maintainer: $PACKAGE_MAINTAINER <$MAINTAINER_EMAIL>
Installed-Size: $PACKAGE_SIZE
Depends: libappindicator1, libnotify4, notify-osd
Section: base
Priority: optional
Homepage: https://github.com/Quacky2200/Spotify-Web-Player-for-Linux
Description: Spotify Web Player
 A minimal Electron application which wraps Spotify Web Player into an application.
EOF

chmod 0644 "$DIR/build/$PACKAGE_NAME/DEBIAN/control"

fakeroot dpkg-deb --build "$DIR/build/$PACKAGE_NAME"
rm -rf "$DIR/build/$PACKAGE_NAME"
echo "$PACKAGE_NAME.deb successfully build!"

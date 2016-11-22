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
mkdir -p "build/$PACKAGE_NAME/usr/share/pixmaps" "build/$PACKAGE_NAME/usr/share/applications" "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" "build/$PACKAGE_NAME/DEBIAN"

#Get electron
wget -O "$ELECTRON_TMPFILE" "$ELECTRON_LINK"
unzip "$ELECTRON_TMPFILE" -x \*default_app.asar\* -d "build/$PACKAGE_NAME/opt/$PACKAGE_NAME"
rm "$ELECTRON_TMPFILE"
#Rename binary
mv "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/electron" "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/spotifywebplayer"

#Get application
mkdir -p "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app"
wget -O - "https://github.com/vincent-t/Spotify-Web-Player-for-Linux/archive/master.tar.gz" | tar -xvzf - -C "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app" --strip-components=1 --exclude='.gitignore' --exclude='LICENSE' --exclude='make_deb.sh' --exclude='package.json' --exclude='README.md'

#Get node
wget -O "$NODE_TMPFILE" "$NODE_LINK"
tar -xf "$NODE_TMPFILE" -C "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app" --exclude='CHANGELOG.md' --exclude='LICENSE' --exclude='README.md'
if [ "$(uname -m)" = "x86_64" ]; then
	mv "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node-v$NODE_VER-linux-x64" "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node"
else
	mv "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node-v$NODE_VER-linux-x86" "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/node"
fi
rm "$NODE_TMPFILE"

#Get flashplugin
mkdir -p "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/plugins"
wget -O "$FLASH_TMPFILE" "$FLASH_LINK"
tar -xf "$FLASH_TMPFILE" -C "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/plugins" --exclude='LGPL' --exclude='manifest.json' --exclude='README'
rm "$FLASH_TMPFILE"

#Copy Icon
cp "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/resources/app/icons/spotify.png" "build/$PACKAGE_NAME/usr/share/pixmaps/spotifywebplayer.png"

tee "build/$PACKAGE_NAME/usr/share/applications/spotifywebplayer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Spotify Web Player
GenericName=Spotify
Comment=A minimal Electron application which wraps Spotify Web Player into an application.
Icon=spotifywebplayer
Categories=GNOME;GTK;AudioVideo;Audio;Player;
Exec=spotifywebplayer %U
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
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" electron-rebuild --save-dev
#auto-launch
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" auto-launch
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#dbus
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" dbus
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#electron-cookies
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" electron-cookies
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#freedesktop-notifications
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" freedesktop-notifications
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#mpris-service
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" mpris-service
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#node-unofficialmxm
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" git+https://github.com/Quacky2200/node-unofficialmxm.git
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"
#request
npm install --prefix "build/$PACKAGE_NAME/opt/$PACKAGE_NAME" request
"./build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin/electron-rebuild" -v "$ELECTRON_VER" #-n "$NODE_VER"

pushd "build/$PACKAGE_NAME/opt/$PACKAGE_NAME"
rm -rf $(ls -Ad node_modules/* | grep -Ev '^node_modules/auto-launch$|^node_modules/electron-cookies$|^node_modules/dbus$|^node_modules/freedesktop-notifications$|^node_modules/mpris-service$|^node_modules/node-unofficialmxm$|^node_modules/request$')
rm -rf "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/node_modules/.bin"
popd

rmdir "build/$PACKAGE_NAME/opt/$PACKAGE_NAME/etc"

#Create run script
tee "build/$PACKAGE_NAME/usr/bin/spotifywebplayer" << EOF
#!/bin/bash
/opt/$PACKAGE_NAME/spotifywebplayer "\$1"
EOF

chmod 755 "build/$PACKAGE_NAME/usr/bin/spotifywebplayer"

PACKAGE_SIZE="$(du -c "build/$PACKAGE_NAME" | egrep -i 'total|insgesamt' | cut -f1)"

tee "build/$PACKAGE_NAME/DEBIAN/control" << EOF
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

chmod 644 "build/$PACKAGE_NAME/DEBIAN/control"

fakeroot dpkg-deb --build "$DIR/build/$PACKAGE_NAME"
#rm -rf "build/$PACKAGE_NAME"
echo "$PACKAGE_NAME.deb successfully build!"

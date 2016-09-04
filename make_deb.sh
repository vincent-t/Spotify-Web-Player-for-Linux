#!/bin/bash

PACKAGENAME="spotifywebplayer"
VERSION="0.9.4"
MAINTAINER="Matthew James"
EMAIL="Quacky2200@hotmail.com"

ELECTRON_VER="1.3.4"
X64_BUILD=1

if [ "$X64_BUILD" -eq 1 ]; then
	ELECTRON="https://github.com/electron/electron/releases/download/v$ELECTRON_VER/electron-v$ELECTRON_VER-linux-x64.zip"
else
	ELECTRON="https://github.com/electron/electron/releases/download/v$ELECTRON_VER/electron-v$ELECTRON_VER-linux-ia32.zip"
fi

echo "Build $PACKAGENAME.deb"

#Create folders
mkdir -p "$PACKAGENAME/usr/bin" "$PACKAGENAME/usr/share/pixmaps" "$PACKAGENAME/usr/share/applications" "$PACKAGENAME/opt/$PACKAGENAME"

#Get electron
wget -nc -O tmp.zip "$ELECTRON"
unzip tmp.zip -x \*default_app.asar\* -d "$PACKAGENAME/opt/$PACKAGENAME"
rm tmp.zip

#Rename binary
mv "$PACKAGENAME/opt/$PACKAGENAME/electron" "$PACKAGENAME/opt/$PACKAGENAME/spotifywebplayer"

mkdir -p "$PACKAGENAME/opt/$PACKAGENAME/resources/app"

#Get application
wget -nc -O - "https://github.com/vincent-t/Spotify-Web-Player-for-Linux/archive/master.tar.gz" | tar -xvzf - -C "$PACKAGENAME/opt/$PACKAGENAME/resources/app" --strip-components=1 --exclude='README.md' --exclude='make_deb.sh' --exclude='.gitignore' --exclude='libpepflashplayer-ia32.so'

cp "$PACKAGENAME/opt/$PACKAGENAME/resources/app/icons/icon.png" "$PACKAGENAME/usr/share/pixmaps/spotifywebplayer.png"

tee "$PACKAGENAME/usr/share/applications/spotifywebplayer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Spotify Web Player
GenericName=Spotify
Comment=A minimal Electron application which wraps Spotify Web Player into an application.
Icon=spotifywebplayer
Categories=AudioVideo;Audio;Player;GTK;
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
npm install --prefix "$PACKAGENAME/opt/$PACKAGENAME/resources/app" electron-rebuild --save-dev
npm install --prefix "$PACKAGENAME/opt/$PACKAGENAME/resources/app" auto-launch
./$PACKAGENAME/opt/$PACKAGENAME/resources/app/node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install --prefix "$PACKAGENAME/opt/$PACKAGENAME/resources/app" electron-cookies
./$PACKAGENAME/opt/$PACKAGENAME/resources/app/node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install --prefix "$PACKAGENAME/opt/$PACKAGENAME/resources/app" freedesktop-notifications
./$PACKAGENAME/opt/$PACKAGENAME/resources/app/node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install --prefix "$PACKAGENAME/opt/$PACKAGENAME/resources/app" mpris-service
./$PACKAGENAME/opt/$PACKAGENAME/resources/app/node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
npm install --prefix "$PACKAGENAME/opt/$PACKAGENAME/resources/app" request
./$PACKAGENAME/opt/$PACKAGENAME/resources/app/node_modules/.bin/electron-rebuild -v $ELECTRON_VER #-n $_NODE_VER
pushd "$PACKAGENAME/opt/$PACKAGENAME/resources/app"
rm -rf $(ls -Ad node_modules/* | grep -Ev '^node_modules/auto-launch$|^node_modules/electron-cookies$|^node_modules/freedesktop-notifications$|^node_modules/mpris-service$|^node_modules/request$')
rm -rf "node_modules/.bin"
popd
rmdir "$PACKAGENAME/opt/$PACKAGENAME/resources/app/etc"

#Create run script
#TODO: should be /opt/$PACKAGENAME/spotifywebplayer "$1"
tee "$PACKAGENAME/usr/bin/spotifywebplayer" << EOF
#!/bin/bash
/opt/$PACKAGENAME/spotifywebplayer
EOF
chmod 755 "$PACKAGENAME/usr/bin/spotifywebplayer"

PACKAGESIZE=`du -c $PACKAGENAME | egrep -i 'total|insgesamt' | cut -f1`

mkdir $PACKAGENAME/DEBIAN
#NOTE: Other options
#Architecture: all
#Architecture: i386
#Depends: libappindicator, libnotify4, notify-osd, wget, unzip
#Description: spotifywebplayer
# A minimal Electron application Music for every moment. Spotify is a digital music service that gives you access to millions of songs.
tee "$PACKAGENAME/DEBIAN/control" << EOF
Package: $PACKAGENAME
Version: $VERSION
Architecture: amd64
Maintainer: $MAINTAINER <$EMAIL>
Installed-Size: $PACKAGESIZE
Depends: libappindicator1, libnotify4, notify-osd
Section: base
Priority: optional
Homepage: https://github.com/Quacky2200/Spotify-Web-Player-for-Linux
Description: Spotify Web Player
 A minimal Electron application which wraps Spotify Web Player into an application.
EOF

tee "$PACKAGENAME/DEBIAN/prerm" << EOF
killall -q spotifywebplayer
EOF

chmod 0755 "$PACKAGENAME/DEBIAN/prerm"
chmod 0644 "$PACKAGENAME/DEBIAN/control"

fakeroot dpkg-deb --build $PACKAGENAME
rm -rf $PACKAGENAME
echo "$PACKAGENAME.deb successfully build!"

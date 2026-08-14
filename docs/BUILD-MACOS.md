# SooperLooper — macOS build-ohje

Testattu: macOS 26.x (Tahoe), Apple Silicon (arm64), Xcode Command Line Tools, Homebrew.

## Riippuvuudet

```bash
brew install pkg-config autoconf automake libtool \
  jack wxwidgets liblo libsigc++@2 libsndfile libsamplerate \
  libxml2 rubberband fftw ncurses
```

Huomioita:

- **libsigc++@2** — projekti vaatii `sigc++-2.0`, ei libsigc++ 3.x
- **libxml2** ja **ncurses** ovat keg-only → tarvitaan `PKG_CONFIG_PATH`
- **JACK** — standalone-moottori vaatii käynnissä olevan JACK-palvelimen

## Nopea build

```bash
git clone git@github.com:tonihintikka/sooperlooper.git
cd sooperlooper
./scripts/build-macos.sh
./scripts/test-macos.sh          # smoke test
./scripts/test-macos.sh --with-jack   # + JACK-moottori (valinnainen)
```

Binäärit:

| Tiedosto | Kuvaus |
|---|---|
| `src/sooperlooper` | JACK-moottori |
| `src/gui/slgui` | wxWidgets-GUI |
| `src/slconsole` | Konsoliasiakas (testaus) |

## Manuaalinen build

```bash
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:\
/opt/homebrew/opt/libsigc++@2/lib/pkgconfig:\
/opt/homebrew/opt/libxml2/lib/pkgconfig:\
/opt/homebrew/opt/ncurses/lib/pkgconfig"

./autogen.sh
./configure --prefix=/opt/homebrew \
  --with-wxconfig-path=/opt/homebrew/bin/wx-config
make -j"$(sysctl -n hw.ncpu)"
```

## Käyttö

1. Käynnistä JACK:

   ```bash
   jackd -d coreaudio
   ```

   Tai käytä [qjackctl](https://formulae.brew.sh/formula/qjackctl):ia.

2. Käynnistä moottori:

   ```bash
   ./src/sooperlooper
   ```

3. Käynnistä GUI (käynnistää moottorin tarvittaessa):

   ```bash
   ./src/gui/slgui
   ```

## `.app`-paketti

Build + paketoi Finderistä avattava app (ei AU-pluginia):

```bash
brew install dylibbundler   # kerran
./scripts/package-macos-app.sh
open mac/macdist/SooperLooper.app
```

App sisältää `slgui` + `sooperlooper` ja bundlatut dylibit (`Contents/Frameworks/`).

## Tunnetut rajoitukset

- **JackRouter** ei toimi macOS Catalina+:lla — vain JACK-native-sovellukset (SooperLooper ok)
- **Ei-ASCII-laitenimet** (esim. ä/ö laitteen nimessä) voivat rikkoa JACKin laitteen valinnan ([jack2#1017](https://github.com/jackaudio/jack2/issues/1017))
- **AU-plugin** vaatii erillisen Xcode-buildin (`mac/SooperLooperAU/`) — ei vielä modernisoitu
- **`.app`-paketti** — `./scripts/package-macos-app.sh` (AU puuttuu; vanha `mac/stepsnew.sh` vaatii Xcodea)

## Fork vs. upstream

Tämä fork sisältää korjaukset, joita upstreamissa ei vielä ole:

- liblo 0.36 OSC-handler-yhteensopivuus
- arm64-atomiikka (`__atomic`-toteutus Apple Siliconille)

# SooperLooper — modernisointisuunnitelma (macOS)

Fork: [tonihintikka/sooperlooper](https://github.com/tonihintikka/sooperlooper)  
Upstream: [essej/sooperlooper](https://github.com/essej/sooperlooper) (GPL-2.0)

Tavoite: lähdekoodi kääntyy ja paketoituu luotettavasti modernilla macOS:llä (Apple Silicon + uudet Xcode/SDK-versiot).

## Tilannekuva

| Ulottuvuus | Tila |
|---|---|
| Autotools-build (JACK + GUI) | Toimii arm64:llä Homebrew-riippuvuuksilla (fork) |
| liblo 0.36 | Korjattu forkissa (`bade300`) |
| arm64-atomiikka | Korjattu forkissa (`__atomic`-toteutus) |
| `.app`-bundle | Vanhentunut `mac/stepsnew.sh`, ei CI:tä |
| AU-plugin (Xcode) | Hardkoodatut kehittäjäpolut, erillinen build-polku |
| CI | GitHub Actions macOS smoke test (fork) |
| Notarisoitu DMG | Estetty libjack-linkityksellä (hardened runtime) |

Macilla on **kaksi erillistä build-polkuja**:

1. **Autotools** → `sooperlooper` + `slgui` (JACK-standalone)
2. **Xcode** → `SooperLooperAU64.component` (ei vaadi JACKia)

---

## Testaus jokaisen vaiheen jälkeen

**Sääntö:** älä siirry seuraavaan tehtävään ennen kuin testit menevät läpi.

### Nopea smoke test (paikallinen)

```bash
./scripts/build-macos.sh    # tai make, jos jo konfiguroitu
./scripts/test-macos.sh     # binäärit, versio, arm64-atomiikka
./scripts/test-macos.sh --with-jack   # + moottori käynnistyy JACKin kanssa
```

### CI

GitHub Actions `macOS build` ajaa `./scripts/build-macos.sh` + binääritarkistuksen jokaisella pushilla.

### Vaihekohtaiset tarkistukset

| Vaihe | Testaa |
|---|---|
| 1 dev-build | `test-macos.sh`, CI vihreä |
| 2 `.app` | `open macdist/SooperLooper.app`, GUI avautuu |
| 3 AU | `auval -v aumu SLoP Esse`, plugin löytyy DAW:ssa |
| 4 DMG | asennus puhtaalle Macille, Gatekeeper ok |
| 5 arkkitehtuuri | edelliset + loop record/playback -regressio |

---

- [x] Fork `tonihintikka/sooperlooper`, GPL-2.0 säilyy
- [x] liblo 0.36 OSC-handler-korjaus
- [x] Ensimmäinen onnistunut arm64-build Homebrewilla

---

## Vaihe 1 — Luotettava dev-build (P0)

Tavoite: kloonaa → buildaa ilman arvailua.

- [x] arm64-atomiikka `src/atomic.h` + `libs/pbd/pbd/atomic.h`
- [x] `docs/BUILD-MACOS.md` — build-ohje
- [x] `scripts/build-macos.sh` — automatisoitu build
- [x] GitHub Actions: macOS arm64 smoke test
- [ ] `mem_fun` → `std::mem_fn` / lambdat (C++17-yhteensopivuus)
- [ ] Autoconf 2.7x: korvaa `AC_TRY_LINK`, `AC_LANG_CPLUSPLUS`
- [x] Poista vanha SDK-oletus (`MacOSX10.4u.sdk`) — root + pbd: xcrun-autodetect; midi++ vielä avoinna
- [ ] Upstream PR: liblo 0.36 + arm64-atomiikka

**Deliverable:** CI vihreä, README ohjaa Mac-buildiin.

---

## Vaihe 2 — Ajettava `.app`-bundle (P1)

Tavoite: double-click-käynnistys dev-käyttöön.

- [ ] Modernisoi `mac/stepsnew.sh` (Homebrew-polut, ei `/usr/lib`)
- [ ] Palauta/korjaa dylibbundler-integraatio
- [ ] Lisää tai generoi `slgui.icns`
- [ ] Päivitä `macconfigure64univ.sh` Homebrew-wxWidgets-polulla
- [ ] Universal binary (arm64 + x86_64) valinnainen build-optio
- [ ] JACK-käynnistysohje bundle-readmehen

**Deliverable:** `SooperLooper.app` paikalliseen testaukseen.

**Huomio:** JACK toimii vain JACK-native-sovelluksille. JackRouter (CoreAudio-silta) ei toimi Catalina+:lla.

---

## Vaihe 3 — AU-plugin uudelleenrakennettavaksi (P1)

Tavoite: AudioUnit kääntyy ilman kehittäjäkohtaisia polkuja.

- [ ] Poista `/Users/jesse/devstatic`-polut Xcode-projektista
- [ ] Korvaa staattiset `.a`-libit pkg-config / Homebrew -poluilla
- [ ] OSAtomic → C++11/C11 atomics AU PublicUtility-koodissa
- [ ] `xcodebuild`-integraatio CI:hin (erillinen job)
- [ ] Component Manager -legacy: dokumentoi rajoitukset

**Deliverable:** `SooperLooperAU64.component` buildattavissa CI:ssä.

---

## Vaihe 4 — Jakelu laajemmalle yleisölle (P2)

Tavoite: asennettava paketti ilman Gatekeeper-temppuja.

- [ ] Codesign-skriptit (`mac/codesign.sh` jos puuttuu)
- [ ] **AU-only DMG** (ei libjack → helpompi notarisoida)
- [ ] JACK-standalone DMG erikseen (dev/power user)
- [ ] GitHub Releases + checksum
- [ ] Hardened runtime -ratkaisu JACK-linkitykselle (staattinen libjack tai erillinen binary)

**Deliverable:** Notarisoitu AU+GUI-DMG.

---

## Vaihe 5 — Pitkän aikavälin arkkitehtuuri (P3, valinnainen)

- [ ] CoreAudio-backend JACKin rinnalle
- [ ] CMake-migraatio (pitkä projekti)
- [ ] wxWidgets 3.3+ / C++17 siivous
- [ ] AUv3 / VST3 (upstream mainitsi VST:n, ei toteutunut)
- [ ] GCC-14 / clang strictness (#52 upstream)

---

## Prioriteettijärjestys

```
Vaihe 0 ✅ → Vaihe 1 (dev-build) → Vaihe 2 (.app) ─┐
                    └→ Vaihe 3 (AU) ──────────────────┼→ Vaihe 4 (DMG) → Vaihe 5
```

**Live-käyttäjälle (foorumi):** Vaihe 1 → 3 → 4 (AU-first)  
**JACK-routing:** Vaihe 1 → 2 → 4 (vaikeampi notarisoinnin takia)

---

## Riskit

| Riski | Mitigaatio |
|---|---|
| arm64-atomiikka | Testaa loop-recording + stress |
| JACK + notarization | AU-only DMG ensin |
| Upstream passiivinen | Fork ylläpitää |
| Xcode AU legacy | Vaihe 3 pakollinen AU:lle |
| Ei-ASCII audio-laitteet (JACK #1017) | Kiinteä device UID tai JACK 1.9.23+ |

---

## Viitteet

- [Virallinen lataus 1.7.9](https://sonosaurus.com/sooperlooper/download.html) (universal, ei notarisoitu)
- [JACK macOS](https://jackaudio.org/downloads/)
- [Upstream issue #52](https://github.com/essej/sooperlooper/issues/52) (GCC-14)
- [Mac build -ohje](BUILD-MACOS.md)

# ⚔️ EquippedWeapons

> Lightweight WoW (WotLK 3.3.5) addon that shows your Main Hand, Off Hand and Ranged weapon icons on screen with live enchant and gem detection. Fully configurable and localized in 5 languages.

![WoW Version](https://img.shields.io/badge/WoW-3.3.5a%20(Wrath)-blue)
![Version](https://img.shields.io/badge/version-2.0-brightgreen)
![Languages](https://img.shields.io/badge/languages-EN%20%7C%20ES%20%7C%20DE%20%7C%20FR%20%7C%20RU-orange)

## ✨ Features

- 🗡️ Tracks **Main Hand**, **Off Hand** and **Ranged/Relic** slots
- ✨ Live **enchant** and 💎 **gem** detection via tooltip scanning — no hardcoded data
- 🎨 Optional **quality color borders**
- 🔲 Horizontal / Vertical layout with grow direction
- ⚖️ **Per-character or global** settings profile
- 🌐 Localized in **EN, ES, DE, FR, RU**
- ⚙️ Full options panel (`/ew` or ESC → Interface → AddOns)

<img width="338" height="105" alt="Image" src="https://github.com/user-attachments/assets/1f504335-d58b-48ac-956d-b7272bc85003" />
<img width="280" height="100" alt="image" src="https://github.com/user-attachments/assets/e70ac2e4-daa6-46aa-bd3c-b1af9c988e32" />

<img width="585" height="603" alt="Image" src="https://github.com/user-attachments/assets/a17e59c2-947b-4b77-a6de-e0c80201fa39" />
<img width="547" height="88" alt="Image" src="https://github.com/user-attachments/assets/7fd68735-42f2-4328-a096-9f22526fa9e6" />
<img width="258" height="155" alt="Image" src="https://github.com/user-attachments/assets/02efae9d-ec9d-4c3d-ad12-237aad456fd1" />
<img width="542" height="84" alt="Image" src="https://github.com/user-attachments/assets/b1adcfe7-f00b-4eb6-a70c-b773042fb9fb" />

## 📦 Installation

1. Download the ZIP from GitHub and extract it
2. **Rename** the folder from `EquippedWeapons-main` → `EquippedWeapons`  
   *(GitHub adds `-main` automatically — WoW won't load the addon if the folder name doesn't match)*
3. Move the folder into your AddOns directory:
   ```
   World of Warcraft\_wotlk_\Interface\AddOns\EquippedWeapons\
   ```
4. Launch WoW and enable it in the **AddOns** menu at character select

---

## 💬 Slash Commands

| Command | Description |
|---|---|
| `/ew` | Show all commands |
| `/ew reset` | Reset settings |
| `/ew scale <n>` | Change scale (e.g. `1.2`) |
| `/ew lock` / `/ew unlock` | Lock/unlock frame position |
| `/ew borders` | Toggle quality borders |
| `/ew enchants` | Toggle enchant text |
| `/ew gems` | Toggle gem text |
| `/ew vertical` | Toggle vertical layout |
| `/ew short` | Toggle abbreviated text |

---

## 🌐 Localization

Supports `enUS`, `esES/esMX`, `deDE`, `frFR`, `ruRU`. Any other locale falls back to English.  
Want to add a language? Open a PR with a new `localization/localization_XX.lua` file!

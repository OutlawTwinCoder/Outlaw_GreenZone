# TwinCoder Outlaw GreenZone

Bienvenue dans la version remaniée par OutlawTwin / TwinCoder du script de zones vertes pour FiveM. Cette édition supprime les anciennes références, ajoute une interface utilisateur stylée et offre une expérience bilingue prête pour la production.

## ✨ Features / Fonctionnalités
- **Twin Designer UI** – Configure zones inside an OutlawTwin-branded tablet interface with live sliders and toggles.
- **Branded Zones** – Notifications, blips and presets carry the OutlawTwin identity.
- **Bilingual Locales** – English and French JSON locales included. Select your language via `ox_lib` configuration.
- **Custom Commands** – `/outlawzone` to create and `/outlawclear` to remove temporary safe zones.
- **Default Sanctuaries** – Hospital, police plaza and mountain retreat preconfigured with OutlawTwin styling.

## ⚙️ Requirements / Prérequis
- [ox_lib](https://github.com/overextended/ox_lib) (locale & math modules enabled in `fxmanifest.lua`).
- FiveM server running the `cerulean` build or newer.

## 🚀 Installation
1. Copy the folder into your server resources directory.
2. Ensure `ox_lib` is started before `Outlaw_GreenZone`.
3. Add the resource to your `server.cfg`:
   ```cfg
   ensure Outlaw_GreenZone
   ```
4. (Optional) Set the desired locale in `ox_lib` (defaults to English).

## 🕹️ Usage / Utilisation
- Run `/outlawzone` as an admin to open the OutlawTwin designer.
- Ajustez le nom, la bannière, le rayon, les limitations de vitesse et les options de combat directement dans l'interface.
- Remove the active temporary zone with `/outlawclear`.

## 🛠️ Configuration / Personnalisation
- Edit `config.lua` to tweak default persistent zones, notification behaviour and designer commands.
- Adjust colours, text and icons directly in the locale files (`locales/en.json`, `locales/fr.json`).
- To add more preset zones, duplicate an entry inside `Config.GreenZones` and adjust the coordinates / radius.

## 🤝 Credits
Crafted with ❤️ by **OutlawTwin Studio / TwinCoder**.

# GroupWatch

**GroupWatch** is a lightweight World of Warcraft addon that allows you to manage custom lists of players (friends, bad actors, skilled players, pug leads, etc.), assign custom alerts/sounds when you group with them, and attach **multiline notes** that seamlessly appear in tooltips—including unit frames, right-click context menus, and the **Group Finder**!

---

## 🌟 Features

* 📜 **Custom Player Lists**: Create, rename, and manage multiple customized lists with custom alert messages and sound effects.
* 📝 **Multiline Notes Editor**: Add detailed, multiline notes for any player on your lists.
* 🔎 **Group Finder & LFG Tooltip Integration**: Hover over Premade Group listings in LFG to instantly see if the group leader is on one of your lists and view your saved notes.
* 💬 **Context Menu Support**: Right-click players in chat, friends lists, guild rosters, or target frames to instantly add or remove them from your GroupWatch lists.
* 🔔 **Group Alerts**: Receive chat notifications and audio alerts when a watched player joins your party or raid.
* 🎨 **UI Skinning Support**: Automatically skins itself to match **EllesmereUI** or **ElvUI** if installed, while keeping a native WoW aesthetic otherwise.
* 🔘 **Minimap & LDB Button**: Quick-access minimap button with drag-and-drop positioning and LibDataBroker (LDB) integration.
* 🌐 **Multi-language Localization**: Fully localized in English, German, French, Spanish, Italian, Portuguese, Russian, Simplified Chinese, and Traditional Chinese.

---

## 🚀 Slash Commands

Access commands using `/gw` or `/groupwatch`:

* `/gw` or `/gw list` — Toggle the main GroupWatch window.
* `/gw map` — Toggle the minimap button on/off.
* `/gw add <ListName> <Player-Realm>` — Add a player to a specific list.
* `/gw remove <Player-Realm>` — Remove a player from all lists.

---

## 🛠️ How to Use

### 1. Managing Lists & Players
* Open the main window using `/gw` or by left-clicking the Minimap button.
* Click the **`+`** icon at the bottom to create a new list.
* Click the **`+`** icon next to any list header to add a player (`Name-Realm`).
* Select a sound effect for each list via the dropdown menu to trigger custom audio alerts when you group up with listed players.

### 2. Adding Notes
* Click the golden **`N`** button next to a player's name in the main window to open the **Note Editor**.
* Enter multiline notes and click **Save**.
* Hovering over that player in-game (Unit Frames, World, Tooltips, or LFG Search Results) will display your note in the tooltip.

### 3. Quick Adding via Right-Click
* Right-click any player's name in chat, target frame, guild roster, or friends list.
* Hover over the **GroupWatch** context menu entry to instantly add or remove them from your active lists.

---

## 📦 Installation

1. Download the latest release.
2. Extract the `GroupWatch` folder into your World of Warcraft directory:
   `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart your game or load into the world and type `/reload`.

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.html).
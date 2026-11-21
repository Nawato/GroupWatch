# GroupWatch

**GroupWatch** is a lightweight World of Warcraft addon that allows you to manage custom lists of players (friends, bad actors, skilled players, pug leads, etc.), assign custom alerts/sounds when you group with them, and attach **multiline notes** that seamlessly appear in tooltips—including unit frames, right-click context menus, and the **Group Finder**!

---

## 🌟 Features

* 📜 **Custom Player Lists**: Create, rename, and manage multiple customized lists with custom alert messages and sound effects.
* 📝 **Multiline Notes Editor**: Add detailed, multiline notes for any player on your lists.
* 🔎 **Group Finder & LFG Tooltip Integration**: Hover over Premade Group listings in LFG to instantly see if the group leader is on one of your lists and view your saved notes. Applicants who are on your lists are tagged in the applicant viewer, with their notes in the tooltip, role-fit information, and manual Invite/Decline buttons.
* ⚡ **Per-List Auto Actions**: Optionally auto accept or auto decline direct party invites from players on a list, with chat feedback and the list sound.
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
* `/gw sound add <name>` — Add one of your own sound files.
* `/gw sound remove <name>` — Remove a sound file.
* `/gw sound list` — List your sound files.

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

### 4. Auto Actions
* Right-click a list header and open **Auto Actions**.
* **Auto Accept** accepts direct party invites from players on that list; **Auto Decline** declines them. If a player is on lists with conflicting settings, decline wins.
* While the Group Finder applicant viewer is open, matching applicants are tagged, their tooltip shows your notes, and the panel lists their role fit with manual **Invite** / **Decline** buttons.
* Blizzard does not allow addons to accept or decline Group Finder applicants automatically — the manual buttons are the supported path.

### 5. Custom Sound Files
* The addon ships with two sounds of its own — **Bruh** and **Oof** — which are always in the sound list of every list.
* Drop your own `.ogg` or `.mp3` files into the `Sounds` folder inside the GroupWatch addon directory. Any file name works — `BossAlert.ogg` shows up as **BossAlert**.
* **Restart the game completely** afterwards — the client only indexes new media files at startup, so a `/reload` is not enough.
* Register the sound once with `/gw sound add BossAlert`, or pick **Add sound file...** in a list's sound menu and type the name.
* As many sounds as you like. Each one is remembered, and it is marked *(missing file)* if the file is deleted. The full instructions are in `Sounds/README.txt`.

---

## 📦 Installation

1. Download the latest release.
2. Extract the `GroupWatch` folder into your World of Warcraft directory:
   `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart your game or load into the world and type `/reload`.

---

## 🧪 Development

* Run the Lua test suites: `lua5.1 tests/run.lua`, `lua5.1 tests/midnight.lua`, `lua5.1 tests/perf.lua`, `lua5.1 tests/skin.lua`, `lua5.1 tests/auto.lua`.
* Build a release archive with `./package.sh`; the zip is written to `dist/`.
* Pushing a `v*` tag runs the release workflow and publishes the archive.

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.html).
local ADDON_NAME, ns = ...

local L = setmetatable({}, {
	__index = function(t, k)
		return k
	end,
})
ns.L = L

-- =========================================================================
-- English (Default / Fallback for enUS & enGB)
-- =========================================================================
local enUS = {
	SUBTITLE = "Player List",
	LISTS_LABEL = "Lists:",
	DEFAULT_LIST_NAME = "Default",
	DEFAULT_GROUP_MSG = "%s is in your group!",

	-- Sounds
	SOUND_WARNING = "Warning",
	SOUND_RAID_WARNING = "Raid Warning",
	SOUND_BELL = "Bell",
	SOUND_WHISTLE = "Whistle",
	SOUND_READY_CHECK = "Ready Check",
	SOUND_COIN = "Coin / Gold",
	SOUND_ACHIEVEMENT = "Achievement",
	SOUND_EXPLOSION = "Explosion",
	SOUND_NONE = "No Sound",
	SOUND_CUSTOM = "Custom (%s)",

	-- User sound files (dropped into the Sounds/ folder)
	SOUND_USER_ADD = "Add sound file...",
	SOUND_USER_MISSING = "(missing file)",
	MSG_SOUND_FILE_MISSING = "Sound file '%s' not found. Put it in the GroupWatch Sounds folder and restart the game.",
	MSG_SOUND_ADDED = "Sound '%s' added.",
	MSG_SOUND_REMOVED = "Sound '%s' removed.",
	MSG_SOUND_NOT_FOUND = "No sound file named '%s' found. Add it to the Sounds folder and restart the game.",
	MSG_SOUND_NOT_REGISTERED = "No sound file named '%s' is registered.",
	MSG_SOUND_BUNDLED = "'%s' comes with the addon and cannot be removed.",
	MSG_SOUND_BAD_NAME = "That is not a valid sound file name.",
	MSG_SOUND_NO_FILES = "No sound files yet. Use /gw sound add <name> to add one.",
	DIALOG_ADD_SOUND_TEXT = "Sound file name (without extension):",
	HELP_SOUND_ADD = "/gw sound add <name> - add your own sound file",
	HELP_SOUND_REMOVE = "/gw sound remove <name> - remove a sound file",
	HELP_SOUND_LIST = "/gw sound list - list your sound files",

	-- UI Messages & Labels
	NO_PLAYERS_IN_LIST = "(No players on this list)",
	MSG_LIST_NOT_FOUND = "List '%s' does not exist.",
	MSG_PLAYER_ADDED = "%s added to list '%s'.",
	MSG_PLAYER_REMOVED = "%s removed from '%s'.",
	MSG_LIST_EXISTS = "List '%s' already exists.",
	MSG_LIST_CREATED = "New list '%s' created.",
	MSG_CANNOT_DELETE_DEFAULT = "The default list cannot be deleted.",
	MSG_LIST_DELETED = "List '%s' deleted.",
	MSG_SELECT_PLAYER_FIRST = "Please select a player first.",
	MINIMAP_ENABLED = "Minimap button enabled",
	MINIMAP_DISABLED = "Minimap button disabled",

	-- Chat commands
	HELP_HEADER = "Commands:",
	HELP_TOGGLE = "/gw or /gw list - Toggle main window",
	HELP_MAP = "/gw map - Toggle minimap button",
	HELP_ADD = "/gw add <ListName> <Player-Realm>",
	HELP_REMOVE = "/gw remove <Player-Realm>",

	-- Dialogs
	DIALOG_ADD_PLAYER_TEXT = "Enter player name (Name-Realm):",
	DIALOG_ADD = "Add",
	DIALOG_CANCEL = "Cancel",
	DIALOG_NEW_LIST_TEXT = "Enter name of the new list:",
	DIALOG_CREATE = "Create",
	DIALOG_DELETE_LIST_TEXT = "Do you really want to delete the list '%s'?",
	DIALOG_DELETE = "Delete",
	DIALOG_RENAME_LIST_TEXT = "Enter new name for the list:",
	DIALOG_EDIT_NOTE_TEXT = "Note for %s:",
	DIALOG_SAVE = "Save",

	-- Tooltips & Menus
	TOOLTIP_LEFT_CLICK = "Left-click: |cffffffffToggle window|r",
	TOOLTIP_RIGHT_CLICK = "Right-click: |cffffffffList overview|r",
	TOOLTIP_DRAG = "Hold & Drag: |cffffffffMove button|r",
	TOOLTIP_OPEN_WINDOW = "Open main window",
	TOOLTIP_PLAYERS_COUNT = "%s: %d player(s)",
	CONTEXT_REMOVE = "Remove",
	CONTEXT_ADD = "Add",
	CONTEXT_LIST = "List: %s",
	RENAME_LIST = "Rename List",
	DELETE_LIST = "Delete List",
	CHANGE_SOUND_ALERT = "Change Sound Alert",
	EDIT_NOTE = "Edit Note",
	MOVE_TO_LIST = "Move to List",
	COPY_TO_LIST = "Copy to List",

	-- Auto actions (direct party invites only)
	AUTO_ACTIONS = "Auto Actions",
	AUTO_ACCEPT = "Auto Accept (direct invites)",
	AUTO_DECLINE = "Auto Decline (direct invites)",
	AUTO_LFG_MANUAL = "LFG applicant decisions require a manual click.",
	MSG_AUTO_ACCEPTED = "Auto-accepted invite from %s (list '%s').",
	MSG_AUTO_DECLINED = "Auto-declined invite from %s (list '%s').",
	MSG_AUTO_SKIPPED = "Auto action skipped for %s: %s",
	MSG_AUTO_FAILED = "Auto action failed for %s: %s",
	MSG_AUTO_RESTRICTED = "Auto actions are restricted by the client for this session.",
	MSG_AUTO_BLOCKED = "The client blocked automatic invite handling; auto actions are disabled for this session.",
	MSG_AUTO_API_MISSING = "API unavailable",
	MSG_LFG_MATCH = "%s is on your list '%s'.",
	MSG_LFG_RESTRICTED = "LFG applicant details are restricted by the client.",
	MSG_LFG_FAILED = "LFG action failed: %s",
	LFG_PANEL_TITLE = "GroupWatch matches",
	LFG_INVITE = "Invite",
	LFG_DECLINE = "Decline",
	LFG_NO_MATCHES = "No matches",
	LFG_ROLE_TANK = "Tank",
	LFG_ROLE_HEALER = "Healer",
	LFG_ROLE_DAMAGE = "DPS",
	LFG_ROLE_UNKNOWN = "Role fit unavailable",
	LFG_ROLE_NO_FIT = "No free role",
	LFG_ROLE_FIT = "Role fits",
	LFG_SLOTS_FULL = "Group full",
	LFG_SLOTS_AVAILABLE = "%d slot(s) free",
	LFG_MORE = "+%d more",

	-- Notes
	NOTE_HEADER = "Note",
	NOTE_TOOLTIP = "Note: %s\n\nClick to edit",
	NOTE_TOOLTIP_EMPTY = "No note — click to add",
}

for k, v in pairs(enUS) do
	L[k] = v
end

local locale = GetLocale()

-- =========================================================================
-- German (deDE)
-- =========================================================================
if locale == "deDE" then
	L["SUBTITLE"] = "Spielerliste"
	L["LISTS_LABEL"] = "Listen:"
	L["DEFAULT_LIST_NAME"] = "Standard"
	L["DEFAULT_GROUP_MSG"] = "%s ist in deiner Gruppe!"

	L["SOUND_WARNING"] = "Warn-Ton"
	L["SOUND_RAID_WARNING"] = "Raid-Warnung"
	L["SOUND_BELL"] = "Glocke"
	L["SOUND_WHISTLE"] = "Pfeifen"
	L["SOUND_READY_CHECK"] = "Ready Check"
	L["SOUND_COIN"] = "Münze / Gold"
	L["SOUND_ACHIEVEMENT"] = "Erfolg"
	L["SOUND_EXPLOSION"] = "Explosion"
	L["SOUND_NONE"] = "Kein Sound"
	L["SOUND_CUSTOM"] = "Benutzerdefiniert (%s)"

	L["SOUND_USER_ADD"] = "Sounddatei hinzufügen..."
	L["SOUND_USER_MISSING"] = "(Datei fehlt)"
	L["MSG_SOUND_FILE_MISSING"] = "Sounddatei '%s' nicht gefunden. Lege sie in den GroupWatch-Ordner Sounds und starte das Spiel neu."
	L["MSG_SOUND_ADDED"] = "Sound '%s' hinzugefügt."
	L["MSG_SOUND_REMOVED"] = "Sound '%s' entfernt."
	L["MSG_SOUND_NOT_FOUND"] = "Keine Sounddatei '%s' gefunden. Lege sie in den Ordner Sounds und starte das Spiel neu."
	L["MSG_SOUND_NOT_REGISTERED"] = "Keine Sounddatei namens '%s' ist eingetragen."
	L["MSG_SOUND_BUNDLED"] = "'%s' ist im Addon enthalten und kann nicht entfernt werden."
	L["MSG_SOUND_BAD_NAME"] = "Das ist kein gültiger Name einer Sounddatei."
	L["MSG_SOUND_NO_FILES"] = "Noch keine Sounddateien. Nutze /gw sound add <Name>, um eine hinzuzufügen."
	L["DIALOG_ADD_SOUND_TEXT"] = "Name der Sounddatei (ohne Endung):"
	L["HELP_SOUND_ADD"] = "/gw sound add <Name> - eigene Sounddatei hinzufügen"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <Name> - Sounddatei entfernen"
	L["HELP_SOUND_LIST"] = "/gw sound list - eigene Sounddateien auflisten"

	L["NO_PLAYERS_IN_LIST"] = "(Keine Spieler auf dieser Liste)"
	L["MSG_LIST_NOT_FOUND"] = "Liste '%s' existiert nicht."
	L["MSG_PLAYER_ADDED"] = "%s zur Liste '%s' hinzugefügt."
	L["MSG_PLAYER_REMOVED"] = "%s aus '%s' entfernt."
	L["MSG_LIST_EXISTS"] = "Liste '%s' existiert bereits."
	L["MSG_LIST_CREATED"] = "Neue Liste '%s' erstellt."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "Die 'Standard'-Liste kann nicht gelöscht werden."
	L["MSG_LIST_DELETED"] = "Liste '%s' gelöscht."
	L["MSG_SELECT_PLAYER_FIRST"] = "Bitte erst einen Spieler anklicken."
	L["MINIMAP_ENABLED"] = "Minimap-Button aktiviert"
	L["MINIMAP_DISABLED"] = "Minimap-Button deaktiviert"

	L["HELP_HEADER"] = "Befehle:"
	L["HELP_TOGGLE"] = "/gw oder /gw list - Fenster öffnen/schließen"
	L["HELP_MAP"] = "/gw map - Minimap-Button ein-/ausblenden"
	L["HELP_ADD"] = "/gw add <ListenName> <Spieler-Realm>"
	L["HELP_REMOVE"] = "/gw remove <Spieler-Realm>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "Spielername eingeben (Name-Realm):"
	L["DIALOG_ADD"] = "Hinzufügen"
	L["DIALOG_CANCEL"] = "Abbrechen"
	L["DIALOG_NEW_LIST_TEXT"] = "Name der neuen Liste eingeben:"
	L["DIALOG_CREATE"] = "Erstellen"
	L["DIALOG_DELETE_LIST_TEXT"] = "Möchtest du die Liste '%s' wirklich löschen?"
	L["DIALOG_DELETE"] = "Löschen"
	L["DIALOG_RENAME_LIST_TEXT"] = "Neuen Namen für die Liste eingeben:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "Notiz für %s:"
	L["DIALOG_SAVE"] = "Speichern"

	L["TOOLTIP_LEFT_CLICK"] = "Linksklick: |cffffffffFenster öffnen/schließen|r"
	L["TOOLTIP_RIGHT_CLICK"] = "Rechtsklick: |cffffffffListen-Übersicht|r"
	L["TOOLTIP_DRAG"] = "Gedrückt halten & Ziehen: |cffffffffPosition verschieben|r"
	L["TOOLTIP_OPEN_WINDOW"] = "Hauptfenster öffnen"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d Spieler"
	L["CONTEXT_REMOVE"] = "Entfernen"
	L["CONTEXT_ADD"] = "Hinzufügen"
	L["CONTEXT_LIST"] = "Liste: %s"
	L["RENAME_LIST"] = "Liste umbenennen"
	L["DELETE_LIST"] = "Liste löschen"
	L["CHANGE_SOUND_ALERT"] = "Sound-Signal ändern"
	L["EDIT_NOTE"] = "Notiz bearbeiten"
	L["MOVE_TO_LIST"] = "In Liste verschieben"
	L["COPY_TO_LIST"] = "In Liste kopieren"

	L["AUTO_ACTIONS"] = "Auto-Aktionen"
	L["AUTO_ACCEPT"] = "Automatisch annehmen (Direkteinladungen)"
	L["AUTO_DECLINE"] = "Automatisch ablehnen (Direkteinladungen)"
	L["AUTO_LFG_MANUAL"] = "Über LFG-Bewerber muss manuell entschieden werden."
	L["MSG_AUTO_ACCEPTED"] = "Einladung von %s automatisch angenommen (Liste '%s')."
	L["MSG_AUTO_DECLINED"] = "Einladung von %s automatisch abgelehnt (Liste '%s')."
	L["MSG_AUTO_SKIPPED"] = "Auto-Aktion für %s übersprungen: %s"
	L["MSG_AUTO_FAILED"] = "Auto-Aktion für %s fehlgeschlagen: %s"
	L["MSG_AUTO_RESTRICTED"] = "Auto-Aktionen sind vom Client für diese Sitzung eingeschränkt."
	L["MSG_AUTO_BLOCKED"] = "Der Client hat die automatische Einladungsverarbeitung blockiert; Auto-Aktionen sind für diese Sitzung deaktiviert."
	L["MSG_AUTO_API_MISSING"] = "API nicht verfügbar"
	L["MSG_LFG_MATCH"] = "%s steht auf deiner Liste '%s'."
	L["MSG_LFG_RESTRICTED"] = "LFG-Bewerberdaten sind vom Client eingeschränkt."
	L["MSG_LFG_FAILED"] = "LFG-Aktion fehlgeschlagen: %s"
	L["LFG_PANEL_TITLE"] = "GroupWatch-Treffer"
	L["LFG_INVITE"] = "Einladen"
	L["LFG_DECLINE"] = "Ablehnen"
	L["LFG_NO_MATCHES"] = "Keine Treffer"
	L["LFG_ROLE_TANK"] = "Tank"
	L["LFG_ROLE_HEALER"] = "Heiler"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "Rollenpassung nicht verfügbar"
	L["LFG_ROLE_NO_FIT"] = "Keine freie Rolle"
	L["LFG_ROLE_FIT"] = "Rolle passt"
	L["LFG_SLOTS_FULL"] = "Gruppe voll"
	L["LFG_SLOTS_AVAILABLE"] = "%d freie(r) Platz/Plätze"
	L["LFG_MORE"] = "+%d weitere"

	L["NOTE_HEADER"] = "Notiz"
	L["NOTE_TOOLTIP"] = "Notiz: %s\n\nKlicken zum Bearbeiten"
	L["NOTE_TOOLTIP_EMPTY"] = "Keine Notiz — klicken zum Hinzufügen"

-- =========================================================================
-- French (frFR)
-- =========================================================================
elseif locale == "frFR" then
	L["SUBTITLE"] = "Liste de joueurs"
	L["LISTS_LABEL"] = "Listes :"
	L["DEFAULT_LIST_NAME"] = "Par défaut"
	L["DEFAULT_GROUP_MSG"] = "%s est dans votre groupe !"

	L["SOUND_WARNING"] = "Avertissement"
	L["SOUND_RAID_WARNING"] = "Avertissement raid"
	L["SOUND_BELL"] = "Cloche"
	L["SOUND_WHISTLE"] = "Sifflet"
	L["SOUND_READY_CHECK"] = "Appel"
	L["SOUND_COIN"] = "Pièce / Or"
	L["SOUND_ACHIEVEMENT"] = "Haut fait"
	L["SOUND_EXPLOSION"] = "Explosion"
	L["SOUND_NONE"] = "Aucun son"
	L["SOUND_CUSTOM"] = "Personnalisé (%s)"

	L["SOUND_USER_ADD"] = "Ajouter un fichier son..."
	L["SOUND_USER_MISSING"] = "(fichier manquant)"
	L["MSG_SOUND_FILE_MISSING"] = "Fichier son '%s' introuvable. Placez-le dans le dossier Sounds de GroupWatch et redémarrez le jeu."
	L["MSG_SOUND_ADDED"] = "Son '%s' ajouté."
	L["MSG_SOUND_REMOVED"] = "Son '%s' supprimé."
	L["MSG_SOUND_NOT_FOUND"] = "Aucun fichier son nommé '%s' trouvé. Ajoutez-le dans le dossier Sounds et redémarrez le jeu."
	L["MSG_SOUND_NOT_REGISTERED"] = "Aucun fichier son nommé '%s' n'est enregistré."
	L["MSG_SOUND_BUNDLED"] = "'%s' est fourni avec l'addon et ne peut pas être supprimé."
	L["MSG_SOUND_BAD_NAME"] = "Ce n'est pas un nom de fichier son valide."
	L["MSG_SOUND_NO_FILES"] = "Aucun fichier son pour l'instant. Utilisez /gw sound add <nom> pour en ajouter un."
	L["DIALOG_ADD_SOUND_TEXT"] = "Nom du fichier son (sans extension) :"
	L["HELP_SOUND_ADD"] = "/gw sound add <nom> - ajouter votre propre fichier son"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <nom> - supprimer un fichier son"
	L["HELP_SOUND_LIST"] = "/gw sound list - lister vos fichiers son"

	L["NO_PLAYERS_IN_LIST"] = "(Aucun joueur dans cette liste)"
	L["MSG_LIST_NOT_FOUND"] = "La liste « %s » n'existe pas."
	L["MSG_PLAYER_ADDED"] = "%s ajouté(e) à la liste « %s »."
	L["MSG_PLAYER_REMOVED"] = "%s retiré(e) de « %s »."
	L["MSG_LIST_EXISTS"] = "La liste « %s » existe déjà."
	L["MSG_LIST_CREATED"] = "Nouvelle liste « %s » créée."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "La liste par défaut ne peut pas être supprimée."
	L["MSG_LIST_DELETED"] = "Liste « %s » supprimée."
	L["MSG_SELECT_PLAYER_FIRST"] = "Veuillez d'abord sélectionner un joueur."
	L["MINIMAP_ENABLED"] = "Bouton de minicarte activé"
	L["MINIMAP_DISABLED"] = "Bouton de minicarte désactivé"

	L["HELP_HEADER"] = "Commandes :"
	L["HELP_TOGGLE"] = "/gw ou /gw list - Ouvrir/fermer la fenêtre"
	L["HELP_MAP"] = "/gw map - Afficher/masquer le bouton de minicarte"
	L["HELP_ADD"] = "/gw add <NomListe> <Joueur-Royaume>"
	L["HELP_REMOVE"] = "/gw remove <Joueur-Royaume>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "Entrez le nom du joueur (Nom-Royaume) :"
	L["DIALOG_ADD"] = "Ajouter"
	L["DIALOG_CANCEL"] = "Annuler"
	L["DIALOG_NEW_LIST_TEXT"] = "Entrez le nom de la nouvelle liste :"
	L["DIALOG_CREATE"] = "Créer"
	L["DIALOG_DELETE_LIST_TEXT"] = "Voulez-vous vraiment supprimer la liste « %s » ?"
	L["DIALOG_DELETE"] = "Supprimer"
	L["DIALOG_RENAME_LIST_TEXT"] = "Entrez le nouveau nom de la liste :"
	L["DIALOG_EDIT_NOTE_TEXT"] = "Note pour %s :"
	L["DIALOG_SAVE"] = "Enregistrer"

	L["TOOLTIP_LEFT_CLICK"] = "Clic gauche : |cffffffffOuvrir/fermer la fenêtre|r"
	L["TOOLTIP_RIGHT_CLICK"] = "Clic droit : |cffffffffAperçu des listes|r"
	L["TOOLTIP_DRAG"] = "Maintenir & glisser : |cffffffffDéplacer le bouton|r"
	L["TOOLTIP_OPEN_WINDOW"] = "Ouvrir la fenêtre principale"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s : %d joueur(s)"
	L["CONTEXT_REMOVE"] = "Retirer"
	L["CONTEXT_ADD"] = "Ajouter"
	L["CONTEXT_LIST"] = "Liste : %s"
	L["RENAME_LIST"] = "Renommer la liste"
	L["DELETE_LIST"] = "Supprimer la liste"
	L["CHANGE_SOUND_ALERT"] = "Changer l'alerte sonore"
	L["EDIT_NOTE"] = "Modifier la note"
	L["MOVE_TO_LIST"] = "Déplacer vers la liste"
	L["COPY_TO_LIST"] = "Copier vers la liste"

	L["AUTO_ACTIONS"] = "Actions automatiques"
	L["AUTO_ACCEPT"] = "Accepter automatiquement (invitations directes)"
	L["AUTO_DECLINE"] = "Refuser automatiquement (invitations directes)"
	L["AUTO_LFG_MANUAL"] = "Les décisions concernant les candidats LFG nécessitent un clic manuel."
	L["MSG_AUTO_ACCEPTED"] = "Invitation de %s acceptée automatiquement (liste « %s »)."
	L["MSG_AUTO_DECLINED"] = "Invitation de %s refusée automatiquement (liste « %s »)."
	L["MSG_AUTO_SKIPPED"] = "Action automatique ignorée pour %s : %s"
	L["MSG_AUTO_FAILED"] = "Échec de l'action automatique pour %s : %s"
	L["MSG_AUTO_RESTRICTED"] = "Les actions automatiques sont restreintes par le client pour cette session."
	L["MSG_AUTO_BLOCKED"] = "Le client a bloqué la gestion automatique des invitations ; les actions automatiques sont désactivées pour cette session."
	L["MSG_AUTO_API_MISSING"] = "API indisponible"
	L["MSG_LFG_MATCH"] = "%s figure sur votre liste « %s »."
	L["MSG_LFG_RESTRICTED"] = "Les détails des candidats LFG sont restreints par le client."
	L["MSG_LFG_FAILED"] = "Échec de l'action LFG : %s"
	L["LFG_PANEL_TITLE"] = "Correspondances GroupWatch"
	L["LFG_INVITE"] = "Inviter"
	L["LFG_DECLINE"] = "Refuser"
	L["LFG_NO_MATCHES"] = "Aucune correspondance"
	L["LFG_ROLE_TANK"] = "Tank"
	L["LFG_ROLE_HEALER"] = "Soigneur"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "Adéquation des rôles indisponible"
	L["LFG_ROLE_NO_FIT"] = "Aucun rôle libre"
	L["LFG_ROLE_FIT"] = "Rôle adapté"
	L["LFG_SLOTS_FULL"] = "Groupe complet"
	L["LFG_SLOTS_AVAILABLE"] = "%d place(s) libre(s)"
	L["LFG_MORE"] = "+%d de plus"

	L["NOTE_HEADER"] = "Note"
	L["NOTE_TOOLTIP"] = "Note : %s\n\nCliquer pour modifier"
	L["NOTE_TOOLTIP_EMPTY"] = "Aucune note — cliquer pour ajouter"

-- =========================================================================
-- Spanish (esES & esMX)
-- =========================================================================
elseif locale == "esES" or locale == "esMX" then
	L["SUBTITLE"] = "Lista de jugadores"
	L["LISTS_LABEL"] = "Listas:"
	L["DEFAULT_LIST_NAME"] = "Predeterminada"
	L["DEFAULT_GROUP_MSG"] = "¡%s está en tu grupo!"

	L["SOUND_WARNING"] = "Aviso"
	L["SOUND_RAID_WARNING"] = "Aviso de banda"
	L["SOUND_BELL"] = "Campana"
	L["SOUND_WHISTLE"] = "Silbato"
	L["SOUND_READY_CHECK"] = "Comprobación de listos"
	L["SOUND_COIN"] = "Moneda / Oro"
	L["SOUND_ACHIEVEMENT"] = "Logro"
	L["SOUND_EXPLOSION"] = "Explosión"
	L["SOUND_NONE"] = "Sin sonido"
	L["SOUND_CUSTOM"] = "Personalizado (%s)"

	L["SOUND_USER_ADD"] = "Añadir archivo de sonido..."
	L["SOUND_USER_MISSING"] = "(falta el archivo)"
	L["MSG_SOUND_FILE_MISSING"] = "No se encuentra el archivo de sonido '%s'. Colócalo en la carpeta Sounds de GroupWatch y reinicia el juego."
	L["MSG_SOUND_ADDED"] = "Sonido '%s' añadido."
	L["MSG_SOUND_REMOVED"] = "Sonido '%s' eliminado."
	L["MSG_SOUND_NOT_FOUND"] = "No se encuentra ningún archivo de sonido llamado '%s'. Añádelo a la carpeta Sounds y reinicia el juego."
	L["MSG_SOUND_NOT_REGISTERED"] = "No hay ningún archivo de sonido llamado '%s' registrado."
	L["MSG_SOUND_BUNDLED"] = "'%s' viene con el addon y no se puede quitar."
	L["MSG_SOUND_BAD_NAME"] = "Ese no es un nombre de archivo de sonido válido."
	L["MSG_SOUND_NO_FILES"] = "Todavía no hay archivos de sonido. Usa /gw sound add <nombre> para añadir uno."
	L["DIALOG_ADD_SOUND_TEXT"] = "Nombre del archivo de sonido (sin extensión):"
	L["HELP_SOUND_ADD"] = "/gw sound add <nombre> - añadir tu propio archivo de sonido"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <nombre> - eliminar un archivo de sonido"
	L["HELP_SOUND_LIST"] = "/gw sound list - listar tus archivos de sonido"

	L["NO_PLAYERS_IN_LIST"] = "(No hay jugadores en esta lista)"
	L["MSG_LIST_NOT_FOUND"] = "La lista '%s' no existe."
	L["MSG_PLAYER_ADDED"] = "%s añadido a la lista '%s'."
	L["MSG_PLAYER_REMOVED"] = "%s eliminado de '%s'."
	L["MSG_LIST_EXISTS"] = "La lista '%s' ya existe."
	L["MSG_LIST_CREATED"] = "Nueva lista '%s' creada."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "No se puede eliminar la lista predeterminada."
	L["MSG_LIST_DELETED"] = "Lista '%s' eliminada."
	L["MSG_SELECT_PLAYER_FIRST"] = "Por favor, selecciona primero a un jugador."
	L["MINIMAP_ENABLED"] = "Botón del minimapa activado"
	L["MINIMAP_DISABLED"] = "Botón del minimapa desactivado"

	L["HELP_HEADER"] = "Comandos:"
	L["HELP_TOGGLE"] = "/gw o /gw list - Abrir/cerrar ventana"
	L["HELP_MAP"] = "/gw map - Mostrar/ocultar botón del minimapa"
	L["HELP_ADD"] = "/gw add <NombreLista> <Jugador-Reino>"
	L["HELP_REMOVE"] = "/gw remove <Jugador-Reino>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "Introduce el nombre del jugador (Nombre-Reino):"
	L["DIALOG_ADD"] = "Añadir"
	L["DIALOG_CANCEL"] = "Cancelar"
	L["DIALOG_NEW_LIST_TEXT"] = "Introduce el nombre de la nueva lista:"
	L["DIALOG_CREATE"] = "Crear"
	L["DIALOG_DELETE_LIST_TEXT"] = "¿Seguro que quieres eliminar la lista '%s'?"
	L["DIALOG_DELETE"] = "Eliminar"
	L["DIALOG_RENAME_LIST_TEXT"] = "Introduce el nuevo nombre de la lista:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "Nota para %s:"
	L["DIALOG_SAVE"] = "Guardar"

	L["TOOLTIP_LEFT_CLICK"] = "Clic izquierdo: |cffffffffAbrir/cerrar ventana|r"
	L["TOOLTIP_RIGHT_CLICK"] = "Clic derecho: |cffffffffResumen de listas|r"
	L["TOOLTIP_DRAG"] = "Mantener y arrastrar: |cffffffffMover posición|r"
	L["TOOLTIP_OPEN_WINDOW"] = "Abrir ventana principal"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d jugador(es)"
	L["CONTEXT_REMOVE"] = "Eliminar"
	L["CONTEXT_ADD"] = "Añadir"
	L["CONTEXT_LIST"] = "Lista: %s"
	L["RENAME_LIST"] = "Renombrar lista"
	L["DELETE_LIST"] = "Eliminar lista"
	L["CHANGE_SOUND_ALERT"] = "Cambiar alerta de sonido"
	L["EDIT_NOTE"] = "Editar nota"
	L["MOVE_TO_LIST"] = "Mover a la lista"
	L["COPY_TO_LIST"] = "Copiar a la lista"

	L["AUTO_ACTIONS"] = "Acciones automáticas"
	L["AUTO_ACCEPT"] = "Aceptar automáticamente (invitaciones directas)"
	L["AUTO_DECLINE"] = "Rechazar automáticamente (invitaciones directas)"
	L["AUTO_LFG_MANUAL"] = "Las decisiones sobre solicitantes de LFG requieren un clic manual."
	L["MSG_AUTO_ACCEPTED"] = "Invitación de %s aceptada automáticamente (lista '%s')."
	L["MSG_AUTO_DECLINED"] = "Invitación de %s rechazada automáticamente (lista '%s')."
	L["MSG_AUTO_SKIPPED"] = "Acción automática omitida para %s: %s"
	L["MSG_AUTO_FAILED"] = "Error en la acción automática para %s: %s"
	L["MSG_AUTO_RESTRICTED"] = "El cliente restringe las acciones automáticas en esta sesión."
	L["MSG_AUTO_BLOCKED"] = "El cliente bloqueó la gestión automática de invitaciones; las acciones automáticas están desactivadas en esta sesión."
	L["MSG_AUTO_API_MISSING"] = "API no disponible"
	L["MSG_LFG_MATCH"] = "%s está en tu lista '%s'."
	L["MSG_LFG_RESTRICTED"] = "El cliente restringe los detalles de los solicitantes de LFG."
	L["MSG_LFG_FAILED"] = "Error en la acción de LFG: %s"
	L["LFG_PANEL_TITLE"] = "Coincidencias de GroupWatch"
	L["LFG_INVITE"] = "Invitar"
	L["LFG_DECLINE"] = "Rechazar"
	L["LFG_NO_MATCHES"] = "Sin coincidencias"
	L["LFG_ROLE_TANK"] = "Tanque"
	L["LFG_ROLE_HEALER"] = "Sanador"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "Ajuste de rol no disponible"
	L["LFG_ROLE_NO_FIT"] = "Sin rol libre"
	L["LFG_ROLE_FIT"] = "Rol compatible"
	L["LFG_SLOTS_FULL"] = "Grupo lleno"
	L["LFG_SLOTS_AVAILABLE"] = "%d plaza(s) libre(s)"
	L["LFG_MORE"] = "+%d más"

	L["NOTE_HEADER"] = "Nota"
	L["NOTE_TOOLTIP"] = "Nota: %s\n\nHaz clic para editar"
	L["NOTE_TOOLTIP_EMPTY"] = "Sin nota — haz clic para añadir"

-- =========================================================================
-- Italian (itIT)
-- =========================================================================
elseif locale == "itIT" then
	L["SUBTITLE"] = "Elenco giocatori"
	L["LISTS_LABEL"] = "Elenchi:"
	L["DEFAULT_LIST_NAME"] = "Predefinito"
	L["DEFAULT_GROUP_MSG"] = "%s è nel tuo gruppo!"

	L["SOUND_WARNING"] = "Avviso"
	L["SOUND_RAID_WARNING"] = "Avviso incursione"
	L["SOUND_BELL"] = "Campana"
	L["SOUND_WHISTLE"] = "Fischietto"
	L["SOUND_READY_CHECK"] = "Appello"
	L["SOUND_COIN"] = "Moneta / Oro"
	L["SOUND_ACHIEVEMENT"] = "Impresa"
	L["SOUND_EXPLOSION"] = "Esplosione"
	L["SOUND_NONE"] = "Nessun suono"
	L["SOUND_CUSTOM"] = "Personalizzato (%s)"

	L["SOUND_USER_ADD"] = "Aggiungi file audio..."
	L["SOUND_USER_MISSING"] = "(file mancante)"
	L["MSG_SOUND_FILE_MISSING"] = "File audio '%s' non trovato. Mettilo nella cartella Sounds di GroupWatch e riavvia il gioco."
	L["MSG_SOUND_ADDED"] = "Suono '%s' aggiunto."
	L["MSG_SOUND_REMOVED"] = "Suono '%s' rimosso."
	L["MSG_SOUND_NOT_FOUND"] = "Nessun file audio chiamato '%s' trovato. Aggiungilo nella cartella Sounds e riavvia il gioco."
	L["MSG_SOUND_NOT_REGISTERED"] = "Nessun file audio chiamato '%s' è registrato."
	L["MSG_SOUND_BUNDLED"] = "'%s' è incluso nell'addon e non può essere rimosso."
	L["MSG_SOUND_BAD_NAME"] = "Questo non è un nome di file audio valido."
	L["MSG_SOUND_NO_FILES"] = "Ancora nessun file audio. Usa /gw sound add <nome> per aggiungerne uno."
	L["DIALOG_ADD_SOUND_TEXT"] = "Nome del file audio (senza estensione):"
	L["HELP_SOUND_ADD"] = "/gw sound add <nome> - aggiungi il tuo file audio"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <nome> - rimuovi un file audio"
	L["HELP_SOUND_LIST"] = "/gw sound list - elenca i tuoi file audio"

	L["NO_PLAYERS_IN_LIST"] = "(Nessun giocatore in questo elenco)"
	L["MSG_LIST_NOT_FOUND"] = "L'elenco '%s' non esiste."
	L["MSG_PLAYER_ADDED"] = "%s aggiunto all'elenco '%s'."
	L["MSG_PLAYER_REMOVED"] = "%s rimosso da '%s'."
	L["MSG_LIST_EXISTS"] = "L'elenco '%s' esiste già."
	L["MSG_LIST_CREATED"] = "Nuovo elenco '%s' creato."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "L'elenco predefinito non può essere eliminato."
	L["MSG_LIST_DELETED"] = "Elenco '%s' eliminato."
	L["MSG_SELECT_PLAYER_FIRST"] = "Seleziona prima un giocatore."
	L["MINIMAP_ENABLED"] = "Pulsante minimappa attivato"
	L["MINIMAP_DISABLED"] = "Pulsante minimappa disattivato"

	L["HELP_HEADER"] = "Comandi:"
	L["HELP_TOGGLE"] = "/gw o /gw list - Apri/chiudi finestra"
	L["HELP_MAP"] = "/gw map - Mostra/nascondi pulsante minimappa"
	L["HELP_ADD"] = "/gw add <NomeElenco> <Giocatore-Reame>"
	L["HELP_REMOVE"] = "/gw remove <Giocatore-Reame>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "Inserisci nome giocatore (Nome-Reame):"
	L["DIALOG_ADD"] = "Aggiungi"
	L["DIALOG_CANCEL"] = "Annulla"
	L["DIALOG_NEW_LIST_TEXT"] = "Inserisci il nome del nuovo elenco:"
	L["DIALOG_CREATE"] = "Crea"
	L["DIALOG_DELETE_LIST_TEXT"] = "Vuoi davvero eliminare l'elenco '%s'?"
	L["DIALOG_DELETE"] = "Elimina"
	L["DIALOG_RENAME_LIST_TEXT"] = "Inserisci il nuovo nome dell'elenco:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "Nota per %s:"
	L["DIALOG_SAVE"] = "Salva"

	L["TOOLTIP_LEFT_CLICK"] = "Clic sinistro: |cffffffffApri/chiudi finestra|r"
	L["TOOLTIP_RIGHT_CLICK"] = "Clic destro: |cffffffffPanoramica elenchi|r"
	L["TOOLTIP_DRAG"] = "Trascina: |cffffffffSposta pulsante|r"
	L["TOOLTIP_OPEN_WINDOW"] = "Apri finestra principale"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d giocatori"
	L["CONTEXT_REMOVE"] = "Rimuovi"
	L["CONTEXT_ADD"] = "Aggiungi"
	L["CONTEXT_LIST"] = "Elenco: %s"
	L["RENAME_LIST"] = "Rinomina elenco"
	L["DELETE_LIST"] = "Elimina elenco"
	L["CHANGE_SOUND_ALERT"] = "Cambia avviso sonoro"
	L["EDIT_NOTE"] = "Modifica nota"
	L["MOVE_TO_LIST"] = "Sposta nell'elenco"
	L["COPY_TO_LIST"] = "Copia nell'elenco"

	L["AUTO_ACTIONS"] = "Azioni automatiche"
	L["AUTO_ACCEPT"] = "Accetta automaticamente (inviti diretti)"
	L["AUTO_DECLINE"] = "Rifiuta automaticamente (inviti diretti)"
	L["AUTO_LFG_MANUAL"] = "Le decisioni sui candidati LFG richiedono un clic manuale."
	L["MSG_AUTO_ACCEPTED"] = "Invito di %s accettato automaticamente (lista '%s')."
	L["MSG_AUTO_DECLINED"] = "Invito di %s rifiutato automaticamente (lista '%s')."
	L["MSG_AUTO_SKIPPED"] = "Azione automatica saltata per %s: %s"
	L["MSG_AUTO_FAILED"] = "Azione automatica non riuscita per %s: %s"
	L["MSG_AUTO_RESTRICTED"] = "Le azioni automatiche sono limitate dal client per questa sessione."
	L["MSG_AUTO_BLOCKED"] = "Il client ha bloccato la gestione automatica degli inviti; le azioni automatiche sono disattivate per questa sessione."
	L["MSG_AUTO_API_MISSING"] = "API non disponibile"
	L["MSG_LFG_MATCH"] = "%s è nella tua lista '%s'."
	L["MSG_LFG_RESTRICTED"] = "I dettagli dei candidati LFG sono limitati dal client."
	L["MSG_LFG_FAILED"] = "Azione LFG non riuscita: %s"
	L["LFG_PANEL_TITLE"] = "Corrispondenze GroupWatch"
	L["LFG_INVITE"] = "Invita"
	L["LFG_DECLINE"] = "Rifiuta"
	L["LFG_NO_MATCHES"] = "Nessuna corrispondenza"
	L["LFG_ROLE_TANK"] = "Tank"
	L["LFG_ROLE_HEALER"] = "Guaritore"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "Compatibilità dei ruoli non disponibile"
	L["LFG_ROLE_NO_FIT"] = "Nessun ruolo libero"
	L["LFG_ROLE_FIT"] = "Ruolo compatibile"
	L["LFG_SLOTS_FULL"] = "Gruppo pieno"
	L["LFG_SLOTS_AVAILABLE"] = "%d posto/i libero/i"
	L["LFG_MORE"] = "+%d altri"

	L["NOTE_HEADER"] = "Nota"
	L["NOTE_TOOLTIP"] = "Nota: %s\n\nClicca per modificare"
	L["NOTE_TOOLTIP_EMPTY"] = "Nessuna nota — clicca per aggiungere"

-- =========================================================================
-- Portuguese (ptBR)
-- =========================================================================
elseif locale == "ptBR" then
	L["SUBTITLE"] = "Lista de Jogadores"
	L["LISTS_LABEL"] = "Listas:"
	L["DEFAULT_LIST_NAME"] = "Padrão"
	L["DEFAULT_GROUP_MSG"] = "%s está no seu grupo!"

	L["SOUND_WARNING"] = "Aviso"
	L["SOUND_RAID_WARNING"] = "Aviso de Raide"
	L["SOUND_BELL"] = "Sino"
	L["SOUND_WHISTLE"] = "Apito"
	L["SOUND_READY_CHECK"] = "Confirmação de Prontidão"
	L["SOUND_COIN"] = "Moeda / Ouro"
	L["SOUND_ACHIEVEMENT"] = "Conquista"
	L["SOUND_EXPLOSION"] = "Explosão"
	L["SOUND_NONE"] = "Sem som"
	L["SOUND_CUSTOM"] = "Personalizado (%s)"

	L["SOUND_USER_ADD"] = "Adicionar ficheiro de som..."
	L["SOUND_USER_MISSING"] = "(arquivo em falta)"
	L["MSG_SOUND_FILE_MISSING"] = "Ficheiro de som '%s' não encontrado. Coloque-o na pasta Sounds do GroupWatch e reinicie o jogo."
	L["MSG_SOUND_ADDED"] = "Som '%s' adicionado."
	L["MSG_SOUND_REMOVED"] = "Som '%s' removido."
	L["MSG_SOUND_NOT_FOUND"] = "Nenhum ficheiro de som chamado '%s' encontrado. Adicione-o à pasta Sounds e reinicie o jogo."
	L["MSG_SOUND_NOT_REGISTERED"] = "Nenhum ficheiro de som chamado '%s' está registado."
	L["MSG_SOUND_BUNDLED"] = "'%s' vem com o addon e não pode ser removido."
	L["MSG_SOUND_BAD_NAME"] = "Esse não é um nome de ficheiro de som válido."
	L["MSG_SOUND_NO_FILES"] = "Ainda não há ficheiros de som. Use /gw sound add <nome> para adicionar um."
	L["DIALOG_ADD_SOUND_TEXT"] = "Nome do ficheiro de som (sem extensão):"
	L["HELP_SOUND_ADD"] = "/gw sound add <nome> - adicionar o seu próprio ficheiro de som"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <nome> - remover um ficheiro de som"
	L["HELP_SOUND_LIST"] = "/gw sound list - listar os seus ficheiros de som"

	L["NO_PLAYERS_IN_LIST"] = "(Nenhum jogador nesta lista)"
	L["MSG_LIST_NOT_FOUND"] = "A lista '%s' não existe."
	L["MSG_PLAYER_ADDED"] = "%s adicionado à lista '%s'."
	L["MSG_PLAYER_REMOVED"] = "%s removido de '%s'."
	L["MSG_LIST_EXISTS"] = "A lista '%s' já existe."
	L["MSG_LIST_CREATED"] = "Nova lista '%s' criada."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "A lista padrão não pode ser excluída."
	L["MSG_LIST_DELETED"] = "Lista '%s' excluída."
	L["MSG_SELECT_PLAYER_FIRST"] = "Por favor, selecione um jogador primeiro."
	L["MINIMAP_ENABLED"] = "Botão do minimapa ativado"
	L["MINIMAP_DISABLED"] = "Botão do minimapa desativado"

	L["HELP_HEADER"] = "Comandos:"
	L["HELP_TOGGLE"] = "/gw ou /gw list - Abrir/fechar janela"
	L["HELP_MAP"] = "/gw map - Mostrar/ocultar botão do minimapa"
	L["HELP_ADD"] = "/gw add <NomeLista> <Jogador-Reino>"
	L["HELP_REMOVE"] = "/gw remove <Jogador-Reino>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "Digite o nome do jogador (Nome-Reino):"
	L["DIALOG_ADD"] = "Adicionar"
	L["DIALOG_CANCEL"] = "Cancelar"
	L["DIALOG_NEW_LIST_TEXT"] = "Digite o nome da nova lista:"
	L["DIALOG_CREATE"] = "Criar"
	L["DIALOG_DELETE_LIST_TEXT"] = "Tem certeza de que deseja excluir a lista '%s'?"
	L["DIALOG_DELETE"] = "Excluir"
	L["DIALOG_RENAME_LIST_TEXT"] = "Digite o novo nome da lista:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "Nota para %s:"
	L["DIALOG_SAVE"] = "Salvar"

	L["TOOLTIP_LEFT_CLICK"] = "Clique esquerdo: |cffffffffAbrir/fechar janela|r"
	L["TOOLTIP_RIGHT_CLICK"] = "Clique direito: |cffffffffVisão geral das listas|r"
	L["TOOLTIP_DRAG"] = "Segurar e arrastar: |cffffffffMover posição|r"
	L["TOOLTIP_OPEN_WINDOW"] = "Abrir janela principal"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d jogadores"
	L["CONTEXT_REMOVE"] = "Remover"
	L["CONTEXT_ADD"] = "Adicionar"
	L["CONTEXT_LIST"] = "Lista: %s"
	L["RENAME_LIST"] = "Renomear lista"
	L["DELETE_LIST"] = "Excluir lista"
	L["CHANGE_SOUND_ALERT"] = "Alterar alerta sonoro"
	L["EDIT_NOTE"] = "Editar nota"
	L["MOVE_TO_LIST"] = "Mover para a lista"
	L["COPY_TO_LIST"] = "Copiar para a lista"

	L["AUTO_ACTIONS"] = "Ações automáticas"
	L["AUTO_ACCEPT"] = "Aceitar automaticamente (convites diretos)"
	L["AUTO_DECLINE"] = "Recusar automaticamente (convites diretos)"
	L["AUTO_LFG_MANUAL"] = "As decisões sobre candidatos do LFG exigem um clique manual."
	L["MSG_AUTO_ACCEPTED"] = "Convite de %s aceito automaticamente (lista '%s')."
	L["MSG_AUTO_DECLINED"] = "Convite de %s recusado automaticamente (lista '%s')."
	L["MSG_AUTO_SKIPPED"] = "Ação automática ignorada para %s: %s"
	L["MSG_AUTO_FAILED"] = "Falha na ação automática para %s: %s"
	L["MSG_AUTO_RESTRICTED"] = "As ações automáticas estão restritas pelo cliente nesta sessão."
	L["MSG_AUTO_BLOCKED"] = "O cliente bloqueou o tratamento automático de convites; as ações automáticas estão desativadas nesta sessão."
	L["MSG_AUTO_API_MISSING"] = "API indisponível"
	L["MSG_LFG_MATCH"] = "%s está na sua lista '%s'."
	L["MSG_LFG_RESTRICTED"] = "Os detalhes dos candidatos do LFG estão restritos pelo cliente."
	L["MSG_LFG_FAILED"] = "Falha na ação do LFG: %s"
	L["LFG_PANEL_TITLE"] = "Correspondências do GroupWatch"
	L["LFG_INVITE"] = "Convidar"
	L["LFG_DECLINE"] = "Recusar"
	L["LFG_NO_MATCHES"] = "Nenhuma correspondência"
	L["LFG_ROLE_TANK"] = "Tanque"
	L["LFG_ROLE_HEALER"] = "Curador"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "Ajuste de função indisponível"
	L["LFG_ROLE_NO_FIT"] = "Nenhuma função livre"
	L["LFG_ROLE_FIT"] = "Função compatível"
	L["LFG_SLOTS_FULL"] = "Grupo cheio"
	L["LFG_SLOTS_AVAILABLE"] = "%d vaga(s) livre(s)"
	L["LFG_MORE"] = "+%d a mais"

	L["NOTE_HEADER"] = "Nota"
	L["NOTE_TOOLTIP"] = "Nota: %s\n\nClique para editar"
	L["NOTE_TOOLTIP_EMPTY"] = "Sem nota — clique para adicionar"

-- =========================================================================
-- Russian (ruRU)
-- =========================================================================
elseif locale == "ruRU" then
	L["SUBTITLE"] = "Список игроков"
	L["LISTS_LABEL"] = "Списки:"
	L["DEFAULT_LIST_NAME"] = "По умолчанию"
	L["DEFAULT_GROUP_MSG"] = "%s теперь в вашей группе!"

	L["SOUND_WARNING"] = "Предупреждение"
	L["SOUND_RAID_WARNING"] = "Предупреждение рейда"
	L["SOUND_BELL"] = "Колокольчик"
	L["SOUND_WHISTLE"] = "Свист"
	L["SOUND_READY_CHECK"] = "Проверка готовности"
	L["SOUND_COIN"] = "Монета / Золото"
	L["SOUND_ACHIEVEMENT"] = "Достижение"
	L["SOUND_EXPLOSION"] = "Взрыв"
	L["SOUND_NONE"] = "Без звука"
	L["SOUND_CUSTOM"] = "Свой (%s)"

	L["SOUND_USER_ADD"] = "Добавить звуковой файл..."
	L["SOUND_USER_MISSING"] = "(файл отсутствует)"
	L["MSG_SOUND_FILE_MISSING"] = "Звуковой файл '%s' не найден. Поместите его в папку Sounds аддона GroupWatch и перезапустите игру."
	L["MSG_SOUND_ADDED"] = "Звук '%s' добавлен."
	L["MSG_SOUND_REMOVED"] = "Звук '%s' удалён."
	L["MSG_SOUND_NOT_FOUND"] = "Звуковой файл '%s' не найден. Поместите его в папку Sounds и перезапустите игру."
	L["MSG_SOUND_NOT_REGISTERED"] = "Звуковой файл с именем '%s' не зарегистрирован."
	L["MSG_SOUND_BUNDLED"] = "'%s' входит в комплект аддона и не может быть удалён."
	L["MSG_SOUND_BAD_NAME"] = "Это недопустимое имя звукового файла."
	L["MSG_SOUND_NO_FILES"] = "Звуковых файлов пока нет. Используйте /gw sound add <имя>, чтобы добавить файл."
	L["DIALOG_ADD_SOUND_TEXT"] = "Имя звукового файла (без расширения):"
	L["HELP_SOUND_ADD"] = "/gw sound add <имя> - добавить свой звуковой файл"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <имя> - удалить звуковой файл"
	L["HELP_SOUND_LIST"] = "/gw sound list - показать список звуковых файлов"

	L["NO_PLAYERS_IN_LIST"] = "(В этом списке нет игроков)"
	L["MSG_LIST_NOT_FOUND"] = "Список '%s' не существует."
	L["MSG_PLAYER_ADDED"] = "%s добавлен в список '%s'."
	L["MSG_PLAYER_REMOVED"] = "%s удален из '%s'."
	L["MSG_LIST_EXISTS"] = "Список '%s' уже существует."
	L["MSG_LIST_CREATED"] = "Создан новый список '%s'."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "Список по умолчанию нельзя удалить."
	L["MSG_LIST_DELETED"] = "Список '%s' удален."
	L["MSG_SELECT_PLAYER_FIRST"] = "Пожалуйста, сначала выберите игрока."
	L["MINIMAP_ENABLED"] = "Кнопка у миникарты включена"
	L["MINIMAP_DISABLED"] = "Кнопка у миникарты отключена"

	L["HELP_HEADER"] = "Команды:"
	L["HELP_TOGGLE"] = "/gw или /gw list - Открыть/закрыть окно"
	L["HELP_MAP"] = "/gw map - Показать/скрыть кнопку у миникарты"
	L["HELP_ADD"] = "/gw add <ИмяСписка> <Игрок-Сервер>"
	L["HELP_REMOVE"] = "/gw remove <Игрок-Сервер>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "Введите имя игрока (Имя-Сервер):"
	L["DIALOG_ADD"] = "Добавить"
	L["DIALOG_CANCEL"] = "Отмена"
	L["DIALOG_NEW_LIST_TEXT"] = "Введите название нового списка:"
	L["DIALOG_CREATE"] = "Создать"
	L["DIALOG_DELETE_LIST_TEXT"] = "Вы действительно хотите удалить список '%s'?"
	L["DIALOG_DELETE"] = "Удалить"
	L["DIALOG_RENAME_LIST_TEXT"] = "Введите новое название списка:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "Заметка для %s:"
	L["DIALOG_SAVE"] = "Сохранить"

	L["TOOLTIP_LEFT_CLICK"] = "Левый клик: |cffffffffОткрыть/закрыть окно|r"
	L["TOOLTIP_RIGHT_CLICK"] = "Правый клик: |cffffffffОбзор списков|r"
	L["TOOLTIP_DRAG"] = "Перетаскивание: |cffffffffПереместить кнопку|r"
	L["TOOLTIP_OPEN_WINDOW"] = "Открыть главное окно"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: игроков: %d"
	L["CONTEXT_REMOVE"] = "Удалить"
	L["CONTEXT_ADD"] = "Добавить"
	L["CONTEXT_LIST"] = "Список: %s"
	L["RENAME_LIST"] = "Переименовать список"
	L["DELETE_LIST"] = "Удалить список"
	L["CHANGE_SOUND_ALERT"] = "Изменить звуковой сигнал"
	L["EDIT_NOTE"] = "Редактировать заметку"
	L["MOVE_TO_LIST"] = "Переместить в список"
	L["COPY_TO_LIST"] = "Копировать в список"

	L["AUTO_ACTIONS"] = "Автодействия"
	L["AUTO_ACCEPT"] = "Автопринятие (прямые приглашения)"
	L["AUTO_DECLINE"] = "Автоотклонение (прямые приглашения)"
	L["AUTO_LFG_MANUAL"] = "Решения по заявителям LFG требуют ручного нажатия."
	L["MSG_AUTO_ACCEPTED"] = "Приглашение от %s принято автоматически (список «%s»)."
	L["MSG_AUTO_DECLINED"] = "Приглашение от %s отклонено автоматически (список «%s»)."
	L["MSG_AUTO_SKIPPED"] = "Автодействие для %s пропущено: %s"
	L["MSG_AUTO_FAILED"] = "Не удалось выполнить автодействие для %s: %s"
	L["MSG_AUTO_RESTRICTED"] = "Клиент ограничил автодействия в этом сеансе."
	L["MSG_AUTO_BLOCKED"] = "Клиент заблокировал автоматическую обработку приглашений; автодействия отключены в этом сеансе."
	L["MSG_AUTO_API_MISSING"] = "API недоступен"
	L["MSG_LFG_MATCH"] = "%s есть в вашем списке «%s»."
	L["MSG_LFG_RESTRICTED"] = "Клиент ограничил сведения о заявителях LFG."
	L["MSG_LFG_FAILED"] = "Не удалось выполнить действие LFG: %s"
	L["LFG_PANEL_TITLE"] = "Совпадения GroupWatch"
	L["LFG_INVITE"] = "Пригласить"
	L["LFG_DECLINE"] = "Отклонить"
	L["LFG_NO_MATCHES"] = "Совпадений нет"
	L["LFG_ROLE_TANK"] = "Танк"
	L["LFG_ROLE_HEALER"] = "Целитель"
	L["LFG_ROLE_DAMAGE"] = "ДПС"
	L["LFG_ROLE_UNKNOWN"] = "Соответствие ролей недоступно"
	L["LFG_ROLE_NO_FIT"] = "Нет свободной роли"
	L["LFG_ROLE_FIT"] = "Роль подходит"
	L["LFG_SLOTS_FULL"] = "Группа заполнена"
	L["LFG_SLOTS_AVAILABLE"] = "Свободно мест: %d"
	L["LFG_MORE"] = "Ещё: %d"

	L["NOTE_HEADER"] = "Заметка"
	L["NOTE_TOOLTIP"] = "Заметка: %s\n\nНажмите для редактирования"
	L["NOTE_TOOLTIP_EMPTY"] = "Нет заметки — нажмите для добавления"

-- =========================================================================
-- Simplified Chinese (zhCN)
-- =========================================================================
elseif locale == "zhCN" then
	L["SUBTITLE"] = "玩家列表"
	L["LISTS_LABEL"] = "列表:"
	L["DEFAULT_LIST_NAME"] = "默认"
	L["DEFAULT_GROUP_MSG"] = "%s 加入了你的队伍！"

	L["SOUND_WARNING"] = "警报音"
	L["SOUND_RAID_WARNING"] = "团队警报"
	L["SOUND_BELL"] = "钟声"
	L["SOUND_WHISTLE"] = "哨声"
	L["SOUND_READY_CHECK"] = "就位确认"
	L["SOUND_COIN"] = "硬币 / 金币"
	L["SOUND_ACHIEVEMENT"] = "成就"
	L["SOUND_EXPLOSION"] = "爆炸"
	L["SOUND_NONE"] = "无声音"
	L["SOUND_CUSTOM"] = "自定义 (%s)"

	L["SOUND_USER_ADD"] = "添加音效文件..."
	L["SOUND_USER_MISSING"] = "（缺少文件）"
	L["MSG_SOUND_FILE_MISSING"] = "找不到音效文件“%s”。请将其放入 GroupWatch 的 Sounds 文件夹并重启游戏。"
	L["MSG_SOUND_ADDED"] = "已添加音效“%s”。"
	L["MSG_SOUND_REMOVED"] = "已移除音效“%s”。"
	L["MSG_SOUND_NOT_FOUND"] = "找不到名为“%s”的音效文件。请将其放入 Sounds 文件夹并重启游戏。"
	L["MSG_SOUND_NOT_REGISTERED"] = "没有注册名为“%s”的音效文件。"
	L["MSG_SOUND_BUNDLED"] = "“%s”随插件附带，无法移除。"
	L["MSG_SOUND_BAD_NAME"] = "这不是有效的音效文件名。"
	L["MSG_SOUND_NO_FILES"] = "目前没有音效文件。使用 /gw sound add <名称> 添加一个。"
	L["DIALOG_ADD_SOUND_TEXT"] = "音效文件名（不含扩展名）："
	L["HELP_SOUND_ADD"] = "/gw sound add <名称> - 添加自己的音效文件"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <名称> - 移除音效文件"
	L["HELP_SOUND_LIST"] = "/gw sound list - 列出你的音效文件"

	L["NO_PLAYERS_IN_LIST"] = "(该列表中暂无玩家)"
	L["MSG_LIST_NOT_FOUND"] = "列表 '%s' 不存在。"
	L["MSG_PLAYER_ADDED"] = "已将 %s 添加到列表 '%s'。"
	L["MSG_PLAYER_REMOVED"] = "已从 '%s' 中移除 %s。"
	L["MSG_LIST_EXISTS"] = "列表 '%s' 已存在。"
	L["MSG_LIST_CREATED"] = "已创建新列表 '%s'。"
	L["MSG_CANNOT_DELETE_DEFAULT"] = "无法删除默认列表。"
	L["MSG_LIST_DELETED"] = "已删除列表 '%s'。"
	L["MSG_SELECT_PLAYER_FIRST"] = "请先点击选择一名玩家。"
	L["MINIMAP_ENABLED"] = "小地图图标已启用"
	L["MINIMAP_DISABLED"] = "小地图图标已禁用"

	L["HELP_HEADER"] = "命令:"
	L["HELP_TOGGLE"] = "/gw 或 /gw list - 打开/关闭主窗口"
	L["HELP_MAP"] = "/gw map - 显示/隐藏小地图按钮"
	L["HELP_ADD"] = "/gw add <列表名称> <玩家-服务器>"
	L["HELP_REMOVE"] = "/gw remove <玩家-服务器>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "输入玩家姓名 (姓名-服务器):"
	L["DIALOG_ADD"] = "添加"
	L["DIALOG_CANCEL"] = "取消"
	L["DIALOG_NEW_LIST_TEXT"] = "输入新列表名称:"
	L["DIALOG_CREATE"] = "创建"
	L["DIALOG_DELETE_LIST_TEXT"] = "确定要删除列表 '%s' 吗？"
	L["DIALOG_DELETE"] = "删除"
	L["DIALOG_RENAME_LIST_TEXT"] = "输入列表的新名称:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "%s 的备注:"
	L["DIALOG_SAVE"] = "保存"

	L["TOOLTIP_LEFT_CLICK"] = "左键点击: |cffffffff打开/关闭窗口|r"
	L["TOOLTIP_RIGHT_CLICK"] = "右键点击: |cffffffff列表概览|r"
	L["TOOLTIP_DRAG"] = "按住拖动: |cffffffff移动位置|r"
	L["TOOLTIP_OPEN_WINDOW"] = "打开主窗口"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d 名玩家"
	L["CONTEXT_REMOVE"] = "移除"
	L["CONTEXT_ADD"] = "添加"
	L["CONTEXT_LIST"] = "列表: %s"
	L["RENAME_LIST"] = "重命名列表"
	L["DELETE_LIST"] = "删除列表"
	L["CHANGE_SOUND_ALERT"] = "更改声音警报"
	L["EDIT_NOTE"] = "编辑备注"
	L["MOVE_TO_LIST"] = "移动到列表"
	L["COPY_TO_LIST"] = "复制到列表"

	L["AUTO_ACTIONS"] = "自动操作"
	L["AUTO_ACCEPT"] = "自动接受（直接邀请）"
	L["AUTO_DECLINE"] = "自动拒绝（直接邀请）"
	L["AUTO_LFG_MANUAL"] = "LFG 申请人需要手动点击处理。"
	L["MSG_AUTO_ACCEPTED"] = "已自动接受 %s 的邀请（列表“%s”）。"
	L["MSG_AUTO_DECLINED"] = "已自动拒绝 %s 的邀请（列表“%s”）。"
	L["MSG_AUTO_SKIPPED"] = "已跳过 %s 的自动操作：%s"
	L["MSG_AUTO_FAILED"] = "%s 的自动操作失败：%s"
	L["MSG_AUTO_RESTRICTED"] = "客户端已限制本次会话的自动操作。"
	L["MSG_AUTO_BLOCKED"] = "客户端阻止了自动邀请处理；本次会话已禁用自动操作。"
	L["MSG_AUTO_API_MISSING"] = "API 不可用"
	L["MSG_LFG_MATCH"] = "%s 在你的列表“%s”中。"
	L["MSG_LFG_RESTRICTED"] = "客户端已限制 LFG 申请人详情。"
	L["MSG_LFG_FAILED"] = "LFG 操作失败：%s"
	L["LFG_PANEL_TITLE"] = "GroupWatch 匹配"
	L["LFG_INVITE"] = "邀请"
	L["LFG_DECLINE"] = "拒绝"
	L["LFG_NO_MATCHES"] = "没有匹配"
	L["LFG_ROLE_TANK"] = "坦克"
	L["LFG_ROLE_HEALER"] = "治疗"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "无法判断角色是否合适"
	L["LFG_ROLE_NO_FIT"] = "没有空闲角色"
	L["LFG_ROLE_FIT"] = "角色合适"
	L["LFG_SLOTS_FULL"] = "队伍已满"
	L["LFG_SLOTS_AVAILABLE"] = "剩余 %d 个位置"
	L["LFG_MORE"] = "还有 %d 个"

	L["NOTE_HEADER"] = "备注"
	L["NOTE_TOOLTIP"] = "备注: %s\n\n点击编辑"
	L["NOTE_TOOLTIP_EMPTY"] = "无备注 — 点击添加"

-- =========================================================================
-- Traditional Chinese (zhTW)
-- =========================================================================
elseif locale == "zhTW" then
	L["SUBTITLE"] = "玩家名單"
	L["LISTS_LABEL"] = "名單:"
	L["DEFAULT_LIST_NAME"] = "預設"
	L["DEFAULT_GROUP_MSG"] = "%s 已加入你的隊伍！"

	L["SOUND_WARNING"] = "警告音"
	L["SOUND_RAID_WARNING"] = "團隊警告"
	L["SOUND_BELL"] = "鐘聲"
	L["SOUND_WHISTLE"] = "哨聲"
	L["SOUND_READY_CHECK"] = "確認準備"
	L["SOUND_COIN"] = "硬幣 / 金幣"
	L["SOUND_ACHIEVEMENT"] = "成就"
	L["SOUND_EXPLOSION"] = "爆炸"
	L["SOUND_NONE"] = "無聲音"
	L["SOUND_CUSTOM"] = "自訂 (%s)"

	L["SOUND_USER_ADD"] = "新增音效檔案..."
	L["SOUND_USER_MISSING"] = "（缺少檔案）"
	L["MSG_SOUND_FILE_MISSING"] = "找不到音效檔案「%s」。請將其放入 GroupWatch 的 Sounds 資料夾並重新啟動遊戲。"
	L["MSG_SOUND_ADDED"] = "已新增音效「%s」。"
	L["MSG_SOUND_REMOVED"] = "已移除音效「%s」。"
	L["MSG_SOUND_NOT_FOUND"] = "找不到名為「%s」的音效檔案。請將其放入 Sounds 資料夾並重新啟動遊戲。"
	L["MSG_SOUND_NOT_REGISTERED"] = "沒有註冊名為「%s」的音效檔案。"
	L["MSG_SOUND_BUNDLED"] = "「%s」隨插件附帶，無法移除。"
	L["MSG_SOUND_BAD_NAME"] = "這不是有效的音效檔案名稱。"
	L["MSG_SOUND_NO_FILES"] = "目前沒有音效檔案。使用 /gw sound add <名稱> 新增一個。"
	L["DIALOG_ADD_SOUND_TEXT"] = "音效檔案名稱（不含副檔名）："
	L["HELP_SOUND_ADD"] = "/gw sound add <名稱> - 新增自己的音效檔案"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <名稱> - 移除音效檔案"
	L["HELP_SOUND_LIST"] = "/gw sound list - 列出你的音效檔案"

	L["NO_PLAYERS_IN_LIST"] = "(此名單中暫無玩家)"
	L["MSG_LIST_NOT_FOUND"] = "名單 '%s' 不存在。"
	L["MSG_PLAYER_ADDED"] = "已將 %s 新增至名單 '%s'。"
	L["MSG_PLAYER_REMOVED"] = "已從 '%s' 中移除 %s。"
	L["MSG_LIST_EXISTS"] = "名單 '%s' 已存在。"
	L["MSG_LIST_CREATED"] = "已建立新名單 '%s'。"
	L["MSG_CANNOT_DELETE_DEFAULT"] = "無法刪除預設名單。"
	L["MSG_LIST_DELETED"] = "已刪除名單 '%s'。"
	L["MSG_SELECT_PLAYER_FIRST"] = "請先點選一名玩家。"
	L["MINIMAP_ENABLED"] = "小地圖按鈕已啟用"
	L["MINIMAP_DISABLED"] = "小地圖按鈕已停用"

	L["HELP_HEADER"] = "指令:"
	L["HELP_TOGGLE"] = "/gw 或 /gw list - 開啟/關閉主視窗"
	L["HELP_MAP"] = "/gw map - 顯示/隱藏小地圖按鈕"
	L["HELP_ADD"] = "/gw add <名單名稱> <玩家-伺服器>"
	L["HELP_REMOVE"] = "/gw remove <玩家-伺服器>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "輸入玩家名稱 (名稱-伺服器):"
	L["DIALOG_ADD"] = "新增"
	L["DIALOG_CANCEL"] = "取消"
	L["DIALOG_NEW_LIST_TEXT"] = "輸入新名單名稱:"
	L["DIALOG_CREATE"] = "建立"
	L["DIALOG_DELETE_LIST_TEXT"] = "確定要刪除名單 '%s' 嗎？"
	L["DIALOG_DELETE"] = "刪除"
	L["DIALOG_RENAME_LIST_TEXT"] = "輸入名單的新名稱:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "%s 的註記:"
	L["DIALOG_SAVE"] = "儲存"

	L["TOOLTIP_LEFT_CLICK"] = "左鍵點擊: |cffffffff開啟/關閉視窗|r"
	L["TOOLTIP_RIGHT_CLICK"] = "右鍵點擊: |cffffffff名單概覽|r"
	L["TOOLTIP_DRAG"] = "按住拖曳: |cffffffff移動位置|r"
	L["TOOLTIP_OPEN_WINDOW"] = "開啟主視窗"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d 名玩家"
	L["CONTEXT_REMOVE"] = "移除"
	L["CONTEXT_ADD"] = "新增"
	L["CONTEXT_LIST"] = "名單: %s"
	L["RENAME_LIST"] = "重新命名名單"
	L["DELETE_LIST"] = "刪除名單"
	L["CHANGE_SOUND_ALERT"] = "變更聲音警告"
	L["EDIT_NOTE"] = "編輯註記"
	L["MOVE_TO_LIST"] = "移動至名單"
	L["COPY_TO_LIST"] = "複製至名單"

	L["AUTO_ACTIONS"] = "自動操作"
	L["AUTO_ACCEPT"] = "自動接受（直接邀請）"
	L["AUTO_DECLINE"] = "自動拒絕（直接邀請）"
	L["AUTO_LFG_MANUAL"] = "LFG 申請人需要手動點擊處理。"
	L["MSG_AUTO_ACCEPTED"] = "已自動接受 %s 的邀請（清單「%s」）。"
	L["MSG_AUTO_DECLINED"] = "已自動拒絕 %s 的邀請（清單「%s」）。"
	L["MSG_AUTO_SKIPPED"] = "已略過 %s 的自動操作：%s"
	L["MSG_AUTO_FAILED"] = "%s 的自動操作失敗：%s"
	L["MSG_AUTO_RESTRICTED"] = "客戶端已限制本次工作階段的自動操作。"
	L["MSG_AUTO_BLOCKED"] = "客戶端封鎖了自動邀請處理；本次工作階段已停用自動操作。"
	L["MSG_AUTO_API_MISSING"] = "API 無法使用"
	L["MSG_LFG_MATCH"] = "%s 在你的清單「%s」中。"
	L["MSG_LFG_RESTRICTED"] = "客戶端已限制 LFG 申請人詳細資料。"
	L["MSG_LFG_FAILED"] = "LFG 操作失敗：%s"
	L["LFG_PANEL_TITLE"] = "GroupWatch 符合項目"
	L["LFG_INVITE"] = "邀請"
	L["LFG_DECLINE"] = "拒絕"
	L["LFG_NO_MATCHES"] = "沒有符合項目"
	L["LFG_ROLE_TANK"] = "坦克"
	L["LFG_ROLE_HEALER"] = "治療"
	L["LFG_ROLE_DAMAGE"] = "DPS"
	L["LFG_ROLE_UNKNOWN"] = "無法判斷角色是否合適"
	L["LFG_ROLE_NO_FIT"] = "沒有空閒角色"
	L["LFG_ROLE_FIT"] = "角色合適"
	L["LFG_SLOTS_FULL"] = "隊伍已滿"
	L["LFG_SLOTS_AVAILABLE"] = "剩餘 %d 個位置"
	L["LFG_MORE"] = "還有 %d 個"

	L["NOTE_HEADER"] = "註記"
	L["NOTE_TOOLTIP"] = "註記: %s\n\n點擊編輯"
	L["NOTE_TOOLTIP_EMPTY"] = "無註記 — 點擊新增"

-- =========================================================================
-- Korean (koKR)
-- =========================================================================
elseif locale == "koKR" then
	L["SUBTITLE"] = "플레이어 목록"
	L["LISTS_LABEL"] = "목록:"
	L["DEFAULT_LIST_NAME"] = "기본"
	L["DEFAULT_GROUP_MSG"] = "%s님이 파티에 참여했습니다!"

	L["SOUND_WARNING"] = "경고음"
	L["SOUND_RAID_WARNING"] = "공격대 경보"
	L["SOUND_BELL"] = "종소리"
	L["SOUND_WHISTLE"] = "휘파람"
	L["SOUND_READY_CHECK"] = "전투 준비"
	L["SOUND_COIN"] = "동전 / 골드"
	L["SOUND_ACHIEVEMENT"] = "업적"
	L["SOUND_EXPLOSION"] = "폭발"
	L["SOUND_NONE"] = "소리 없음"
	L["SOUND_CUSTOM"] = "사용자 지정 (%s)"

	L["SOUND_USER_ADD"] = "음향 파일 추가..."
	L["SOUND_USER_MISSING"] = "(파일 없음)"
	L["MSG_SOUND_FILE_MISSING"] = "음향 파일 '%s'을(를) 찾을 수 없습니다. GroupWatch의 Sounds 폴더에 넣고 게임을 다시 시작하십시오."
	L["MSG_SOUND_ADDED"] = "음향 '%s'을(를) 추가했습니다."
	L["MSG_SOUND_REMOVED"] = "음향 '%s'을(를) 제거했습니다."
	L["MSG_SOUND_NOT_FOUND"] = "'%s' 음향 파일을 찾을 수 없습니다. Sounds 폴더에 넣고 게임을 다시 시작하십시오."
	L["MSG_SOUND_NOT_REGISTERED"] = "'%s' 음향 파일이 등록되어 있지 않습니다."
	L["MSG_SOUND_BUNDLED"] = "'%s'은(는) 애드온에 포함되어 제거할 수 없습니다."
	L["MSG_SOUND_BAD_NAME"] = "올바르지 않은 음향 파일 이름입니다."
	L["MSG_SOUND_NO_FILES"] = "아직 음향 파일이 없습니다. /gw sound add <이름>으로 추가하십시오."
	L["DIALOG_ADD_SOUND_TEXT"] = "음향 파일 이름 (확장자 제외):"
	L["HELP_SOUND_ADD"] = "/gw sound add <이름> - 나만의 음향 파일 추가"
	L["HELP_SOUND_REMOVE"] = "/gw sound remove <이름> - 음향 파일 제거"
	L["HELP_SOUND_LIST"] = "/gw sound list - 음향 파일 목록 보기"

	L["NO_PLAYERS_IN_LIST"] = "(이 목록에 플레이어가 없습니다)"
	L["MSG_LIST_NOT_FOUND"] = "'%s' 목록이 존재하지 않습니다."
	L["MSG_PLAYER_ADDED"] = "%s님을 '%s' 목록에 추가했습니다."
	L["MSG_PLAYER_REMOVED"] = "%s님을 '%s'에서 제거했습니다."
	L["MSG_LIST_EXISTS"] = "'%s' 목록이 이미 존재합니다."
	L["MSG_LIST_CREATED"] = "새 목록 '%s'이(가) 생성되었습니다."
	L["MSG_CANNOT_DELETE_DEFAULT"] = "기본 목록은 삭제할 수 없습니다."
	L["MSG_LIST_DELETED"] = "'%s' 목록이 삭제되었습니다."
	L["MSG_SELECT_PLAYER_FIRST"] = "먼저 플레이어를 선택해주세요."
	L["MINIMAP_ENABLED"] = "미니맵 버튼 활성화됨"
	L["MINIMAP_DISABLED"] = "미니맵 버튼 비활성화됨"

	L["HELP_HEADER"] = "명령어:"
	L["HELP_TOGGLE"] = "/gw 또는 /gw list - 창 열기/닫기"
	L["HELP_MAP"] = "/gw map - 미니맵 버튼 표시/숨기기"
	L["HELP_ADD"] = "/gw add <목록이름> <플레이어-서버>"
	L["HELP_REMOVE"] = "/gw remove <플레이어-서버>"

	L["DIALOG_ADD_PLAYER_TEXT"] = "플레이어 이름 입력 (이름-서버):"
	L["DIALOG_ADD"] = "추가"
	L["DIALOG_CANCEL"] = "취소"
	L["DIALOG_NEW_LIST_TEXT"] = "새 목록 이름 입력:"
	L["DIALOG_CREATE"] = "만들기"
	L["DIALOG_DELETE_LIST_TEXT"] = "'%s' 목록을 정말 삭제하시겠습니까?"
	L["DIALOG_DELETE"] = "삭제"
	L["DIALOG_RENAME_LIST_TEXT"] = "새 목록 이름 입력:"
	L["DIALOG_EDIT_NOTE_TEXT"] = "%s 메모:"
	L["DIALOG_SAVE"] = "저장"

	L["TOOLTIP_LEFT_CLICK"] = "좌클릭: |cffffffff창 열기/닫기|r"
	L["TOOLTIP_RIGHT_CLICK"] = "우클릭: |cffffffff목록 개요|r"
	L["TOOLTIP_DRAG"] = "드래그: |cffffffff위치 이동|r"
	L["TOOLTIP_OPEN_WINDOW"] = "메인 창 열기"
	L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d명"
	L["CONTEXT_REMOVE"] = "제거"
	L["CONTEXT_ADD"] = "추가"
	L["CONTEXT_LIST"] = "목록: %s"
	L["RENAME_LIST"] = "목록 이름 변경"
	L["DELETE_LIST"] = "목록 삭제"
	L["CHANGE_SOUND_ALERT"] = "소리 경보 변경"
	L["EDIT_NOTE"] = "메모 편집"
	L["MOVE_TO_LIST"] = "목록으로 이동"
	L["COPY_TO_LIST"] = "목록으로 복사"

	L["AUTO_ACTIONS"] = "자동 작업"
	L["AUTO_ACCEPT"] = "자동 수락 (직접 초대)"
	L["AUTO_DECLINE"] = "자동 거절 (직접 초대)"
	L["AUTO_LFG_MANUAL"] = "LFG 신청자 처리는 수동 클릭이 필요합니다."
	L["MSG_AUTO_ACCEPTED"] = "%s님의 초대를 자동으로 수락했습니다 (목록 '%s')."
	L["MSG_AUTO_DECLINED"] = "%s님의 초대를 자동으로 거절했습니다 (목록 '%s')."
	L["MSG_AUTO_SKIPPED"] = "%s 자동 작업을 건너뛰었습니다: %s"
	L["MSG_AUTO_FAILED"] = "%s 자동 작업 실패: %s"
	L["MSG_AUTO_RESTRICTED"] = "이 세션에서는 클라이언트가 자동 작업을 제한했습니다."
	L["MSG_AUTO_BLOCKED"] = "클라이언트가 자동 초대 처리를 차단했습니다. 이 세션에서는 자동 작업이 비활성화됩니다."
	L["MSG_AUTO_API_MISSING"] = "API를 사용할 수 없음"
	L["MSG_LFG_MATCH"] = "%s님이 목록 '%s'에 있습니다."
	L["MSG_LFG_RESTRICTED"] = "클라이언트가 LFG 신청자 정보를 제한했습니다."
	L["MSG_LFG_FAILED"] = "LFG 작업 실패: %s"
	L["LFG_PANEL_TITLE"] = "GroupWatch 일치 항목"
	L["LFG_INVITE"] = "초대"
	L["LFG_DECLINE"] = "거절"
	L["LFG_NO_MATCHES"] = "일치 항목 없음"
	L["LFG_ROLE_TANK"] = "탱커"
	L["LFG_ROLE_HEALER"] = "힐러"
	L["LFG_ROLE_DAMAGE"] = "딜러"
	L["LFG_ROLE_UNKNOWN"] = "역할 적합 여부를 알 수 없음"
	L["LFG_ROLE_NO_FIT"] = "사용 가능한 역할 없음"
	L["LFG_ROLE_FIT"] = "역할 적합"
	L["LFG_SLOTS_FULL"] = "그룹이 가득 참"
	L["LFG_SLOTS_AVAILABLE"] = "%d자리 남음"
	L["LFG_MORE"] = "+%d개 더"

	L["NOTE_HEADER"] = "메모"
	L["NOTE_TOOLTIP"] = "메모: %s\n\n클릭하여 편집"
	L["NOTE_TOOLTIP_EMPTY"] = "메모 없음 — 클릭하여 추가"
end

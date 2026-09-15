local ADDON_NAME, ns = ...

local L = setmetatable({}, {
    __index = function(t, k)
        return k
    end
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

    -- Tooltips & Menus
    TOOLTIP_LEFT_CLICK = "Left-click: |cffffffffToggle window|r",
    TOOLTIP_RIGHT_CLICK = "Right-click: |cffffffffList overview|r",
    TOOLTIP_DRAG = "Hold & Drag: |cffffffffMove button|r",
    TOOLTIP_OPEN_WINDOW = "Open main window",
    TOOLTIP_PLAYERS_COUNT = "%s: %d player(s)",
    CONTEXT_REMOVE = "Remove",
    CONTEXT_ADD = "Add",
    CONTEXT_LIST = "List: %s",
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

    L["TOOLTIP_LEFT_CLICK"] = "Linksklick: |cffffffffFenster öffnen/schließen|r"
    L["TOOLTIP_RIGHT_CLICK"] = "Rechtsklick: |cffffffffListen-Übersicht|r"
    L["TOOLTIP_DRAG"] = "Gedrückt halten & Ziehen: |cffffffffPosition verschieben|r"
    L["TOOLTIP_OPEN_WINDOW"] = "Hauptfenster öffnen"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d Spieler"
    L["CONTEXT_REMOVE"] = "Entfernen"
    L["CONTEXT_ADD"] = "Hinzufügen"
    L["CONTEXT_LIST"] = "Liste: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "Clic gauche : |cffffffffOuvrir/fermer la fenêtre|r"
    L["TOOLTIP_RIGHT_CLICK"] = "Clic droit : |cffffffffAperçu des listes|r"
    L["TOOLTIP_DRAG"] = "Maintenir & glisser : |cffffffffDéplacer le bouton|r"
    L["TOOLTIP_OPEN_WINDOW"] = "Ouvrir la fenêtre principale"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s : %d joueur(s)"
    L["CONTEXT_REMOVE"] = "Retirer"
    L["CONTEXT_ADD"] = "Ajouter"
    L["CONTEXT_LIST"] = "Liste : %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "Clic izquierdo: |cffffffffAbrir/cerrar ventana|r"
    L["TOOLTIP_RIGHT_CLICK"] = "Clic derecho: |cffffffffResumen de listas|r"
    L["TOOLTIP_DRAG"] = "Mantener y arrastrar: |cffffffffMover posición|r"
    L["TOOLTIP_OPEN_WINDOW"] = "Abrir ventana principal"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d jugador(es)"
    L["CONTEXT_REMOVE"] = "Eliminar"
    L["CONTEXT_ADD"] = "Añadir"
    L["CONTEXT_LIST"] = "Lista: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "Clic sinistro: |cffffffffApri/chiudi finestra|r"
    L["TOOLTIP_RIGHT_CLICK"] = "Clic destro: |cffffffffPanoramica elenchi|r"
    L["TOOLTIP_DRAG"] = "Trascina: |cffffffffSposta pulsante|r"
    L["TOOLTIP_OPEN_WINDOW"] = "Apri finestra principale"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d giocatori"
    L["CONTEXT_REMOVE"] = "Rimuovi"
    L["CONTEXT_ADD"] = "Aggiungi"
    L["CONTEXT_LIST"] = "Elenco: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "Clique esquerdo: |cffffffffAbrir/fechar janela|r"
    L["TOOLTIP_RIGHT_CLICK"] = "Clique direito: |cffffffffVisão geral das listas|r"
    L["TOOLTIP_DRAG"] = "Segurar e arrastar: |cffffffffMover posição|r"
    L["TOOLTIP_OPEN_WINDOW"] = "Abrir janela principal"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d jogadores"
    L["CONTEXT_REMOVE"] = "Remover"
    L["CONTEXT_ADD"] = "Adicionar"
    L["CONTEXT_LIST"] = "Lista: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "Левый клик: |cffffffffОткрыть/закрыть окно|r"
    L["TOOLTIP_RIGHT_CLICK"] = "Правый клик: |cffffffffОбзор списков|r"
    L["TOOLTIP_DRAG"] = "Перетаскивание: |cffffffffПереместить кнопку|r"
    L["TOOLTIP_OPEN_WINDOW"] = "Открыть главное окно"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: игроков: %d"
    L["CONTEXT_REMOVE"] = "Удалить"
    L["CONTEXT_ADD"] = "Добавить"
    L["CONTEXT_LIST"] = "Список: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "左键点击: |cffffffff打开/关闭窗口|r"
    L["TOOLTIP_RIGHT_CLICK"] = "右键点击: |cffffffff列表概览|r"
    L["TOOLTIP_DRAG"] = "按住拖动: |cffffffff移动位置|r"
    L["TOOLTIP_OPEN_WINDOW"] = "打开主窗口"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d 名玩家"
    L["CONTEXT_REMOVE"] = "移除"
    L["CONTEXT_ADD"] = "添加"
    L["CONTEXT_LIST"] = "列表: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "左鍵點擊: |cffffffff開啟/關閉視窗|r"
    L["TOOLTIP_RIGHT_CLICK"] = "右鍵點擊: |cffffffff名單概覽|r"
    L["TOOLTIP_DRAG"] = "按住拖曳: |cffffffff移動位置|r"
    L["TOOLTIP_OPEN_WINDOW"] = "開啟主視窗"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d 名玩家"
    L["CONTEXT_REMOVE"] = "移除"
    L["CONTEXT_ADD"] = "新增"
    L["CONTEXT_LIST"] = "名單: %s"

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

    L["TOOLTIP_LEFT_CLICK"] = "좌클릭: |cffffffff창 열기/닫기|r"
    L["TOOLTIP_RIGHT_CLICK"] = "우클릭: |cffffffff목록 개요|r"
    L["TOOLTIP_DRAG"] = "드래그: |cffffffff위치 이동|r"
    L["TOOLTIP_OPEN_WINDOW"] = "메인 창 열기"
    L["TOOLTIP_PLAYERS_COUNT"] = "%s: %d명"
    L["CONTEXT_REMOVE"] = "제거"
    L["CONTEXT_ADD"] = "추가"
    L["CONTEXT_LIST"] = "목록: %s"
end


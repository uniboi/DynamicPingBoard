global function pingDisplayPreCache

/** PING DISPLAY SETTINGS */
struct {
    float verticalPos = 0.00 // Vertical offset [0.0 -> 1.0]
    float horizontalPos = 0.75 // Horizontal offset [0.0 -> 1.0]
    vector color = Vector(1, 1, 1) // Default text color < %r, %g, %b >
    float textSize = 19 // value for font size, 19 is default
    float alpha = 1.0 // Text alpha
    float bold = 0.0 // Text boldness
    bool scaleColor = true // Scale ping color from lowLatencyColor to highLatencyColor relative to capPing
    bool drawUsernameLikePing = false // Draw ping and username in the same color. Excludes the player.
    int capPing = 300 // This ping and above gets the full highLatencyColor applied
    vector lowLatencyColor = Vector(0, 1, 0)
    vector highLatencyColor = Vector(1, 0, 0)
    vector highlightColor = Vector(1, 0.5, 0) // Highlighted text color < %r, %g, %b >
    bool drawBackground = true
    int orderBy = 0 // You can change this at runtime with the menu. 0: Unordered | 1: Ascending | 2: Descending
}settings

/** SUBMENU ONSELECT REFERENCES */
void function setRefs(){
    menuInternal.itemSelect = [[addSubMenuSorting, switchBg], [setOrderAscending, setOrderDescending, setOrderUnordered]]
}

/** MENU SETTINGS */
struct {
    vector topoOrigin = <50,300,0>
    vector topoStretchX = <200, 0, 0>
    vector topoStretchY = <0, 400, 0>
    /** For some reason the topology doesn't take new values. I'll look into it in the future. Ignore the following two. */
    int appendStretchX = 0
    int increaseStretchX = 100
    /**  */
    vector highlightColor = <1, 0.5, 0>
    vector textColor = <1, 1, 1>
    vector topoColor = <0, 0, 0>
    float subTextXOffset
    float topoAlpha = 0.5
    float textAlpha = 1
    float referenceTextSize = 400
    float xBaseSpace = 0.03
    float xSpace = 1.2
    float yBaseSpace = 0
    float ySpace = 0.4
    array < array < string > > menus = [["sort", "background"], ["asc", "desc", "normal"]]
}menuSettings

// Internal
struct {
    bool displayAlive = false
}script

// My code & approach is pretty scuffed. I don't advise you to copy my menu code.
// ... especially my use of topologies
struct {
    array < int > functionIndexList = [0]
    array < int > selected = [0]
    bool showingMenu = false
    var menuTopology = null
    var refTop = null
    int sel = 0
    int lastSel = 0
    int hSel = 0
    array < array < string > > activeMenuItemList = []
    array < var > menuRuis = []
    var menuGroundRui
    array < array < void functionref() > > itemSelect
}menuInternal

void function pingDisplayPreCache() {
    var rui = createEmptyRUI()
    setRefs()
    resetActiveMenuItemLists()
    menusThread()
}

void function setOrderAscending(){
    settings.orderBy = 1

}

void function setOrderDescending(){
    settings.orderBy = 2
}

void function setOrderUnordered(){
    settings.orderBy = 0
}

void function addSubMenuSorting(){
    menuInternal.activeMenuItemList.append(menuSettings.menus[1])
    menuInternal.functionIndexList.append(1)
    menuInternal.selected.append(0)
}

void function switchBg(){
    settings.drawBackground = !settings.drawBackground
}

// see _utility_shared.nut in vpks function GetSortedPlayers
array < entity > function GetSpecifiedSortedPlayers(int comp, int team){
    array<entity> players
    IntFromEntityCompare compareFunc
	if ( team )
		players = GetPlayerArrayOfTeam( team )
	else
		players = GetPlayerArray()

    switch (comp) {
        case 1:
            compareFunc = compare_ascending
            break;
        case 2:
            compareFunc = compare_descending
            break;
        default:
            return players;
    }

	players.sort( compareFunc )
	return players
}

void function resetActiveMenuItemLists(){
    menuInternal.activeMenuItemList = [menuSettings.menus[0]]
    menuInternal.selected = [0]
}

int function compare_ascending(entity player1, entity player2)
{
    if(player1.GetPlayerGameStat(PGS_PING).tofloat()>player2.GetPlayerGameStat(PGS_PING).tofloat()) return 1
    else if(player1.GetPlayerGameStat(PGS_PING).tofloat()<player2.GetPlayerGameStat(PGS_PING).tofloat()) return -1
    return 0;
}

int function compare_descending(entity player1, entity player2)
{
    if(player1.GetPlayerGameStat(PGS_PING).tofloat()<player2.GetPlayerGameStat(PGS_PING).tofloat()) return 1
    else if(player1.GetPlayerGameStat(PGS_PING).tofloat()>player2.GetPlayerGameStat(PGS_PING).tofloat()) return -1
    return 0;
}

void function menusThread() {
    menuInternal.menuTopology = RuiTopology_CreatePlane( menuSettings.topoOrigin, menuSettings.topoStretchX, menuSettings.topoStretchY, false )
    menuInternal.refTop = RuiTopology_CreatePlane( menuSettings.topoOrigin, <100, 0, 0>, <0, 50, 0>, false )

    registerPermanentListeners()
}

void function createTopology(vector stretchX){
    // Why isn't the new stretch taken over?
    menuInternal.menuTopology = RuiTopology_CreatePlane( menuSettings.topoOrigin, stretchX, menuSettings.topoStretchY, false )
    menuInternal.refTop = RuiTopology_CreatePlane( menuSettings.topoOrigin, <100, 0, 0>, <0, 50, 0>, false )
    print(type(menuInternal.menuTopology))
}

void function destroyTopology(){
    RuiTopology_Destroy( menuInternal.menuTopology )
    RuiTopology_Destroy( menuInternal.refTop )
}

void function registerMenuListeners(){
    RegisterButtonPressedCallback(KEY_K, ptrUp)
    RegisterButtonPressedCallback(KEY_I, ptrDown)
    RegisterButtonPressedCallback(KEY_J, deselectItem)
    RegisterButtonPressedCallback(KEY_L, selectItem)
}

void function deregisterMenuListeners(){
    DeregisterButtonPressedCallback(KEY_K, ptrUp)
    DeregisterButtonPressedCallback(KEY_I, ptrDown)
    DeregisterButtonPressedCallback(KEY_J, deselectItem)
    DeregisterButtonPressedCallback(KEY_L, selectItem)
}

void function registerPermanentListeners(){
    RegisterButtonPressedCallback(KEY_F2, handleDisplay)
    RegisterButtonPressedCallback(KEY_U, handleMenu)
}

void function colorMenuItem(){
    if(menuInternal.menuRuis.len() > 0 && menuInternal.showingMenu)
        {
            string slc = menuInternal.selected.tostring()
            int corRuiIndex = 0
            int currentMenuRuiIndex
            for (int i; i < menuInternal.selected.len(); i++) {
                int subMenuSelected = menuInternal.selected[i]
                currentMenuRuiIndex = corRuiIndex + subMenuSelected
                if(currentMenuRuiIndex < menuInternal.menuRuis.len() && currentMenuRuiIndex >= 0)
                RuiSetFloat3(menuInternal.menuRuis[currentMenuRuiIndex], "msgColor", menuSettings.highlightColor)
                if(i < menuInternal.selected.len()-1)
                    corRuiIndex += menuInternal.activeMenuItemList[i].len()
            }
            int lastMenuRuiIndex = corRuiIndex + menuInternal.lastSel
            if(currentMenuRuiIndex != lastMenuRuiIndex && lastMenuRuiIndex < menuInternal.menuRuis.len())
                RuiSetFloat3(menuInternal.menuRuis[lastMenuRuiIndex], "msgColor", menuSettings.textColor)
        }
}

int function lastSelectedIndex(){
    return menuInternal.selected.len()-1 < 0 ? 0 : menuInternal.selected.len()-1
}



void function ptrUp(var e){
    if(menuInternal.selected[lastSelectedIndex()]+1 < menuInternal.activeMenuItemList[menuInternal.activeMenuItemList.len()-1].len())
    {
        menuInternal.lastSel = menuInternal.selected[lastSelectedIndex()]
        menuInternal.selected[lastSelectedIndex()]++
    }
    colorMenuItem()
}

void function ptrDown(var e){
    if(menuInternal.selected[lastSelectedIndex()]-1 >= 0)
    {
        menuInternal.lastSel = menuInternal.selected[lastSelectedIndex()]
        menuInternal.selected[lastSelectedIndex()]--
    }
    colorMenuItem()
}

void function deselectItem(var e){
    if(menuInternal.selected.len() > 1)
    {
        menuInternal.selected.pop()
        menuInternal.activeMenuItemList.pop()
        menuInternal.functionIndexList.pop()
        menuInternal.lastSel = 0
        menuSettings.appendStretchX -= menuSettings.increaseStretchX
        updateRuntimeMenu()
    }
    else
        {
            menuInternal.showingMenu = false
            killMenu()
        }
}
void function selectItem(var e){
    int lastListIndex = menuInternal.functionIndexList.len()-1
    if(lastListIndex < 0)
        lastListIndex = 0
    menuInternal.lastSel = 0
    int index = menuInternal.functionIndexList[lastListIndex]
    menuInternal.itemSelect[index][menuInternal.selected[lastSelectedIndex()]]()
    menuSettings.appendStretchX += menuSettings.increaseStretchX
    updateRuntimeMenu()
}

void function updateRuntimeMenu(){
    foreach (rui in menuInternal.menuRuis) {
            RuiDestroyIfAlive(rui)
    }
    menuInternal.menuRuis.clear()
    destroyTopology()
    vector sx = menuSettings.topoStretchX
    sx.x = sx.x + menuSettings.appendStretchX
    print(sx)
    createTopology(sx)
    displayRuntimeMenu()
    colorMenuItem()
}

void function handleMenu(var pressedKey){
    menuInternal.showingMenu = !menuInternal.showingMenu
    if(menuInternal.showingMenu)
        {
            createTopology(menuSettings.topoStretchX)
            registerMenuListeners()
            menuInternal.menuGroundRui = RuiCreate( $"ui/basic_image.rpak", menuInternal.menuTopology, RUI_DRAW_HUD, -1 )
            RuiSetFloat3(menuInternal.menuGroundRui, "basicImageColor", <0,0,0>)
            RuiSetFloat(menuInternal.menuGroundRui, "basicImageAlpha", menuSettings.topoAlpha)
            displayRuntimeMenu()
            colorMenuItem()
        }
    else
        killMenu()
}

void function killMenu(){
    deregisterMenuListeners()
    destroyTopology()
    RuiDestroyIfAlive(menuInternal.menuGroundRui)
    foreach (rui in menuInternal.menuRuis) {
        RuiDestroyIfAlive(rui)
    }
    menuInternal.functionIndexList = [0]
    menuInternal.lastSel = 0
    menuInternal.menuRuis.clear()
    resetActiveMenuItemLists()
}

void function displayRuntimeMenu(){
    for (int i; i < menuInternal.activeMenuItemList.len(); i++) {
        array < string > mItems = menuInternal.activeMenuItemList[i]
        for (int j; j < mItems.len(); j++) {
            print(j)
            menuInternal.menuRuis.append(createRef(
                <i*menuSettings.xSpace+menuSettings.xBaseSpace,
                j*menuSettings.ySpace+menuSettings.yBaseSpace, 0>
                , menuInternal.refTop, mItems[j]))
            print(i*menuSettings.xSpace+menuSettings.xBaseSpace)
            print(j*menuSettings.ySpace+menuSettings.yBaseSpace)
        }
    }
}


var function createRef(vector pos, var topo, string text) {
    var rui = RuiCreate($"ui/cockpit_console_text_top_left.rpak", topo, RUI_DRAW_HUD, 15)
    RuiSetString(rui, "msgText", text)
    RuiSetFloat(rui, "msgFontSize", 400)
    RuiSetFloat2(rui, "msgPos", pos )
    RuiSetFloat(rui, "msgAlpha", 1)
    return rui
}


void function handleDisplay(var pressedKey) {
    script.displayAlive = !script.displayAlive
    if (script.displayAlive) {
        thread ruiHandler()
    }
    EmitSoundOnEntity(GetLocalClientPlayer(), "menu_click")
}

var function createEmptyRUI() {
    var rui = RuiCreate($"ui/cockpit_console_text_top_left.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 15)
    RuiSetString(rui, "msgText", "")
    RuiSetInt(rui, "lineNum", 1)
    RuiSetFloat(rui, "msgFontSize", settings.textSize)
    RuiSetFloat(rui, "msgAlpha", settings.alpha)
    RuiSetFloat(rui, "thicken", settings.bold)
    RuiSetFloat3(rui, "msgColor", settings.color)
    return rui
}

void function killRUIs(array < array < var > > ruis) {
    foreach(array < var > row in ruis) {
        foreach(var cell in row) {
            RuiDestroyIfAlive(cell)
        }
    }
}

void function ruiHandler() {
        array < array < var > > playerRows
        array < array < int > > playerRefs
        var background
        while (script.displayAlive) {
        if(settings.drawBackground && background == null)
            background = RuiCreate($"ui/scoreboard_background.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 10)
        else if(!settings.drawBackground && background != null)
            {
                RuiDestroyIfAlive(background)
                background = null
            }

        for (int i = 0; i < GetSpecifiedSortedPlayers(settings.orderBy, 0).len(); i++) {
            while (playerRows.len() > GetSpecifiedSortedPlayers(settings.orderBy, 0).len()) {
                array < var > row = playerRows.pop()
                RuiDestroyIfAlive(row[0]) // Destroy unused ruis
                RuiDestroyIfAlive(row[1])
            }
            while (playerRows.len() < GetSpecifiedSortedPlayers(settings.orderBy, 0).len()) {
                playerRows.append([createEmptyRUI(), createEmptyRUI()]) // Populate needed array slots
            }

            /** USER PING COLOR */
            vector pingColor = settings.color
            if(settings.scaleColor)
              {
                float p = GetSpecifiedSortedPlayers(settings.orderBy, 0)[i].GetPlayerGameStat(PGS_PING).tofloat() / settings.capPing.tofloat()
                pingColor = < settings.lowLatencyColor.x+p*(settings.highLatencyColor.x-settings.lowLatencyColor.x),
                settings.lowLatencyColor.y+p*(settings.highLatencyColor.y-settings.lowLatencyColor.y),
                settings.lowLatencyColor.z+p*(settings.highLatencyColor.z-settings.lowLatencyColor.z) >
              }

            /** USERNAME COLOR*/
            vector usernameColor = settings.color
            if (GetSpecifiedSortedPlayers(settings.orderBy, 0)[i].GetPlayerName() == GetLocalClientPlayer().GetPlayerName())
              usernameColor = settings.highlightColor
            else if(settings.drawUsernameLikePing)
              usernameColor = pingColor

            /** APPLY USERNAME */
            RuiSetFloat3(playerRows[i][0], "msgColor", usernameColor)
            RuiSetString(playerRows[i][0], "msgText", GetSpecifiedSortedPlayers(settings.orderBy, 0)[i].GetPlayerName())
            RuiSetFloat2(playerRows[i][0], "msgPos", < settings.horizontalPos, settings.verticalPos + i * 0.025, 0.0 > )

            /** APPLY PING */
            RuiSetFloat3(playerRows[i][1], "msgColor", pingColor)
            RuiSetString(playerRows[i][1], "msgText", GetSpecifiedSortedPlayers(settings.orderBy, 0)[i].GetPlayerGameStat(PGS_PING) + "ms")
            RuiSetFloat2(playerRows[i][1], "msgPos", < settings.horizontalPos+0.1, settings.verticalPos+i*0.025, 0.0 > )

            WaitFrame() // Update every frame
        }
        if (!script.displayAlive) // Might change in while because of thread magic
        {
            if(settings.drawBackground && background != null)
                RuiDestroyIfAlive(background)
            killRUIs(playerRows) // Kill remaining ruis
            break
        }
    }
}
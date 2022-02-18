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


/** MENU SETTINGS */
struct {
    int maxPlayerDisplayExpensive
    vector topoOrigin = <50,300,0>
    vector topoStretchX = <220, 0, 0>
    vector topoStretchY = <0, 200, 0>
    vector highlightColor = <1, 0.5, 0>
    vector textColor = <1, 1, 1>
    vector topoColor = <0, 0, 0>
    float topoAlpha = 0.5
    float textAlpha = 1
    float referenceTextSize = 400
    float xBaseSpace = 0.03
    float yBaseSpace = 0
    array < array < string > > menus = [["sort", "background"], ["asc", "desc", "normal", "name asc", "name desc"]]
    /*
        I added the compact menu down the line because of rui limitations and the original broke somewhere
        Because I don't recommend using it I'm not going to do anything about it.
        Just ignore the following.
    */
    float xSpace = 1.2
    float ySpace = 0.4
    bool useCompact = true
    int menuCompact = 0 // 0: Dynamic | 1: Compact | 2: Expensive
    /** For some reason the topology doesn't take new values. I'll look into it in the future. Ignore the following two. */
    int appendStretchX = 0
    int increaseStretchX = 100
}menuSettings

/*
    I really don't recommend working with this menu implementation because it's pretty shit and I haven't bothered looking into UI.
    I'm going to explain how it works anyways in case some maniac wants to change something.

    [*] menuSettings.menus are the strings of every possible submenu.
        [*] The first subarray HAS TO BE the submenu opened with the menu.
        [*] The order of the rest doesn't matter
    [*] menuInternal.itemSelect are the function references for each menu item
        [*] The first subarray HAS TO BE the functionrefs for the items opened with the menu
        [*] The order of the rest doesn't matter but I would recommend using the same order like in menuSettings.menus
    [*] To add a submenu on selection, you have to append some things to some arrays
        [*] The list of item titles to menuInternal.activeMenuItemList
            [*] Like this: menuInternal.activeMenuItemList.append(menuSettings.menus[1])
        [*] The list of corresponding function references
            [*] Like this: menuInternal.functionIndexList.append(1)
        [*] The selected item index of the opened submenu (doesn't have to be 0)
            [*] Like this: menuInternal.selected.append(0)
    [*] === THE ORDER OF ITEM TITLE AND CORRESPONDING FUNCTIONREF IN THE ARRAY HAVE TO BE THE SAME === (I think I don't remember 100%)
        [*] For example, like this:
            [*] [["item1", "item2"], ["item1.1", "item1.2"], ["item2.1"]]
            [*] [[onselect1, onselect2], [onselect11, onselect12], [onselect21]]
    [*] Functionrefs can only be void. Edit the code if this bothers you.

    That's it if I remember correctly
*/

/** SUBMENU ONSELECT REFERENCES */
void function setRefs(){
    menuInternal.itemSelect = [[addSubMenuSorting, switchBg], [setOrderAscending, setOrderDescending, setOrderUnordered, setOrderNameAscending, setOrderNameDescending]]
}

// Internal
struct {
    bool displayAlive = false
}script

// My code & approach is pretty scuffed. I don't advise you to copy my menu code.
// ... especially my use of topologies
struct {
    bool killFollowing = false
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
    var menuRui
    var menuGroundRui
    array < array < void functionref() > > itemSelect
}menuInternal

void function pingDisplayPreCache() {
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

void function setOrderNameDescending(){
    settings.orderBy = 3
}

void function setOrderNameAscending(){
    settings.orderBy = 4
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
        case 3:
            compareFunc = compareByUsernameDescending
            break;
        case 4:
            compareFunc = compareByUsernameAscending
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

int function compareByUsernameDescending(entity player1, entity player2){
    string p1 = player1.GetPlayerName().toupper()
    string p2 = player2.GetPlayerName().toupper()

    for (int i; i < p1.len() && i < p2.len(); i++){
        if(i >= p1.len())
            return 1;
        if(i >= p2.len())
            return -1;
        if(p1[i] == p2[i])
            continue;
        if(p1[i] < p2[i])
            return 1;
        if(p1[i] > p2[i])
            return -1
    }
    return 0;
}

int function compareByUsernameAscending(entity player1, entity player2){
    string p1 = player1.GetPlayerName().toupper()
    string p2 = player2.GetPlayerName().toupper()

    for (int i; i < p1.len() && i < p2.len(); i++){
        if(i >= p1.len())
            return 1;
        if(i >= p2.len())
            return -1;
        if(p1[i] == p2[i])
            continue;
        if(p1[i] < p2[i])
            return -1;
        if(p1[i] > p2[i])
            return 1
    }
    return 0;
}

int function compare_ascending(entity player1, entity player2)
{
    if(player1.GetPlayerGameStat(PGS_PING)>player2.GetPlayerGameStat(PGS_PING)) return 1
    else if(player1.GetPlayerGameStat(PGS_PING)<player2.GetPlayerGameStat(PGS_PING)) return -1
    return 0;
}

int function compare_descending(entity player1, entity player2)
{
    if(player1.GetPlayerGameStat(PGS_PING)<player2.GetPlayerGameStat(PGS_PING)) return 1
    else if(player1.GetPlayerGameStat(PGS_PING)>player2.GetPlayerGameStat(PGS_PING)) return -1
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
    RegisterButtonPressedCallback(KEY_F1, handleDisplay)
    RegisterButtonPressedCallback(KEY_U, handleMenu)
}

void function colorMenuItem(){
    if(menuInternal.menuRuis.len() > 0 && menuInternal.showingMenu)
        {
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
    if(menuSettings.useCompact)
        RuiSetString(menuInternal.menuRui, "msgText", singleMenuString())
}

void function ptrDown(var e){
    if(menuInternal.selected[lastSelectedIndex()]-1 >= 0)
    {
        menuInternal.lastSel = menuInternal.selected[lastSelectedIndex()]
        menuInternal.selected[lastSelectedIndex()]--
    }
    colorMenuItem()
    if(menuSettings.useCompact)
        RuiSetString(menuInternal.menuRui, "msgText", singleMenuString())
}

void function deselectItem(var e){
    if(menuInternal.selected.len() > 1)
    {
        menuInternal.selected.pop()
        menuInternal.activeMenuItemList.pop()
        menuInternal.functionIndexList.pop()
        menuInternal.lastSel = 0
        menuSettings.appendStretchX -= menuSettings.increaseStretchX
        if(!menuSettings.useCompact)
            updateRuntimeMenu()
        else
            RuiSetString(menuInternal.menuRui, "msgText", singleMenuString())
    }
    else
        killMenu()
}
void function selectItem(var e){
    int lastListIndex = menuInternal.functionIndexList.len()-1
    if(lastListIndex < 0)
        lastListIndex = 0
    menuInternal.lastSel = 0
    int index = menuInternal.functionIndexList[lastListIndex]
    menuInternal.itemSelect[index][menuInternal.selected[lastSelectedIndex()]]()
    if(menuInternal.killFollowing){
        menuInternal.killFollowing = false
        killMenu()
        return
    }
    menuSettings.appendStretchX += menuSettings.increaseStretchX
    if(!menuSettings.useCompact)
        updateRuntimeMenu()
    else
        RuiSetString(menuInternal.menuRui, "msgText", singleMenuString())
}

void function updateRuntimeMenu(){
    if(!menuSettings.useCompact){
        foreach (rui in menuInternal.menuRuis) {
                RuiDestroyIfAlive(rui)
        menuInternal.menuRuis.clear()
        colorMenuItem()
        }
    }
    else {
        RuiSetString(menuInternal.menuRui, "msgText", singleMenuString())
    }
        // destroyTopology()
        // vector sx = menuSettings.topoStretchX
        // sx.x = sx.x + menuSettings.appendStretchX
        // createTopology(sx)
    displayRuntimeMenu()
}

void function handleMenu(var pressedKey){
    menuInternal.showingMenu = !menuInternal.showingMenu
    if(menuInternal.showingMenu)
        {
            switch (menuSettings.menuCompact) {
                case 0:
                    if(GetPlayerArray().len() > menuSettings.maxPlayerDisplayExpensive)
                        menuSettings.useCompact = true
                    else
                        menuSettings.useCompact = false
                    break;
                case 1:
                    menuSettings.useCompact = true
                    break;
                case 2:
                    menuSettings.useCompact = false
                    break;
            }
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
    menuInternal.showingMenu = false
    if (!menuSettings.useCompact) {
        foreach (rui in menuInternal.menuRuis) {
            RuiDestroyIfAlive(rui)
        }
    }
    else
        RuiDestroyIfAlive(menuInternal.menuRui)
    deregisterMenuListeners()
    destroyTopology()
    RuiDestroyIfAlive(menuInternal.menuGroundRui)
    menuInternal.functionIndexList = [0]
    menuInternal.lastSel = 0
    menuInternal.menuRuis.clear()
    resetActiveMenuItemLists()
}

string function singleMenuString(){
    string mString = ""
    array < array < string > > l = menuInternal.activeMenuItemList
    int i
    int longest
    foreach (array < string > sl in l) {
        if(sl.len() > longest)
            longest = sl.len()
    }

    for (int i; i < longest; i++) {
        int emptyLists
        for(int ii; ii < l.len(); ii++){
            if(emptyLists >= l.len())
                break
            if(i >= l[ii].len()){
                for (int i; i < 11; i++) {
                    mString += " "
                }
                emptyLists++
                continue
            }
            else {
                string s = l[ii][i]
                int nSeperators = 11
                if(menuInternal.selected[ii] == i){
                    mString += ">"
                    nSeperators = 10
                }
                mString += s
                for (int i; i < nSeperators-s.len(); i++) {
                    mString += " "
                }
            }
        }
        mString += "\n"
    }
    return mString
}

void function createSingleRuntimeMenu(){
    menuInternal.menuRui = createRef(<menuSettings.xBaseSpace,menuSettings.yBaseSpace,0>, menuInternal.refTop, singleMenuString())
}

void function displayMultipleRuntimeMenu(){
    for (int i; i < menuInternal.activeMenuItemList.len(); i++) {
        array < string > mItems = menuInternal.activeMenuItemList[i]
        for (int j; j < mItems.len(); j++) {
            menuInternal.menuRuis.append(createRef(
                <i*menuSettings.xSpace+menuSettings.xBaseSpace,
                j*menuSettings.ySpace+menuSettings.yBaseSpace, 0>
                , menuInternal.refTop, mItems[j]))
        }
    }
}

void function displayRuntimeMenu(){
    if(!menuSettings.useCompact)
        displayMultipleRuntimeMenu()
    else
        createSingleRuntimeMenu()
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

void function killRUIs(array <var > ruis) {
    foreach(rui in ruis) {
        RuiDestroyIfAlive(rui)
    }
}

void function ruiHandler() {
        array < array < var > > playerRows
        array < var > pingRuis
        // string nonLocalPlayerNames
        var playerRui
        var nonLocalRui
        var background
        while (script.displayAlive) {
        string nonLocalPlayerNames
        if(settings.drawBackground && background == null)
            background = RuiCreate($"ui/scoreboard_background.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 10)
        else if(!settings.drawBackground && background != null)
            {
                RuiDestroyIfAlive(background)
                background = null
            }

        nonLocalPlayerNames = ""
        array < entity > players = GetSpecifiedSortedPlayers(settings.orderBy, 0)
        for (int i = 0; i < players.len(); i++) {
            while (pingRuis.len() > players.len()) {
                RuiDestroyIfAlive(pingRuis.pop())
            }

            while (pingRuis.len() < players.len()) {
                pingRuis.append(createEmptyRUI())
            }

            /** USER PING COLOR */
            vector pingColor = settings.color
            if(settings.scaleColor)
              {
                float p = players[i].GetPlayerGameStat(PGS_PING).tofloat() / settings.capPing.tofloat()
                pingColor = < settings.lowLatencyColor.x+p*(settings.highLatencyColor.x-settings.lowLatencyColor.x),
                settings.lowLatencyColor.y+p*(settings.highLatencyColor.y-settings.lowLatencyColor.y),
                settings.lowLatencyColor.z+p*(settings.highLatencyColor.z-settings.lowLatencyColor.z) >
              }

            /** USERNAME COLOR*/
            vector usernameColor = settings.color
            if (players[i].GetPlayerName() == GetLocalClientPlayer().GetPlayerName()){
                usernameColor = settings.highlightColor
                nonLocalPlayerNames += "\n"
                if(playerRui)
                    RuiDestroyIfAlive(playerRui)
                playerRui = createEmptyRUI()
                RuiSetFloat3(playerRui, "msgColor", settings.highlightColor)
                RuiSetString(playerRui, "msgText", GetLocalClientPlayer().GetPlayerName())
                RuiSetFloat2(playerRui, "msgPos", < settings.horizontalPos, settings.verticalPos + i * 0.0175, 0.0 > )
            }

            else {
                nonLocalPlayerNames += players[i].GetPlayerName() + "\n"
            }

            /** APPLY PING */
            RuiSetFloat3(pingRuis[i], "msgColor", pingColor)
            RuiSetString(pingRuis[i], "msgText", players[i].GetPlayerGameStat(PGS_PING) + "ms")
            RuiSetFloat2(pingRuis[i], "msgPos", < settings.horizontalPos+0.1, settings.verticalPos+i*0.0175, 0.0 > )
            if(!nonLocalRui)
                nonLocalRui = createEmptyRUI()
            RuiSetFloat3(nonLocalRui, "msgColor", settings.color)
            RuiSetString(nonLocalRui, "msgText", nonLocalPlayerNames)
            RuiSetFloat2(nonLocalRui, "msgPos", < settings.horizontalPos, settings.verticalPos, 0> )
        }
        for (int i; i<5; i++){
            WaitFrame() // Update every 5 frames
        }
        if (!script.displayAlive) // Might change in while because of thread magic
        {
            if(settings.drawBackground && background != null)
                RuiDestroyIfAlive(background)
            killRUIs(pingRuis) // Kill remaining ruis
            RuiDestroyIfAlive(nonLocalRui)
            RuiDestroyIfAlive(playerRui)
            break
        }
    }
}
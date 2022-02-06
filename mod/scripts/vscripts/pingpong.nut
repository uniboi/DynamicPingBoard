global function pingDisplayPreCache

struct {
    float verticalPos = 0.00 // Vertical offset [0.0 -> 1.0]
    float horizontalPos = 0.75 // Horizontal offset [0.0 -> 1.0]
    vector color = Vector(1, 1, 1) // Default text color < %r, %g, %b >
    float textSize = 19 // value for font size, 19 is default
    float alpha = 0.6 // Text alpha
    float bold = 0.0 // Text boldness
    bool scaleColor = true // Scale ping color from lowLatencyColor to highLatencyColor relative to capPing
    bool drawUsernameLikePing = false // Draw ping and username in the same color. Excludes the player.
    int capPing = 300 // This ping and above gets the full highLatencyColor applied
    vector lowLatencyColor = Vector(0, 1, 0)
    vector highLatencyColor = Vector(1, 0, 0)
    vector highlightColor = Vector(1, 0.5, 0) // Highlighted text color < %r, %g, %b >
}settings

// Internal
struct {
    bool alive = false
}
script

void function pingDisplayPreCache() {
    thread menusTread()
}

void function menusTread() {
    WaitFrame()
    thread displayPings()
}

void function displayPings() {
    RegisterButtonPressedCallback(KEY_F1, handleDisplay)
}

void function handleDisplay(var pressedKey) {
    script.alive = !script.alive
    if (script.alive) {
        thread ruiHandler()
    }
    EmitSoundOnEntity(GetLocalClientPlayer(), "menu_click")
}

var function createEmptyRUI() {
    var rui = RuiCreate($"ui/cockpit_console_text_top_left.rpak", clGlobal.topoCockpitHudPermanent, RUI_DRAW_COCKPIT, 15)
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
        while (script.alive) {
        for (int i = 0; i < GetPlayerArray().len(); i++) {
            while (playerRows.len() > GetPlayerArray().len()) {
                array < var > row = playerRows.pop()
                RuiDestroyIfAlive(row[0]) // Destroy unused ruis
                RuiDestroyIfAlive(row[1])
            }
            while (playerRows.len() < GetPlayerArray().len()) {
                playerRows.append([createEmptyRUI(), createEmptyRUI()]) // Populate needed array slots
            }

            /** USER PING COLOR */
            vector pingColor = settings.color
            if(settings.scaleColor)
              {
                float p = GetPlayerArray()[i].GetPlayerGameStat(PGS_PING).tofloat() / settings.capPing.tofloat()
                pingColor = < settings.lowLatencyColor.x+p*(settings.highLatencyColor.x-settings.lowLatencyColor.x),
                settings.lowLatencyColor.y+p*(settings.highLatencyColor.y-settings.lowLatencyColor.y),
                settings.lowLatencyColor.z+p*(settings.highLatencyColor.z-settings.lowLatencyColor.z) >
              }

            /** USERNAME COLOR*/
            vector usernameColor = settings.color
            if (GetPlayerArray()[i].GetPlayerName() == GetLocalClientPlayer().GetPlayerName())
              usernameColor = settings.highlightColor
            else if(settings.drawUsernameLikePing)
              usernameColor = pingColor

            /** APPLY USERNAME */
            RuiSetFloat3(playerRows[i][0], "msgColor", usernameColor)
            RuiSetString(playerRows[i][0], "msgText", GetPlayerArray()[i].GetPlayerName())
            RuiSetFloat2(playerRows[i][0], "msgPos", < settings.horizontalPos, settings.verticalPos + i * 0.025, 0.0 > )

            /** APPLY PING */
            RuiSetFloat3(playerRows[i][1], "msgColor", pingColor)
            RuiSetString(playerRows[i][1], "msgText", GetPlayerArray()[i].GetPlayerGameStat(PGS_PING) + "ms")
            RuiSetFloat2(playerRows[i][1], "msgPos", < settings.horizontalPos+0.1, settings.verticalPos+i*0.025, 0.0 > )

            WaitFrame() // Update every frame
        }
        if (!script.alive) // Might change in while because of thread magic
        {
          killRUIs(playerRows) // Kill remaining ruis
          break
        }
    }
}
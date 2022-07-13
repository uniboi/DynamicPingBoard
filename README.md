# Dynamic Ping Board
Pressing F1 toggles the list on / off.
Pressing U toggles the runtime menu on / off.
## Functionality
When open, a list of every connected player is displayed. The displayed information includes the username and current ping.
You can open the menu while playing to change settings related to the ping display.

## Menu Settings
* sort
    + asc sorts by ascending ping
    + desc sorts by descending ping
    + name asc sort by names alphabetically
    + name desc does the reverse
* background
    + switches the background of the ping display on / off

You can use these options while the ping display is active

## Navigating the Menu
Press U to show or hide the menu. Navigate up/down with `I`/`K`. Select Items with `L` and close the last submenu with `J`.

![ping_ascending](https://raw.githubusercontent.com/uniboi/DynamicPingBoard/master/mod/images/ping_ascending.png)
![ping_descedning](https://raw.githubusercontent.com/uniboi/DynamicPingBoard/master/mod/images/ping_descending.png)
![names_ascending](https://raw.githubusercontent.com/uniboi/DynamicPingBoard/master/mod/images/names_ascending.png)
![names_descending](https://raw.githubusercontent.com/uniboi/DynamicPingBoard/master/mod/images/names_descending.png)

## Optional Ping Display Settings
* `float verticalPos` Vertical display offset
* `float horizontalPos` Horizonzal display offset
* `vector color` Default text color used for pings and usernames
* `float textSize` Text size
* `float alpha`
* `float bold`
* `scaleColor` If `true` the ping color is normalized between `lowlatencyColor` and `highLatencyColor`
* `vector lowlatencyColor`
* `vector highLatencyColor`
* `vector highlightColor` Username color
* `int capPing` every ping is normalized in comparison to this number. The number and everything greater has the color `highLatencyColor`

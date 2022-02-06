# Northstar-PingBoard
Pressing F1 toggles the list on / off.
## Functionality
When open, a list of every connected player is displayed. Displayed informations are the username and current ping.

## Optional Settings
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
* `drawUsernameLikePing` Draw usernames in the same color like the corresponding ping

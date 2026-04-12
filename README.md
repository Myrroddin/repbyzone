# RepByZone

RepByZone automatically updates the watched reputation bar to match the faction most relevant to your current location. When you move between cities, quest hubs, dungeons, raids, and battlegrounds, the addon switches to the reputation mapped for that area instead of leaving the bar on whichever faction was watched last.

That includes city reputations such as Stormwind and Orgrimmar, battleground reputations such as Silverwing Sentinels and Warsong Outriders, and instance reputations such as Hydraxian Waterlords and Brood of Nozdormu.

## Highlights

- Automatically switches the watched reputation for zones, subzones, instances, and battlegrounds
- Falls back to a configurable default watched reputation when an area has no specific mapping
- Can print a chat message whenever the watched reputation changes
- Can keep switching while you are on taxi flights
- Supports Classic Era variants, The Burning Crusade Classic, Mists of Pandaria Classic, and Retail

## Version-specific features

- Classic Era variants, including Hardcore, Fresh, and Season of Discovery, support zone, subzone, instance, battleground, fallback, taxi, and verbose handling
- The Burning Crusade Classic supports the same core switching behavior as Classic Era
- Mists of Pandaria Classic adds Pandaren handling and faction tabard support in older 5-player dungeons
- Retail adds faction tabard support in older 5-player dungeons, optional WoD garrison bodyguard tracking, and other retail-specific reputation handling

## How it works

1. If subzone tracking is enabled, RepByZone checks for a mapped subzone first.
2. If you are in an instance, it checks the instance mapping.
3. Otherwise it checks the current zone and then the parent zone.
4. If no mapping exists, it uses your configured default watched reputation.
5. If the default is set to None, the watched reputation bar is cleared when no mapped reputation exists.

On supported clients, special rules can also take precedence:

- Faction tabards in older 5-player dungeons
- WoD garrison bodyguards in Draenor zones when that option is enabled

## Open the options

- `/rbz`
- `/repbyzone`
- Blizzard's AddOns settings panel for RepByZone

## Configuration

- Enable or disable the addon
- Watch subzones
- Print chat messages when the watched reputation changes
- Switch reputations while on taxi flights
- Adjust the delay used after zone changes before reading reputation data
- Choose a default watched reputation per character
- Use the Profiles tab to keep separate settings for alts or different play styles
- Mists of Pandaria Classic and Retail: use faction tabards in supported dungeons
- Mists of Pandaria Classic and Retail: stop using tabard reputations after Exalted
- Retail: prefer active WoD garrison bodyguard reputations in selected Draenor zones

## Installation

1. Download the addon package from CurseForge.
2. Extract it into the `Interface/AddOns` folder for the WoW client you play.
3. Make sure the final folder is named `RepByZone`.
4. Reload the UI or restart the client.

Project pages:

- CurseForge: [RepByZone](https://www.curseforge.com/wow/addons/repbyzone)
- GitHub: [Myrroddin/repbyzone](https://github.com/Myrroddin/repbyzone)
- Wowinterface: [RepByZone](https://www.wowinterface.com/downloads/info25407-RepByZone.html)
- Wago AddOns: [RepByZone](https://addons.wago.io/addons/repbyzone)

## Localization

RepByZone ships with translations for English, German, Spanish (ES and MX), French, Italian, Korean, Brazilian Portuguese, Russian, Simplified Chinese, and Traditional Chinese.

Localization contributions can be made through CurseForge's [online localization page](https://legacy.curseforge.com/wow/addons/repbyzone/localization).

## Support

Report bugs or missing reputation mappings on [GitHub Issues](https://github.com/Myrroddin/repbyzone/issues).

Helpful details to include in a report:

- WoW client and version
- Character faction and race
- Exact zone, subzone, or instance
- Expected reputation and actual watched reputation

## Limitations

- The WoW API does not let addons watch a reputation your character has not discovered yet.
- After a character first gains or loses reputation with that faction, RepByZone can switch to it normally.
- Blizzard's API can lag briefly after zone changes, so the addon uses a configurable delay before updating the watched bar.

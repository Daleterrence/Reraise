# Reraise

A Windower addon for FFXI that helps you keep up Reraise. Simply type `//rr` and the addon will use your best available Reraise spell or item based on a priority system.

## What it does

- Uses the best available Reraise spell or item you currently have access to with a single command
- Shows a status display telling you if you have Reraise and where it came from
- Automatically detects Reraise from spells, common items, Cait Sith, and Goddess's Hymnus
- Handles equipment-based Reraise items with GearSwap integration, using the Sels GearSwap library for item use if you have it, otherwise auto-disabling and re-enabling the slot the Reraise item is in.
- Scans all your normally reachable bags for Reraise items and automatically moves them to inventory when needed (itemizer not required!)

## Commands

- `//rr` - Uses your best available Reraise
- `//rr silence` - Toggle silence bypass mode (will attempt to use Reraise items if you are silenced, but could normally cast a Reraise spell, if off, will simply inform you about your Silence debuff. You should probably do something about that.)
- `//rr display` - Show/hide the status display
- `//rr help` - Show command list

## Display

The status display shows:
- **Green text**: "You have Reraise from [source]." when active
- **Red text**: "You don't have Reraise!" when you don't have it

The display can be dragged anywhere on screen and your position is automatically saved.

## Settings

Settings are saved in `data/settings.xml` and can be customized:
- Display position, colors, fonts, and sizes
- Silence bypass mode, default off (will try to use a Reraise item if you normally have access to a Reraise spell, but you're silenced)
- Reraise priorities can be changed in `settings.lua` to your personal taste.

## Installation

1. Download the addon from the releases [here](https://github.com/Daleterrence/Reraise/releases/tag/1.0.0)
1. Extract the zip and copy the `Reraise` folder to `Windower/addons/`
2. Load with `//lua load Reraise`
3. Optionally add to your `init.txt` to auto-load

## Known Issues

- The addon does not currently track Reraise gained from rarer Reraise items, nor will it attempt to use from those sources. It also does not know where Reraise from Field Manuals or random other places in the game came from, and will just state it's an unknown source on the display.
- I have used the word Reraise 23 times in this readme and now the word has lost all meaning to me.

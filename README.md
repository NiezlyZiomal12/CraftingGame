# Crafting Game

A small starting point for a LÖVE (Love2D) game.

## Run

Open this folder with LÖVE, or run `love .` from this folder.

## Controls

Click **Next time**, or press Space or Enter, to move through Morning, Afternoon, Evening, and Night. After Night, the next day begins. After Sunday (Day 7), a new week begins.

Click **EQ** to open or close the inventory. Hover over an item to see its details. The inventory stays available as time advances.
Use the mouse wheel while the pointer is over the inventory to scroll through items that do not fit on screen.

In the morning, click **Crafting** to see recipes on the right. A Steel Sword costs 2 Iron Bars and 1 Wood. Click **Craft** to use those materials and add the sword to your inventory. The Craft button is unavailable when you lack materials, and the crafting panel closes when morning ends.

## Folders

- `src/day_cycle.lua` keeps the day, week, and time state.
- `src/scenes/day.lua` draws the starting scene and handles input.
- `src/items.lua` defines items, while `src/inventory.lua` stores quantities and provides `add` and `remove` functions for later game features.
- `src/recipes.lua` lists recipes, and `src/crafting.lua` checks ingredients and draws the crafting panel.
- `assets/` is ready for images, sounds, and fonts later.

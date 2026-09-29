# Crafting Game

A small starting point for a LÖVE (Love2D) game.

## Run

Open this folder with LÖVE, or run `love .` from this folder.

## Controls

Click **Next time**, or press Space or Enter, to move through Morning, Afternoon, Evening, and Night. After Night, the next day begins. After Sunday (Day 7), a new week begins.

Click **Inventory** to open or close the inventory. Hover over an item to see its details. The inventory stays available as time advances.
Use the mouse wheel while the pointer is over the inventory to scroll through items that do not fit on screen.

In the morning, click **Crafting** to see recipes on the right. A Steel Sword costs 2 Iron Bars and 1 Wood. Click **Craft** to use those materials and add the sword to your inventory. The Craft button is unavailable when you lack materials, and the crafting panel closes when morning ends.

In the afternoon, click **Selling** to open the sell container and your inventory. Click an inventory item to move one into the container. Click an item in the container to take one back, or click **Sell all** to exchange the contents for coins. Unsold items return to your inventory when afternoon ends. Each item's coin value is defined in `src/items.lua` and shown in its tooltip.

Coins earned from **Sell all** are added to the shared quota total when afternoon ends. The quota target and current total are in `src/game_state.lua`.

In the evening, click **Loadout** to prepare for the night. Click equipment or consumables in your inventory to place one into a matching slot. Click a filled loadout slot to return its item to inventory. Equipping another item in an occupied armor or weapon slot swaps the old item back. The five consumable slots each hold one item. The loadout stays equipped for the night, and the panel can be reopened the next evening.

Item definitions in `src/items.lua` now include `equipmentSlot`, `strongPower`, `survivability`, and `looting`. Armor, a starter sword, five healing potions, and two power tonics are included so you can try every loadout slot. The panel shows combined stats from equipped items.

At night, choose Woods, Desert, or Tundra and a tier in the exploration panel. You need at least the recommended power to enter. Each survivability point adds 3.5 percentage points to the survival chance, up to 95%. Every two looting points add one item to the first reward. You can make one expedition attempt per night. On success, loot is added to Inventory and equipped items return. On failure, you stay alive but get no loot and lose all equipped loadout items. Skipping the expedition returns the loadout safely when the next morning begins.

The player has 1 base power, so Woods Tier 1 remains available even after losing all equipment.

## Folders

- `src/day_cycle.lua` keeps the day, week, and time state.
- `src/scenes/day.lua` draws the starting scene and handles input.
- `src/items.lua` defines items, while `src/inventory.lua` stores quantities and provides `add` and `remove` functions for later game features.
- `src/recipes.lua` lists recipes, and `src/crafting.lua` checks ingredients and draws the crafting panel.
- `src/selling.lua` manages the afternoon sell container and coin total.
- `src/game_state.lua` stores the shared coin total and quota target.
- `src/loadout.lua` stores equipped items and shows their combined power, survivability, and looting stats.
- `src/locations.lua` defines expedition tiers and rewards; `src/exploration.lua` handles night expeditions.
- `src/item_tooltip.lua` shows all item details on inventory and recipe hover.
- `assets/` is ready for images, sounds, and fonts later.

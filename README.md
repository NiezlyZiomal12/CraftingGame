# Crafting Game

A small starting point for a LÖVE (Love2D) game.

## Run

Open this folder with LÖVE, or run `love .` from this folder.

## Controls

Click **Next time**, or press Space or Enter, to move through Morning, Afternoon, Evening, and Night. After Night, the next day begins. After Sunday (Day 7), a new week begins.

## Folders

- `src/day_cycle.lua` keeps the day, week, and time state.
- `src/scenes/day.lua` draws the starting scene and handles input.
- `assets/` is ready for images, sounds, and fonts later.

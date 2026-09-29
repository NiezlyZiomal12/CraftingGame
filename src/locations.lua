return {
    {
        name = "Woods",
        tiers = {
            { requiredPower = 1, baseSurvival = 0.65, loot = { { id = "wood", quantity = 2 }, { id = "fiber", quantity = 2 } } },
            { requiredPower = 4, baseSurvival = 0.50, loot = { { id = "wood", quantity = 4 }, { id = "fiber", quantity = 3 } } },
            { requiredPower = 6, baseSurvival = 0.35, loot = { { id = "wood", quantity = 6 }, { id = "fiber", quantity = 5 }, { id = "healing_potion", quantity = 1 } } },
        },
    },
    {
        name = "Desert",
        tiers = {
            { requiredPower = 4, baseSurvival = 0.55, loot = { { id = "stone", quantity = 2 }, { id = "fiber", quantity = 1 } } },
            { requiredPower = 6, baseSurvival = 0.40, loot = { { id = "stone", quantity = 4 }, { id = "iron_bar", quantity = 1 } } },
            { requiredPower = 8, baseSurvival = 0.25, loot = { { id = "stone", quantity = 6 }, { id = "iron_bar", quantity = 3 } } },
        },
    },
    {
        name = "Tundra",
        tiers = {
            { requiredPower = 6, baseSurvival = 0.45, loot = { { id = "iron_bar", quantity = 1 }, { id = "fiber", quantity = 2 } } },
            { requiredPower = 8, baseSurvival = 0.30, loot = { { id = "iron_bar", quantity = 2 }, { id = "healing_potion", quantity = 1 } } },
            { requiredPower = 10, baseSurvival = 0.15, loot = { { id = "iron_bar", quantity = 4 }, { id = "healing_potion", quantity = 2 }, { id = "steel_sword", quantity = 1 } } },
        },
    },
}

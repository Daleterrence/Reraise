--[[Reraise Data Module
Contains all reraise spells and items with their types and priorities]]

res = require('resources')

local reraise_data = {}

-- Reraise Spells
reraise_data.spell_names = {
    "Reraise", -- WHM lv. 25, SCH lv. 35 (requires the Scholar to have Addendum: White active)
    "Reraise II", -- WHM lv. 56, SCH lv. 70 (requires the Scholar to have Addendum: White active)
    "Reraise III", -- WHM lv. 70, SCH lv. 91 (requires the Scholar to have Addendum: White active)
    "Reraise IV", -- WHM Job Points, requires 100 JP.
}

-- Reraise items and their types
-- Types: 'instant' = use immediately from inventory, 'equip' = must be equipped to use
reraise_data.item_definitions = {
    -- Instant use items (sub_priority: lower number = better reraise)
    { name = "Super Reraiser", type = "instant", priority = 2, sub_priority = 1 }, -- Grants Reraise 3, 1 second use time
    { name = "Hi-Reraiser", type = "instant", priority = 2, sub_priority = 2 }, -- Grants Reraise 2, 1 second use time
    { name = "Dusty Reraise", type = "instant", priority = 2, sub_priority = 3 }, -- Grants Reraise 1, 1 second use time, Temporary Item
    { name = "Instant Reraise", type = "instant", priority = 2, sub_priority = 3 }, -- Grants Reraise 1, 1 second use time
    { name = "Reraiser", type = "instant", priority = 2, sub_priority = 3 }, -- Grants Reraise 1, 1 second use time
    { name = "Scapegoat", type = "instant", priority = 2, sub_priority = 3 }, -- Grants Reraise 1, 1 second use time
    
    -- Equipment-based reraise items (sub_priority: higher tier reraise + shorter cooldown = lower number)
    -- slot: equipment slot name, equip_delay: seconds to wait after equipping before using
    { name = "Raphael's Rod", type = "equip", priority = 3, sub_priority = 1, slot = "main", equip_delay = 30 }, -- Grants Reraise 3, 8 second use time, cannot be reused for 2 minutes
    { name = "Airmid's Gorget", type = "equip", priority = 3, sub_priority = 2, slot = "neck", equip_delay = 30 }, -- Grants Reraise 3 effect
    { name = "Reraise Gorget", type = "equip", priority = 3, sub_priority = 3, slot = "neck", equip_delay = 30 }, -- Grants Reraise 2, 10 second use time, cannot be reused for 2 minutes
    { name = "Reraise Hairpin", type = "equip", priority = 3, sub_priority = 4, slot = "head", equip_delay = 30 }, -- Grants Reraise 2, 8 second use time, cannot be reused for 1 minute
    { name = "Reraise Earring", type = "equip", priority = 3, sub_priority = 5, slot = "ear1", equip_delay = 30 }, -- Grants Reraise 1, cannot be reused for 1 minute
    { name = "Raising Earring", type = "equip", priority = 3, sub_priority = 6, slot = "ear1", equip_delay = 30 }, -- Grants Reraise 1, 8 second use time, cannot be reused for 10 minutes
    { name = "Mamool Ja Earring", type = "equip", priority = 3, sub_priority = 7, slot = "ear1", equip_delay = 30 }, -- Grants Reraise 3, 16 second use time, cannot be reused for 12 hours
    { name = "Reraise ring", type = "equip", priority = 3, sub_priority = 8, slot = "ring1", equip_delay = 30 }, -- Grants Reraise 1, 2 second use time, cannot be reused for 20 hours
    { name = "Wh. Rarab Cap +1", type = "equip", priority = 3, sub_priority = 9, slot = "head", equip_delay = 30 }, -- Grants Reraise 1, 8 second use time, cannot be reused for 20 hours
}

-- Build item lookup table from resources
reraise_data.items = {}
for _, item_def in ipairs(reraise_data.item_definitions) do
    for id, item in pairs(res.items) do
        if item.en == item_def.name then
            reraise_data.items[id] = {
                name = item.en,
                type = item_def.type,
                priority = item_def.priority,
                sub_priority = item_def.sub_priority or 0,
                slot = item_def.slot,
                equip_delay = item_def.equip_delay or 0
            }
            break
        end
    end
end

-- Default priority order (lower number = higher priority)
-- 1 = Spells (highest priority)
-- 2 = Instant use items
-- 3 = Equipment items (lowest priority)
reraise_data.default_priorities = {
    spell = 1,
    instant = 2,
    equip = 3
}

return reraise_data

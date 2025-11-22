--[[Settings Module
Manages user-configurable settings and priority overrides]]

config = require('config')

local settings_module = {}

-- Default settings structure
local defaults = {
    priority_overrides = {},
    silence_bypass = false,  -- Skip spells and use items when silenced
    display = {
        pos = {
            x = 100,
            y = 100
        }
    },
    display_settings = {
        bg = {
            alpha = 200,
            red = 0,
            green = 0,
            blue = 0,
            visible = true
        },
        flags = {
            draggable = true,
            bold = false
        },
        text = {
            size = 12,
            font = 'Arial',
            alpha = 255,
            red = 255,
            green = 255,
            blue = 255
        },
        stroke = {
            width = 5,
            alpha = 255,
            red = 0,
            green = 0,
            blue = 0
        }
    }
}

-- Load settings from config file
function settings_module.load()
    local settings = config.load('data/settings.xml', defaults)
    return settings
end

-- Save settings to config file
function settings_module.save(settings)
    config.save(settings, 'all')
end

-- Set priority for a specific type
function settings_module.set_priority(type_name, priority)
    local settings = settings_module.load()
    settings.priority_overrides[type_name] = priority
    settings_module.save(settings)
end

-- Reset priority overrides to defaults
function settings_module.reset_priorities()
    local settings = settings_module.load()
    settings.priority_overrides = {}
    settings_module.save(settings)
end

-- Set silence bypass mode
function settings_module.set_silence_bypass(enabled)
    local settings = settings_module.load()
    settings.silence_bypass = enabled
    settings_module.save(settings)
end

return settings_module

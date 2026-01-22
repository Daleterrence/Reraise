--[[

Copyright © 2026, DTR
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of PhantomGem nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL DTR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]

_addon.name = 'Reraise'
_addon.author = 'DTR'
_addon.version = '1.0.1'
_addon.commands = {'rr'}

require('tables')
require('sets')
require('strings')
require('logger')
config = require('config')
texts = require('texts')
res = require('resources')

local reraise_data = require('reraise_data')
local settings_module = require('settings')
local settings = settings_module.load()
local display = nil
local has_reraise = false
local reraise_source = nil
local arise_pending = false  
local player_was_dead = false 
local pending_reraise_item = nil 
local pending_slot_enable = nil  
local silence_bypass = false 

-- Check for Sels
local sels_available = false
local sels_path = windower.addon_path:match('(.+[/\\])addons[/\\]') .. 'addons\\GearSwap\\libs\\Sel-Include.lua'
if windower.file_exists(sels_path) then
    sels_available = true
end

windower.register_event('load', function()
    settings = settings_module.load()
    silence_bypass = settings.silence_bypass or false
    local text_settings = {}
    for k, v in pairs(settings.display) do
        text_settings[k] = v
    end
    for k, v in pairs(settings.display_settings) do
        text_settings[k] = v
    end
    
    display = texts.new('${status}', text_settings)
    check_reraise_status()
end)

local last_position_save = 0
local last_known_x = nil
local last_known_y = nil

windower.register_event('prerender', function()
    if display and display:visible() then
        local current_time = os.clock()
        if current_time - last_position_save > 2 then
            local pos_x, pos_y = display:pos()
            if last_known_x == nil then
                last_known_x = pos_x
                last_known_y = pos_y
            end
            
            if pos_x ~= last_known_x or pos_y ~= last_known_y then
                settings.display.pos.x = pos_x
                settings.display.pos.y = pos_y
                settings_module.save(settings)
                last_known_x = pos_x
                last_known_y = pos_y
                last_position_save = current_time
            end
        end
    end
end)

-- Check if player has Reraise buff
function check_reraise_status()
    local player = windower.ffxi.get_player()
    if not player then return end
    
    local buffs = windower.ffxi.get_player().buffs
    
    local has_reraise_buff = false
    local has_hymnus = false
    
    for _, buff_id in pairs(buffs) do
        if buff_id == 113 then
            has_reraise_buff = true
        elseif buff_id == 218 then
            has_hymnus = true
            has_reraise_buff = true
        end
    end
    
    -- If we have Hymnus buff, mark it as the source if we don't have another tracked source
    if has_hymnus and not reraise_source then
        reraise_source = "Goddess's Hymnus"
    end
    
    has_reraise = has_reraise_buff
    update_display()
end

-- Format the source with proper grammar
function format_reraise_source(source)
    if not source then
        return "an unknown source.."
    end
    
    -- Check if it's a spell
    if source == "Reraise" or source == "Reraise II" or source == "Reraise III" or source == "Reraise IV" then
        return "the " .. source .. " spell"
    end
    
    -- Special cases
    if source == "Arise" then
        return "the Arise spell"
    elseif source == "Cait Sith" then
        return "Cait Sith"
    elseif source == "Goddess's Hymnus" then
        return "the song Goddess's Hymnus"
    end
    
    -- Items: Grammatically determine "a" vs "an"
    local article = "a"
    if source:match("^[AEIOUaeiou]") then
        article = "an"
    end
    
    return article .. " " .. source
end

-- Update the display text
function update_display()
    if has_reraise then
        local source_text = format_reraise_source(reraise_source)
        display:text('You have Reraise from ' .. source_text .. '.')
        display:color(0, 255, 0)
        display:size(12)
    else
        display:text('You don\'t have Reraise!')
        display:color(255, 0, 0)
        display:bold(true)
        display:size(16)
    end
    display:show()
end

-- Find available Reraise items in all accessible bags
function find_reraise_items()
    local available_items = {}
    local bags_to_check = {0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
    
    for _, bag_id in ipairs(bags_to_check) do
        local bag = windower.ffxi.get_items(bag_id)
        if bag then
            for slot, item in pairs(bag) do
                if type(item) == 'table' and item.id ~= 0 and reraise_data.items[item.id] then
                    local item_data = reraise_data.items[item.id]
        
                    local can_use = false
                    local needs_move = false
                    
                    if item_data.type == 'equip' then
                        if bag_id == 0 or (bag_id >= 8 and bag_id <= 16) then
                            can_use = true
                        end
                    elseif item_data.type == 'instant' then
                        if bag_id == 0 then
                            can_use = true
                        elseif bag_id == 5 or bag_id == 6 or bag_id == 7 then
                            can_use = true
                            needs_move = true
                        end
                    end
                    
                    if can_use then
                        table.insert(available_items, {
                            id = item.id,
                            name = item_data.name,
                            type = item_data.type,
                            priority = item_data.priority,
                            sub_priority = item_data.sub_priority or 0,
                            slot = item_data.slot,
                            equip_delay = item_data.equip_delay,
                            bag_id = bag_id,
                            bag_slot = slot,
                            needs_move = needs_move
                        })
                    end
                end
            end
        end
    end
    
    return available_items
end

-- Check if player has a Reraise spell available and can cast it
function has_reraise_spell()
    local player = windower.ffxi.get_player()
    if not player then return nil, nil, nil end
    
    local player_spells = windower.ffxi.get_spells()
    local main_job = player.main_job
    local sub_job = player.sub_job
    local main_level = player.main_job_level
    local sub_level = player.sub_job_level
    local job_points = player.job_points and player.job_points.whm and player.job_points.whm.jp_spent or 0
    local buffs = player.buffs
    
    -- Check for silence or mute
    local is_silenced = false
    for _, buff_id in pairs(buffs) do
        if buff_id == 6 or buff_id == 29 then
            is_silenced = true
            break
        end
    end
    
    -- If silenced, return silence status
    if is_silenced then
        return nil, nil, "silenced"
    end
    
    -- Check if player is WHM or SCH
    local is_whm_main = main_job == "WHM"
    local is_whm_sub = sub_job == "WHM"
    local is_sch_main = main_job == "SCH"
    local is_sch_sub = sub_job == "SCH"
    
    -- If SCH but not WHM, check for Addendum: White
    if (is_sch_main or is_sch_sub) and not (is_whm_main or is_whm_sub) then
        local has_addendum = false
        for _, buff_id in pairs(buffs) do
            if buff_id == 401 then
                has_addendum = true
                break
            end
        end
        if not has_addendum then
            return nil, nil, "need_addendum"
        end
    end
    
    -- Check each Reraise spell from highest to lowest
    local spell_requirements = {
        {name = "Reraise IV", min_level = 99, whm_only = true, requires_jp = 100},
        {name = "Reraise III", min_level = 70, min_sub_level = 91},
        {name = "Reraise II", min_level = 56, min_sub_level = 70},
        {name = "Reraise", min_level = 25, min_sub_level = 35}
    }
    
    for _, req in ipairs(spell_requirements) do
        -- Look up spell in resources
        for spell_id, spell in pairs(res.spells) do
            if spell.en == req.name then
                -- Check if player has learned this spell
                if player_spells[spell_id] then
                    -- Check job and level requirements
                    local can_cast = false
                    
                    if is_whm_main then
                        -- Main WHM - check main level
                        if main_level >= req.min_level then
                            -- Check JP requirement for Reraise IV
                            if req.requires_jp then
                                if job_points >= req.requires_jp then
                                    can_cast = true
                                end
                            else
                                can_cast = true
                            end
                        end
                    elseif is_whm_sub then
                        -- Sub WHM - check sub level
                        if req.min_sub_level and sub_level >= req.min_sub_level then
                            can_cast = true
                        end
                    elseif is_sch_main then
                        -- Main SCH - check main level
                        if not req.whm_only and req.min_sub_level and main_level >= req.min_sub_level then
                            can_cast = true
                        end
                    elseif is_sch_sub then
                        -- Sub SCH - check sub level
                        if req.min_sub_level and sub_level >= req.min_sub_level then
                            can_cast = true
                        end
                    end
                    
                    if can_cast then
                        return spell_id, {
                            name = spell.en,
                            type = "spell",
                            priority = 1,
                            sub_priority = 0  -- Spells always have highest priority
                        }, nil
                    end
                end
                break
            end
        end
    end
    
    return nil, nil, nil
end

function get_effective_priority(item_type)
    if settings.priority_overrides[item_type] then
        return settings.priority_overrides[item_type]
    end
    return reraise_data.default_priorities[item_type]
end

function sort_by_priority(items)
    table.sort(items, function(a, b)
        local a_priority = get_effective_priority(a.type)
        local b_priority = get_effective_priority(b.type)
        return a_priority < b_priority
    end)
    return items
end

function use_reraise_spell(spell_id, spell_info)
    windower.send_command('input /ma "' .. spell_info.name .. '" <me>')
    reraise_source = spell_info.name
    
    -- Delayed check to confirm buff applied
    coroutine.schedule(function()
        check_reraise_status()
    end, 3)
end

function use_reraise_item(item)
    pending_reraise_item = item.name
    
    if item.type == 'instant' then
        -- Check if item needs to be moved to inventory first
        if item.needs_move then
            windower.ffxi.move_item(item.bag_id, 0, item.bag_slot, 1)
            
            -- Wait for item to be moved before using it
            coroutine.schedule(function()
                windower.send_command('input /item "' .. item.name .. '" <me>')
                reraise_source = item.name
            end, 0.5)
        else
            -- Item is already in inventory, use it directly
            windower.send_command('input /item "' .. item.name .. '" <me>')
            reraise_source = item.name
        end
    elseif item.type == 'equip' then
        local slot = item.slot or 'ammo'
        
        if sels_available then
            -- Use Sels if user has it
            windower.send_command('gs c useitem ' .. slot .. ' "' .. item.name .. '"')
            reraise_source = item.name
        else
            -- Manual GearSwap handling: disable slot, equip, wait, use
            local delay = item.equip_delay or 2
            local use_delay = delay + 2  -- Add 2 second buffer to ensure item is ready
            
            -- Store slot to re-enable later (after item use confirmation)
            pending_slot_enable = slot
            
            -- Disable GearSwap for this slot
            windower.send_command('gs disable ' .. slot)
            
            -- Equip the item
            coroutine.schedule(function()
                windower.send_command('input /equip ' .. slot .. ' "' .. item.name .. '"')
                log('Equipping ' .. item.name .. '. Using item in ' .. use_delay .. ' seconds...')
                
                -- Wait for equip delay + buffer, then use item
                coroutine.schedule(function()
                    log('Attempting to use: ' .. item.name)
                    windower.send_command('input /item "' .. item.name .. '" <me>')
                    reraise_source = item.name
                end, use_delay)
            end, 1)
        end
    end
end

-- Main Reraise function
function use_reraise()
    if has_reraise then
        error('You already have Reraise active!')
        return
    end
    
    -- Check for spells first
    local spell_id, spell_info, spell_status = has_reraise_spell()
    local available_items = find_reraise_items()
    
    -- Handle spell status messages
    if spell_status == "silenced" then
        if silence_bypass then
            log('You are Silenced! Bypassing spells and using items.')
            -- Continue to items below
            spell_id = nil
            spell_info = nil
        else
            error('You are Silenced! Use //rr silence to if you want to skip spells when Silenced and use items instead.')
            return
        end
    elseif spell_status == "need_addendum" then
        error('You need Addendum: White active to cast Reraise!')
        return
    end
    
    -- Build list of all available options
    local options = {}
    
    if spell_id and spell_info then
        table.insert(options, {
            type = 'spell',
            priority = get_effective_priority('spell'),
            sub_priority = spell_info.sub_priority or 0,
            spell_id = spell_id,
            spell_info = spell_info
        })
    end
    
    for _, item in ipairs(available_items) do
        table.insert(options, {
            type = item.type,
            priority = get_effective_priority(item.type),
            sub_priority = item.sub_priority or 0,
            item = item
        })
    end
    
    if #options == 0 then
        log('You have no Reraise items available, or access to any Reraise spells.')
        return
    end
    
    -- Sort by priority, then sub_priority
    table.sort(options, function(a, b)
        if a.priority == b.priority then
            return a.sub_priority < b.sub_priority
        end
        return a.priority < b.priority
    end)
    
    -- Use the highest priority option
    local best_option = options[1]
    if best_option.type == 'spell' then
        use_reraise_spell(best_option.spell_id, best_option.spell_info)
    else
        use_reraise_item(best_option.item)
    end
end

windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or ''
    
    if command == 'silence' then
        silence_bypass = not silence_bypass
        settings_module.set_silence_bypass(silence_bypass)
        if silence_bypass then
            log('Silence bypass enabled. Will use items instead of spells when silenced.')
        else
            log('Silence bypass disabled. Will not try to use Reraise items when silenced.')
        end
    elseif command == 'display' then
        if display:visible() then
            display:hide()
        else
            display:show()
        end
    elseif command == 'help' then
        log('Reraise Commands:')
        log('  //rr - Use best available reraise')
        log('  //rr silence - Toggle silence bypass mode')
        log('  //rr display - Toggle status display')
    else
        use_reraise()
    end
end)

-- Monitor buff changes
windower.register_event('gain buff', function(buff_id)
    if buff_id == 113 then
        check_reraise_status()
    elseif buff_id == 218 then
        reraise_source = "Goddess's Hymnus"
        check_reraise_status()
    end
end)

windower.register_event('lose buff', function(buff_id)
    if buff_id == 113 or buff_id == 218 then
        has_reraise = false
        reraise_source = nil
        update_display()
    end
end)

-- Monitor action packets
windower.register_event('action', function(act)
    local player = windower.ffxi.get_player()
    if not player then return end
    
    -- Check if this is the player's action
    if act.actor_id == player.id then
        if act.category == 4 then
            local spell_id = act.param
            -- Check if this spell is in resources and is a Reraise spell
            if res.spells[spell_id] then
                local spell_name = res.spells[spell_id].en
                -- Check if this is a Reraise spell
                for _, reraise_spell_name in ipairs(reraise_data.spell_names) do
                    if spell_name == reraise_spell_name then
                        -- Check if player is targeting themselves
                        for _, target in pairs(act.targets) do
                            if target.id == player.id then
                                -- Any successful action means the spell landed
                                for _, action in pairs(target.actions) do
                                    -- Don't check specific message, just that action exists
                                    reraise_source = spell_name
                                    update_display()
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
        
        -- Check for item usage
        if act.category == 5 and pending_reraise_item then
            -- Get the item name from the action
            local item_id = act.param
            if res.items[item_id] and res.items[item_id].en == pending_reraise_item then
                -- Check if item was used successfully
                for _, target in pairs(act.targets) do
                    for _, action in pairs(target.actions) do
                        if action.message == 37 or action.message == 122 or action.message == 375 then
                            pending_reraise_item = nil
                            
                            -- Re-enable GearSwap slot if one was disabled
                            if pending_slot_enable then
                                windower.send_command('gs enable ' .. pending_slot_enable)
                                pending_slot_enable = nil
                            else
                            end
                            
                            -- Brief delay to allow buff to register
                            coroutine.schedule(function()
                                check_reraise_status()
                            end, 1)
                            return
                        end
                    end
                end
            end
        end
    end
    
    -- Check for pet abilities
    if act.category == 13 then
        -- Check if player is targeted
        for _, target in pairs(act.targets) do
            if target.id == player.id then
                for _, action in pairs(target.actions) do
                    -- Check if this grants Reraise buff
                    if action.param == 113 and action.message == 319 then
                        reraise_source = "Cait Sith"
                        update_display()
                        break
                    end
                end
            end
        end
    end
    
    -- Check if this is a spell for Arise detection
    if act.category == 4 then
        local arise_id = nil
        for id, spell in pairs(res.spells) do
            if spell.en == "Arise" then
                arise_id = id
                break
            end
        end
        
        -- Check if Arise was cast successfully
        if arise_id and act.param == arise_id then
            -- Check if the player is a target and if action hit
            for _, target in pairs(act.targets) do
                if target.id == player.id then
                    -- Check if the spell succeeds
                    for _, action in pairs(target.actions) do
                        if action.message == 42 then
                            arise_pending = true
                            reraise_source = "Arise"
                            break
                        end
                    end
                    break
                end
            end
        end
    end
end)

windower.register_event('status change', function(new_status, old_status)
    local player = windower.ffxi.get_player()
    if not player then return end
    if new_status == 2 or new_status == 3 then
        player_was_dead = true
    end
    
    if (new_status == 0 or new_status == 1) and player_was_dead and arise_pending then
        arise_pending = false
        player_was_dead = false
        coroutine.schedule(function()
            check_reraise_status()
        end, 2)
    elseif (new_status == 0 or new_status == 1) and player_was_dead then
        -- Player revived but not from Arise
        player_was_dead = false
        arise_pending = false
    end
end)

windower.register_event('job change', function()
    check_reraise_status()
end)

windower.register_event('zone change', function()
    check_reraise_status()
end)


windower.register_event('unload', function()
    if display then
        display:hide()
    end
end)


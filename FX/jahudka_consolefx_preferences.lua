-- ReaScript Name: Preferences GUI for Jahudka's ConsoleFX scripts
-- Version: 2.0
-- Author: jahudka
-- Links:
--   Documentation https://github.com/jahudka/reaper-consolefx
-- Changelog:
--   v2.0 (2020-12-21)
--    - initial release
-- About:
--   This script is a GUI for the configuration of the ConsoleFX
--   scripts. It requires Scythe v3 to run, get it from ReaPack first!


package.path = (function ()
    local info = debug.getinfo(1, 'S')
    local s = package.config:sub(1, 1)
    return info.source:sub(2):gsub(s .. '[^' .. s .. ']+$', '') .. s .. '?.lua;' .. package.path
end)()

require('jahudka_consolefx_utils')

if not log then
    reaper.MB("This script depends on 'jahudka_consolefx_utils.lua' but it appears it isn't installed! Please install it first and then run this script again.", "Whoops!", 0)
end

local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()

local GUI = require('gui.core')

local prefs = read_preferences();

local plugin_types = {
    [1] = 'AU',
    [2] = 'VST',
}


local window = GUI.createWindow({
    name = 'ConsoleFX Preferences',
    w = 320,
    h = 450,
})

local layer = GUI.createLayer({
    name = 'Preferences'
})

local inpTypes = GUI.createElement({
    name = 'InpConsoleTypes',
    type = 'texteditor',
    x = 100,
    y = 20,
    w = 200,
    h = 160,
    caption = 'Console types: ',
    retval = table.concat(prefs['console_types'], '\n'),
})

local inpDefault = GUI.createElement({
    name = 'InpDefaultType',
    type = 'listbox',
    x = 100,
    y = 200,
    w = 200,
    h = 40,
    caption = 'Default type: ',
    list = prefs['console_types'],
    retval = { [indexOf(prefs['console_types'], prefs['default_type'])] = true }
})

local inpPluginType = GUI.createElement({
    name = 'InpPluginType',
    type = 'listbox',
    x = 100,
    y = 260,
    w = 100,
    h = 40,
    caption = 'Plugin type: ',
    list = plugin_types,
    retval = { [indexOf(plugin_types, prefs['plugin_type'])] = true },
})

local inpUseLGU = GUI.createElement({
    name = 'InpUseLgu',
    type = 'checklist',
    x = 100,
    y = 320,
    w = 200,
    h = 24,
    frame = false,
    caption = '',
    options = { 'Use Linked Gain Utility:' },
    selectedOptions = { [1] = prefs['use_linked_gain_utility'] }
})

local inpLGUPath = GUI.createElement({
    name = 'InpLGUPath',
    type = 'textbox',
    x = 100,
    y = 360,
    w = 200,
    caption = ' ',
    retval = prefs['linked_gain_utility_path'],
})

function inpTypes:afterLostFocus()
    inpDefault.list = split(inpTypes:val(), '[,\n ]+')
    inpDefault:redraw()
end

local function handleSave()
    prefs['console_types'] = split(inpTypes:val(), '[,\n ]+')
    prefs['default_type'] = prefs['console_types'][inpDefault:val()]
    prefs['plugin_type'] = plugin_types[inpPluginType:val()]
    prefs['use_linked_gain_utility'] = inpUseLGU:val()[1]
    prefs['linked_gain_utility_path'] = inpLGUPath:val()

    local err = save_preferences()

    if err == nil then
        reaper.MB("", "Preferences saved!", 0)
    else
        reaper.MB("Failed to save preferences: " .. err, "Whoops!", 0)
    end

    window:close()
end

local btnSave = GUI.createElement({
    name = 'BtnSave',
    type = 'button',
    x = 110,
    y = 400,
    w = 100,
    h = 30,
    caption = 'Save & Close',
    func = handleSave,
})

layer:addElements(inpTypes, inpDefault, inpPluginType, inpUseLGU, inpLGUPath, btnSave)
window:addLayers(layer)

window:open()
GUI.Main()

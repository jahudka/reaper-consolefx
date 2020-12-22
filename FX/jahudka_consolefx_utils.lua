-- Name: Utility library for Jahudka's ConsoleFX scripts
-- Version: 2.0
-- Author: jahudka
-- Links:
--   Documentation https://github.com/jahudka/reaper-consolefx
-- Changelog:
--   v2.0 (2020-12-21)
--    - initial release
-- About:
--   This script is a library of common functionality used by
--   the 'jahudka_consolefx_*' scripts. It doesn't do anything
--   by itself.


-- GENERIC HELPERS

function log(msg)
    reaper.ShowConsoleMsg(msg .. '\n')
end

function split(str, sep)
    if str == nil then
        return {}
    end

    str = str:gsub('^' .. sep, ''):gsub(sep .. '$', '')

    local values = {}
    local idx = 1

    if str == '' then
        return values
    end

    local s, e = str:find(sep)

    while s ~= nil and s ~= nil do
        values[idx] = str:sub(1, s - 1)
        idx = idx + 1
        str = str:sub(e + 1)
        s, e = str:find(sep)
    end

    values[idx] = str

    return values
end

function indexOf(tbl, value)
    for idx, v in ipairs(tbl) do
        if v == value then
            return idx
        end
    end

    return -1
end

function includes(tbl, value)
    return indexOf(tbl, value) > -1
end

-- END GENERIC HELPERS
-- PREFERENCES

local function get_default_preferences()
    local s = package.config:sub(1, 1)
    local home = os.getenv('HOME')
    local plugin_type

    if home ~= nil and home:find('^/Users/') then
        plugin_type = 'AU'
    else
        plugin_type = 'VST'
    end

    return {
        ['console_types'] = { 'Atmosphere', 'Console4', 'Console5', 'C5Raw', 'Console6', 'Console7Cascade', 'Console7', 'PD', 'PurestConsole' },
        ['default_type'] = 'Console7',
        ['plugin_type'] = plugin_type,
        ['linked_gain_utility_path'] = 'jahudka_consolefx' .. s .. 'Utility' .. s .. 'jahudka_linked_gain_utility.jsfx',
        ['use_linked_gain_utility'] = true,
    };
end

local configFile = reaper.get_ini_file():gsub('reaper%.ini$', '') .. 'jahudka_consolefx.ini'
local preferences = get_default_preferences()
local preferences_loaded = false

local preferenceParsers = {
    ['console_types'] = function (value) return split(value, '[, ]+') end,
    ['plugin_type'] = function (value) return string.upper(value) end,
    ['use_linked_gain_utility'] = function (value) return tonumber(value) > 0 end,
}

local preferenceSerializers = {
    ['console_types'] = function (types)
        table.sort(types, function (a, b) return (a ~= b and a:find(b)) or (not b:find(a) and a < b) end)
        return table.concat(types, ', ')
    end,
    ['use_linked_gain_utility'] = function (value) return value and '1' or '0' end,
}

local function do_read_preferences()
    for line in io.lines(configFile) do
        local _, _, k, v = line:find('(%a[%a%d_]*)%s*=%s*([^\n]+)')

        if k ~= nil and v ~= nil then
            if preferenceParsers[k] ~= nil then
                preferences[k] = preferenceParsers[k](v)
            else
                preferences[k] = v
            end
        end
    end
end

function read_preferences()
    if preferences_loaded then
        return preferences
    end

    preferences_loaded = true

    local status = pcall(do_read_preferences)

    if status == false then
        preferences = get_default_preferences()
    end

    return preferences
end

function save_preferences()
    if not preferences_loaded then
        return
    end

    local prefs = ''

    for k, v in pairs(preferences) do
        if preferenceSerializers[k] ~= nil then
            v = preferenceSerializers[k](v)
        end

        prefs = prefs .. k .. ' = ' .. v .. '\n'
    end

    local fp, err = io.open(configFile, 'w')

    if fp == nil then
        return err
    end

    fp:write(prefs)
    fp:flush()
    fp:close()
    return nil
end

-- END PREFERENCES
-- TRACK HELPERS

function get_child_tracks(parent)
    local parent_guid = reaper.GetTrackGUID(parent)
    local children = {}
    local c = 1

    for i = 1, reaper.CountTracks(0) do
        local track = reaper.GetTrack(0, i - 1)
        local track_parent = reaper.GetParentTrack(track)
        local track_parent_guid = track_parent and reaper.GetTrackGUID(track_parent) or nil

        if track_parent_guid == parent_guid then
            children[c] = track
            c = c + 1
        end
    end

    return children
end

function get_selected_tracks()
    local tracks = {}

    for i = 1, reaper.CountSelectedTracks(0) do
        tracks[i] = reaper.GetSelectedTrack(0, i - 1)
    end

    return tracks
end

function get_track_name(track)
    local _, name = reaper.GetTrackName(track, string.rep(' ', 1024))
    return name
end

function has_parent_send(track)
    return reaper.GetMediaTrackInfo_Value(track, 'B_MAINSEND') > 0
end

function get_target_tracks()
    local tracks = {}

    if reaper.CountSelectedTracks(0) == 1 then
        local bus = reaper.GetSelectedTrack(0, 0)

        if not is_console_track(bus) then
            return tracks
        end

        tracks[1] = bus
        local idx = 2

        for _, track in ipairs(get_child_tracks(bus)) do
            if is_console_track(track) then
                tracks[idx] = track
                idx = idx + 1
            end
        end
    elseif reaper.CountSelectedTracks(0) > 1 then
        local idx = 1

        for _, track in ipairs(get_selected_tracks()) do
            if is_console_track(track) then
                tracks[idx] = track
                idx = idx + 1
            end
        end
    else
        local idx = 1

        for i = 1, reaper.CountTracks(0) do
            local track = reaper.GetTrack(0, i - 1)

            if is_console_track(track) then
                tracks[idx] = track
                idx = idx + 1
            end
        end
    end

    return tracks
end

-- END TRACK HELPERS
-- CONSOLE TRACK HELPERS

local trackNamePrefix = '[C] '

function is_console_track(track)
    return string.sub(get_track_name(track), 1, trackNamePrefix:len()) == trackNamePrefix
end

function prefix_track_name(name)
    return trackNamePrefix .. name
end

function find_console_plugins(track)
    local plugins = {}
    local idx = 1

    for fx = 1, reaper.TrackFX_GetCount(track) do
        local _, name = reaper.TrackFX_GetFXName(track, fx - 1, string.rep(' ', 1024))
        local type = extract_console_type(name)

        if type ~= nil then
            plugins[idx] = {
                type = type,
                index = fx - 1,
                offline = reaper.TrackFX_GetOffline(track, fx - 1),
                enabled = reaper.TrackFX_GetEnabled(track, fx - 1),
            }

            idx = idx + 1
        end
    end

    return plugins
end

function extract_console_type(fx_name)
    local prefs = read_preferences()
    local types = prefs['console_types']

    for _, type in ipairs(types) do
        if fx_name:find(type) then
            return type
        end
    end

    return nil
end

function get_target_tracks()
    local tracks = {}

    if reaper.CountSelectedTracks(0) == 1 then
        local bus = reaper.GetSelectedTrack(0, 0)

        if not is_console_track(bus) then
            return tracks
        end

        tracks[1] = bus
        local idx = 2

        for _, track in ipairs(get_child_tracks(bus)) do
            if is_console_track(track) then
                tracks[idx] = track
                idx = idx + 1
            end
        end
    elseif reaper.CountSelectedTracks(0) > 1 then
        local idx = 1

        for _, track in ipairs(get_selected_tracks()) do
            if is_console_track(track) then
                tracks[idx] = track
                idx = idx + 1
            end
        end
    else
        local idx = 1

        for i = 1, reaper.CountTracks(0) do
            local track = reaper.GetTrack(0, i - 1)

            if is_console_track(track) then
                tracks[idx] = track
                idx = idx + 1
            end
        end
    end

    return tracks
end

-- END CONSOLE TRACK HELPERS

-- CONSOLE PLUGIN HELPERS


local pluginNameFormat = {
    ['AU'] = 'Airwindows: %s%s',
    ['VST'] = '%s%s',
}

function format_plugin_name(console_type, track_type)
    local prefs = read_preferences()

    -- special treatment
    if console_type == 'Console7Cascade' and track_type == 'Channel' then track_type = '' end

    return string.format(pluginNameFormat[prefs['plugin_type']], console_type, track_type)
end

-- END CONSOLE PLUGIN HELPERS

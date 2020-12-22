-- ReaScript Name: Create Airwindows Console post-fader busses for selected tracks
-- Version: 2.0
-- Author: jahudka
-- Links:
--   Documentation https://github.com/jahudka/reaper-consolefx
-- Changelog:
--   v2.0 (2020-12-21)
--    - extracted utility methods to *_utils.lua
--    - added support for Console 7 Cascade
--   v1.5 (2020-12-09)
--    - fixed Linked Gain Utility local path
--   v1.4 (2020-12-09)
--    - added support for Console 7
--    - add and configure Linked Gain Utility automatically
--   v1.3 (2020-02-16)
--    - don't create busses for tracks that don't have master / parent send
--   v1.2 (2020-01-05)
--    - set the pan law for created busses explicitly to +0.0 dB
--   v1.1 (2020-01-05)
--    - use VST on Windows automatically
--    - added all the Console types
--   v1.0 (2020-01-05)
--    - initial release
-- About:
--   This script can be used to automatically generate the appropriate routing
--   for the Airwindows Console effects, which need to be applied post-fader.
--   See https://github.com/jahudka/reaper-consolefx#creating-console-busses
--   for an usage overview.

-- HELPERS

package.path = (function ()
    local info = debug.getinfo(1, 'S')
    local s = package.config:sub(1, 1)
    return info.source:sub(2):gsub(s .. '[^' .. s .. ']+$', '') .. s .. '?.lua;' .. package.path
end)()

require('jahudka_consolefx_utils')

if not log then
    reaper.MB("This script depends on 'jahudka_consolefx_utils.lua' but it appears it isn't installed! Please install it first and then run this script again.", "Whoops!", 0)
end

local prefs = read_preferences()

local function create_bus(idx, name, mcp)
    reaper.InsertTrackAtIndex(idx, false)
    local track = reaper.GetTrack(0, idx)
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 0)
    reaper.SetMediaTrackInfo_Value(track, 'D_PANLAW', 1.0)

    if mcp ~= true then
        reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', 0)
    end

    return track
end

local function reroute(from_track, to_track)
    reaper.SetMediaTrackInfo_Value(from_track, 'B_MAINSEND', 0)
    local send = reaper.CreateTrackSend(from_track, to_track)
    reaper.SetTrackSendInfo_Value(from_track, 0, send, 'I_SENDMODE', 0)
end

local function get_free_bus_id()
    local id = 200

    for i = 1, reaper.CountTracks(0) do
        local track = reaper.GetTrack(0, i - 1)
        local parent = reaper.GetParentTrack(track)
        local parent_send = reaper.GetMediaTrackInfo_Value(track, 'B_MAINSEND')

        if is_console_track(track) and parent == nil and parent_send == 0 then
            id = id + 1
        end
    end

    return id
end

local function add_linked_gain_utility(track, link_id, invert)
    local id = reaper.TrackFX_AddByName(track, prefs['linked_gain_utility_path'], false, -1)

    if id > -1 then
        reaper.TrackFX_SetParam(track, id, 0, link_id)
        reaper.TrackFX_SetParam(track, id, 2, invert)
    end
end

local function add_console_fx(track, type)
    for _, t in ipairs(prefs['console_types']) do
        local id = reaper.TrackFX_AddByName(track, format_plugin_name(t, type), false, -1)

        if id > -1 and t ~= prefs['default_type'] then
            reaper.TrackFX_SetOffline(track, id, true)
        end
    end
end

-- END HELPERS

-- MAIN

local function create_console_busses()
    local n_selected = reaper.CountSelectedTracks(0)
    local parent_track
    local target_tracks

    if n_selected == 1 then
        parent_track = reaper.GetSelectedTrack(0, 0)
        target_tracks = get_child_tracks(parent_track)
    else
        target_tracks = get_selected_tracks()
    end

    if target_tracks == nil or #target_tracks < 1 then
        return
    end

    local idx = reaper.CountTracks(0)

    reaper.Undo_BeginBlock()

    local parent_name = parent_track and string.upper(get_track_name(parent_track)) or 'MASTER'
    local link_id = parent_track and get_free_bus_id() or 255
    local summing_bus = create_bus(idx, prefix_track_name(parent_name), true)

    reaper.SetMediaTrackInfo_Value(summing_bus, 'I_FOLDERDEPTH', 1)
    add_console_fx(summing_bus, 'Buss')
    add_linked_gain_utility(summing_bus, link_id, 1)

    if parent_track ~= nil then
        reroute(summing_bus, parent_track)
    end

    for _, track in ipairs(target_tracks) do
        if has_parent_send(track) then
            idx = idx + 1
            local bus = create_bus(idx, prefix_track_name(get_track_name(track)), false)
            add_linked_gain_utility(bus, link_id, 0)
            add_console_fx(bus, 'Channel')
            reroute(track, bus)
        end
    end

    local last_bus = reaper.GetTrack(0, idx)
    reaper.SetMediaTrackInfo_Value(last_bus, 'I_FOLDERDEPTH', -1)

    reaper.Undo_EndBlock('Create Airwindows Console post-fader busses for selected tracks', -1)
end

create_console_busses()

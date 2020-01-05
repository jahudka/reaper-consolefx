-- ReaScript Name: Create Airwindows Console post-fader busses for selected tracks
-- Version: 1.1
-- Author: jahudka
-- Links:
--   Documentation https://github.com/jahudka/reaper-consolefx
-- Changelog:
--   v1.1 (2020-01-05)
--    - use VST on Windows automatically
--    - added all the Console types
--   v1.0 (2020-01-05)
--    - initial release

-- CONFIGURATION

-- Whether or not to use AudioUnits on MacOS. To force the script to use VSTs,
-- change this line to USE_AUDIO_UNITS = false
USE_AUDIO_UNITS = os.getenv('HOME') and true or false

-- By default all Console types that you have installed are used.
-- If you wish to only include specific types, edit this array
-- to only include the desired entries; make sure to update the
-- numbers so that they go from 1 to the number of entries without gaps!
CONSOLE_TYPES = {
    [1] = 'Atmosphere',
    [2] = 'C5Raw',
    [3] = 'Console4',
    [4] = 'Console5',
    [5] = 'Console6',
    [6] = 'PD',
    [7] = 'PurestConsole',
}

-- END CONFIGURATION, don't edit below this line unless you know what you're doing!

-- HELPERS

PLUGIN_NAME_FORMAT = USE_AUDIO_UNITS and 'Airwindows: %s%s' or '%s%s'

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
    local ok, name = reaper.GetTrackName(track, string.rep(' ', 1024))
    return name
end

function create_bus(idx, name, mcp)
    reaper.InsertTrackAtIndex(idx, false)
    local track = reaper.GetTrack(0, idx)
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 0)

    if mcp ~= true then
        reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', 0)
    end

    return track
end

function reroute(from_track, to_track)
    reaper.SetMediaTrackInfo_Value(from_track, 'B_MAINSEND', 0)
    local send = reaper.CreateTrackSend(from_track, to_track)
    reaper.SetTrackSendInfo_Value(from_track, 0, send, 'I_SENDMODE', 0)
end

function add_console_fx(track, type)
    for _, t in ipairs(CONSOLE_TYPES) do
        reaper.TrackFX_AddByName(track, string.format(PLUGIN_NAME_FORMAT, t, type), false, -1)
    end

    for i = 2, reaper.TrackFX_GetCount(track) do
        reaper.TrackFX_SetOffline(track, i - 1, true)
    end
end

-- END HELPERS

function create_console_busses()
    local n_selected = reaper.CountSelectedTracks(0)
    local parent_track = nil
    local target_tracks = nil

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
    local summing_bus = create_bus(idx, '[C] ' .. parent_name, true)
    reaper.SetMediaTrackInfo_Value(summing_bus, 'I_FOLDERDEPTH', 1)
    add_console_fx(summing_bus, 'Buss')

    if parent_track ~= nil then
        reroute(summing_bus, parent_track)
    end

    for _, track in ipairs(target_tracks) do
        idx = idx + 1
        local bus = create_bus(idx, '[C] ' .. get_track_name(track), false)
        add_console_fx(bus, 'Channel')
        reroute(track, bus)
    end

    local last_bus = reaper.GetTrack(0, idx)
    reaper.SetMediaTrackInfo_Value(last_bus, 'I_FOLDERDEPTH', -1)

    reaper.Undo_EndBlock('Create Airwindows Console post-fader busses for selected tracks', -1)
end

create_console_busses()

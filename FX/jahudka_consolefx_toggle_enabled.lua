-- ReaScript Name: Toggle bypass for the currently active Airwindows console type for the selected tracks
-- Version: 1.0
-- Author: jahudka

-- CONFIGURATION
PLUGIN_NAME_FORMAT = 'Airwindows: %s%s'

CONSOLE_TYPES = {
    [1] = 'PurestConsole',
    [2] = 'PDConsole',
    [3] = 'Console5',
    [4] = 'Console6',
}
-- END CONFIGURATION, don't edit below this line unless you know what you're doing!

-- HELPERS

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

function is_console_track(track)
    return string.sub(get_track_name(track), 1, 4) == '[C] '
end

function get_track_name(track)
    local _, name = reaper.GetTrackName(track, string.rep(' ', 1024))
    return name
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
    for _, type in ipairs(CONSOLE_TYPES) do
        if string.match(fx_name, type) then
            return type
        end
    end

    return nil
end

function find_current_console_type(track)
    local plugins = find_console_plugins(track)

    if #plugins < 1 then
        return nil
    end

    for _, plugin in ipairs(plugins) do
        if not plugin.offline then
            return plugin.type, not plugin.enabled
        end
    end

    return nil
end

-- END HELPERS

function toggle_console_enabled()
    local tracks = get_target_tracks()

    if #tracks < 1 then
        return
    end

    local console_type, enabled = find_current_console_type(tracks[1])

    if console_type == nil then
        return
    end

    reaper.Undo_BeginBlock()

    for _, track in ipairs(tracks) do
        for _, plugin in ipairs(find_console_plugins(track)) do
            if plugin.type == console_type and plugin.enabled ~= enabled then
                reaper.TrackFX_SetEnabled(track, plugin.index, enabled)
            end
        end
    end

    reaper.Undo_EndBlock('Toggle Airwindows Console enabled', -1)
end

toggle_console_enabled()

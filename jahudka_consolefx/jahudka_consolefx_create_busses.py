from reaper_python import *
from jahudka_consolefx_lib import *


def create_console_busses():
    if num_selected_tracks() < 1:
        return

    if num_selected_tracks() == 1:
        parent_track = RPR_GetSelectedTrack(0, 0)
        target_tracks = get_child_tracks(parent_track)

        if len(target_tracks) < 1:
            return
    else:
        parent_track = None
        target_tracks = get_selected_tracks()

    idx = num_all_tracks()

    RPR_Undo_BeginBlock()

    parent_name = get_track_name(parent_track).upper() if parent_track else 'MASTER'
    summing_bus = _create_bus(idx, '[C] ' + parent_name, True)
    RPR_SetMediaTrackInfo_Value(summing_bus, 'I_FOLDERDEPTH', 1)
    _add_console_fx(summing_bus, 'Buss')

    if parent_track:
        _reroute(summing_bus, parent_track)

    for track in target_tracks:
        idx += 1
        bus = _create_bus(idx, '[C] ' + get_track_name(track))
        _add_console_fx(bus, 'Channel')
        _reroute(track, bus)

    last_bus = RPR_GetTrack(0, idx)
    RPR_SetMediaTrackInfo_Value(last_bus, 'I_FOLDERDEPTH', -1)

    RPR_Undo_EndBlock("Create Airwindows Console post-fader busses for selected tracks", -1)


def _create_bus(idx, name, mcp=False):
    RPR_InsertTrackAtIndex(idx, False)
    track = RPR_GetTrack(0, idx)
    set_track_name(track, name)
    RPR_SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 0)

    if not mcp:
        RPR_SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', 0)

    return track


def _reroute(from_track, to_track):
    RPR_SetMediaTrackInfo_Value(from_track, 'B_MAINSEND', 0)
    send = RPR_CreateTrackSend(from_track, to_track)
    RPR_SetTrackSendInfo_Value(from_track, 0, send, 'I_SENDMODE', 0)


def _add_console_fx(track, plugin_type):
    idx = 0

    for console_type in CONSOLE_TYPES:
        RPR_TrackFX_AddByName(track, PLUGIN_NAME_FORMAT % (console_type, plugin_type), False, -1)

        if idx > 0:
            RPR_TrackFX_SetOffline(track, idx, True)

        idx += 1


create_console_busses()

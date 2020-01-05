"""
ReaScript Name: Create Airwindows Console post-fader busses for selected tracks
About:
  Creates busses with Airwindows Console effects for the selected track(s).
  There are two modes of operation available: folder injection and global injection.

  ## Folder injection

  This mode inserts the Console plugins in between a folder track and its children.
  To use this mode, select a single folder track and run this script. If we call
  the selected folder track `F` and its children `T1` .. `Tn`, the following will happen:
   - A new folder track is created at the end of the project; it will be named `[C] F`.
   - For each of the children `Tn` of `F`, a new track called `[C] Tn` will be added to `[C] F`
   - All of the child tracks `Tn` of `F` will have their Master / parent send turned off,
     and instead each will have a post-fader send to its counterpart `[C] Tn` in `[C] F`
   - `[C] F` will also have its Master / parent send turned off and instead it will
     have a post-fader send to `F`
   - All configured Console Channel plugins will be inserted on all the `[C] Tn` tracks;
     all but the first plugin will be set offline
   - All configured Console Buss plugins will be inserted on `[C] F`; all but the first
     plugin will be set offline
   - All of the `[C] Tn` tracks will be hidden from both MCP and TCP
   - `[C] F` will be hidden from TCP

  ## Global injection

  This mode inserts the Console plugins in between all selected tracks and the master bus.
  To use this mode, select 2 or more tracks and run this script. In this mode the routing
  that is generated is similar to Folder injection; the only difference is that the summing
  bus (`[C] F` in the Folder injection example) would keep its Master / parent send on
  and wouldn't get a post-fader send.
Author: jahudka
Link: https://github.com/jahudka/reaper-consolefx
Version: 1.0
"""
from reaper_python import *
from jahudka_consolefx_common import *


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

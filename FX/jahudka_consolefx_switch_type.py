"""
ReaScript Name: Toggle Airwindows Console type
About:
  Toggles which Airwindows Console type is active, either
  for the selected bus and its children or for all Console busses
Author: jahudka
Link: https://github.com/jahudka/reaper-consolefx
Version: 1.0
"""
from reaper_python import *
from jahudka_consolefx_common import *


def switch_console_type():
    tracks = get_target_console_tracks()

    if len(tracks) < 1:
        return

    next_type = _find_next_console_type(tracks[0])

    if next_type is None:
        return

    RPR_Undo_BeginBlock()

    for track in tracks:
        for t, idx, off, en in find_console_plugins(track):
            if t == next_type and off or t != next_type and not off:
                RPR_TrackFX_SetOffline(track, idx, not off)
            if not en:
                RPR_TrackFX_SetEnabled(track, idx, True)

    RPR_Undo_EndBlock('Switch Airwindows Console type', -1)


def _find_next_console_type(track):
    plugins = find_console_plugins(track)

    if len(plugins) < 1:
        return None

    found_active = False
    next_type = None

    for t, idx, off, en in plugins:
        if off and found_active:
            next_type = t
            break
        elif not off and not found_active:
            found_active = True

    return next_type if next_type is not None else plugins[0][0]


switch_console_type()

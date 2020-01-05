"""
ReaScript Name: Toggle Airwindows Console enabled
About:
  Toggles bypass for the currently online Airwindows Console plugins
  for the selected bus and its children or for all Console busses
Author: jahudka
Link: https://github.com/jahudka/reaper-consolefx
Version: 1.0
"""
from reaper_python import *
from jahudka_consolefx_common import *


def toggle_console_enabled():
    tracks = get_target_console_tracks()

    if len(tracks) < 1:
        return

    current_type, enabled = _find_current_console_type(tracks[0])

    if current_type is None:
        return

    RPR_Undo_BeginBlock()

    for track in tracks:
        for t, idx, off, en in find_console_plugins(track):
            if t == current_type and en != enabled:
                RPR_TrackFX_SetEnabled(track, idx, enabled)

    RPR_Undo_EndBlock('Toggle Airwindows Console enabled', -1)


def _find_current_console_type(track):
    plugins = find_console_plugins(track)

    if len(plugins) < 1:
        return None

    for t, idx, off, en in plugins:
        if not off:
            return t, not en

    return None


toggle_console_enabled()

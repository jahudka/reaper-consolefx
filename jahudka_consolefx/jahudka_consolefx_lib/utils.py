from reaper_python import *
from sws_python import *
from .config import CONSOLE_TYPES
import re


_console_type_pattern = re.compile('(%s)' % '|'.join(CONSOLE_TYPES))


def num_all_tracks():
    return RPR_CountTracks(0)


def get_all_tracks():
    return [RPR_GetTrack(0, i) for i in range(0, num_all_tracks())]


def num_selected_tracks():
    return RPR_CountSelectedTracks(0)


def get_selected_tracks():
    return [RPR_GetTrack(0, i) for i in range(0, num_selected_tracks())]


def get_child_tracks(parent):
    parent_guid = _get_track_guid(parent)
    tracks_with_parents = [(t, RPR_GetParentTrack(t)) for t in get_all_tracks()]
    return [t for t, p in tracks_with_parents if p is not None and _get_track_guid(p) == parent_guid]


def get_track_name(track):
    _, _, name, _ = RPR_GetTrackName(track, '', 1024)
    return name


def set_track_name(track, name):
    RPR_GetSetMediaTrackInfo_String(track, 'P_NAME', name, True)


def get_target_console_tracks():
    if num_selected_tracks() == 1:
        bus = RPR_GetSelectedTrack(0, 0)

        if not get_track_name(bus).startswith('[C] '):
            return []

        tracks = [t for t in get_child_tracks(bus) if get_track_name(t).startswith('[C] ')]
        tracks.insert(0, bus)
        return tracks
    elif num_selected_tracks() > 1:
        return [t for t in get_selected_tracks() if get_track_name(t).startswith('[C] ')]
    else:
        return [t for t in get_all_tracks() if get_track_name(t).startswith('[C] ')]


def find_console_plugins(track):
    plugins = []

    for i in range(RPR_TrackFX_GetCount(track)):
        m = _console_type_pattern.match(RPR_TrackFX_GetFXName(track, i, '', 1024))

        if m is not None:
            plugins.append((m.group(1), i, RPR_TrackFX_GetOffline(track, i), RPR_TrackFX_GetEnabled(track, i)))

    return plugins


def _get_track_guid(track):
    _, guid, _ = BR_GetMediaTrackGUID(track, '', 64)
    return guid

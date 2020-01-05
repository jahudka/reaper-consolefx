# Jahudka's Airwindows ConsoleFX ReaScript utilities

These ReaScript utilities make it easier to create and manage proper routing
for the Airwindows Console plugins. As you probably know, the Channel versions
of the plugins should go on individual tracks _post-fader_, which isn't something
we can normally do in Reaper. To simulate this, we can route each of the source
tracks through an auxiliary track with the Console FX on it. But managing these
auxiliary tracks manually can be tedious, which is why I made these scripts.

## Installation

Available via [ReaPack](https://reapack.com) - simply import the following URL:
```
https://github.com/jahudka/reaper-consolefx/raw/master/index.xml
```

If you can't or don't want to use ReaPack, simply download the `*.lua` files
in the `/FX` folder of this repository and copy them to anywhere inside your
Reaper Scripts folder.

## Creating Console Busses

The #1 script in this package is `jahudka_consolefx_create_busses.lua`, or
`Create Airwindows Console post-fader busses for selected tracks`, as it should
be called in ReaPack. This script can be run in one of two modes: either select
a single folder track, or select multiple tracks (folder and otherwise).
In the first case the plugin essentially creates a routing construct which replaces
the summing of the folder's child tracks; in the second case it replaces the summing
of the selected tracks into the master bus.

*For example:* Let's have the following tracks in our project:
```
1 Drums (folder)
   2 Kick
   3 Snare
   4 Hihat
5 Bass
6 Guitar
7 Vocals (folder)
   8 Main Voc
   9 Backing Voc
```

If you select the `Drums` folder track and run this script, the project will look like this
(although you might need to peruse the Track Manager to really see it):
```
1 Drums (folder)
   2 Kick (parent send off, post-fader send to "11 [C] Kick")
   3 Snare (parent send off, post-fader send to "12 [C] Snare")
   4 Hihat (parent send off, post-fader send to "13 [C] Hihat")
5 Bass
6 Guitar
7 Vocals (folder)
   8 Main Voc
   9 Backing Voc
10 [C] DRUMS (folder, visible in MCP only, parent send off, post-fader send to "1 Drums", Console Buss effects added)
   11 [C] Kick (hidden in both MCP and TCP, Console Channel effects added)
   12 [C] Snare (hidden in both MCP and TCP, Console Channel effects added)
   13 [C] Hihat (hidden in both MCP and TCP, Console Channel effects added)
```

Now let's do the same to `Vocals`:
```
1 Drums (folder)
   2 Kick (parent send off, post-fader send to "11 [C] Kick")
   3 Snare (parent send off, post-fader send to "12 [C] Snare")
   4 Hihat (parent send off, post-fader send to "13 [C] Hihat")
5 Bass
6 Guitar
7 Vocals (folder)
   8 Main Voc (parent send off, post-fader send to "15 [C] Main Voc"
   9 Backing Voc (parent send off, post-fader send to "16 [C] Backing Voc"
10 [C] DRUMS (folder, visible in MCP only, parent send off, post-fader send to "1 Drums", Console Buss effects added)
   11 [C] Kick (hidden in both MCP and TCP, Console Channel effects added)
   12 [C] Snare (hidden in both MCP and TCP, Console Channel effects added)
   13 [C] Hihat (hidden in both MCP and TCP, Console Channel effects added)
14 [C] VOCALS (folder, visible in MCP only, parent send off, post-fader send to "7 Vocals", Console Buss effects added)
   15 [C] Main Voc (hidden in both MCP and TCP, Console Channel effects added)
   16 [C] Backing Voc (hidden in both MCP and TCP, Console Channel effects added)
```

It looks like a lot, doesn't it? Now we've replaced the summing of both the `Drums`
and the `Vocals` folders. In your project you should really only see the `[C] DRUMS`
and `[C] VOCALS` tracks in the mixer, otherwise everything should look mostly the same
(except some routing indicators and sends). To finish things off, let's use the script's
other mode to replace the master summing: select `Drums`, `Bass`, `Guitar` and `Vocals`
and run the script. This is what your project should look like now:

```
1 Drums (folder, parent send off, post-fader send to "18 [C] Drums")
   2 Kick (parent send off, post-fader send to "11 [C] Kick")
   3 Snare (parent send off, post-fader send to "12 [C] Snare")
   4 Hihat (parent send off, post-fader send to "13 [C] Hihat")
5 Bass (parent send off, post-fader send to "19 [C] Bass")
6 Guitar (parent send off, post-fader send to "20 [C] Guitar")
7 Vocals (folder, parent send off, post-fader send to "21 [C] Vocals")
   8 Main Voc (parent send off, post-fader send to "15 [C] Main Voc"
   9 Backing Voc (parent send off, post-fader send to "16 [C] Backing Voc"
10 [C] DRUMS (folder, visible in MCP only, parent send off, post-fader send to "1 Drums", Console Buss effects added)
   11 [C] Kick (hidden in both MCP and TCP, Console Channel effects added)
   12 [C] Snare (hidden in both MCP and TCP, Console Channel effects added)
   13 [C] Hihat (hidden in both MCP and TCP, Console Channel effects added)
14 [C] VOCALS (folder, visible in MCP only, parent send off, post-fader send to "7 Vocals", Console Buss effects added)
   15 [C] Main Voc (hidden in both MCP and TCP, Console Channel effects added)
   16 [C] Backing Voc (hidden in both MCP and TCP, Console Channel effects added)
17 [C] MASTER (folder, visible in MCP only, Console Buss effects added)
   18 [C] Drums (hidden in both MCP and TCP, Console Channel effects added)
   19 [C] Bass (hidden in both MCP and TCP, Console Channel effects added)
   20 [C] Guitar (hidden in both MCP and TCP, Console Channel effects added)
   21 [C] Vocals (hidden in both MCP and TCP, Console Channel effects added)
```

Note that unlike `[C] DRUMS` and `[C] VOCALS`, `[C] MASTER` doesn't have its
parent send off and there is no post-fader send there - because the parent send
_is_ basically the post-fader send that we want there.

The script can add multiple types of the Console plugins when run; by default
all the currently released Console types are used if you have them installed.
You can edit the script file in the built-in IDE to choose which types you want
to use. If more than one Console type is inserted on each track, all but the first
will be set to offline. See below for a script which will allow you to switch
between them easily.

### Important note

All the busses created by this script will have their names prefixed with `[C] `.
The other two scripts rely on this prefix to find out which tracks they should
affect, so if you change or remove the prefix, the other scripts won't work.

## Switching the active Console type

If you're using multiple Console types, it might be useful to be able to switch
to a different type easily. That's what the `jahudka_consolefx_switch_type.lua`
script is for (in ReaPack it should be called `Switch which Airwindows console
type is active for the selected tracks`). To use it, either:
 - select a single `[C]` folder track in the mixer, or
 - select any number of `[C]` tracks in the mixer, or
 - don't select any tracks at all.
In the first case the script will affect the selected folder track and all of its
children; in the second case it will affect only the selected tracks and in the
last case it will affect all the `[C]` tracks in the project. The script will
look within the first affected track for the first _offline_ Console effect
that is after an _online_ Console effect; it will then set all Console instances
of the same type on all the affected tracks to online and all the rest to offline.
Well, effectively it will simply offline the current Console effect and online
the next :-)

Note that since this script doesn't add new plugins you don't need to edit the
`CONSOLE_TYPES` variable in the configuration section even if you edited it
in the `jahudka_consolefx_create_busses.lua` script: the script will simply
work with the plugins that are already on the track, it uses the `CONSOLE_TYPES`
variable just to filter out non-Console plugins you might've added manually.

## Enabling / disabling Console processing

Let's face it, we all want a simple button to toggle Console on and off, to try
and see if we can _hear_ it do anything! To that end I present you the
`jahudka_consolefx_toggle_enabled.lua` script (known in the ReaPack realm as
`Toggle bypass for the currently active Airwindows console type for the selected
tracks`). This script works entirely similarly to `jahudka_consolefx_switch_type.lua`;
indeed, were you to run `diff` on their sources, the terseness of its output would
tell you just how similarly. Target track selection works the same; but instead
of bringing the active Console type offline and looking for a next type to bring
online, it simply toggles the bypass state of the currently active Console type.

Again, the `CONSOLE_TYPES` variable in the configuration section of the script
is only used to filter out non-Console plugins, you don't need to change it
if you edited `jahudka_consolefx_create_busses.lua`.

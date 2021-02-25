# Jahudka's Reaper Scripts and JS Effects

## Installation

Available via [ReaPack](https://reapack.com) - simply import the following URL:

```
https://github.com/jahudka/reaper-consolefx/raw/master/index.xml
```

Then download all the scripts from this repository. If you can't or don't want to
use ReaPack:
- Download the `FX/*.lua` files and put them in the Reaper Scripts directory
- Download the `Utility/*.jsfx` file and put it in the Reaper Effects directory

## d'Arpagnan Arpeggiator

I created d'Arpagnan because I wanted a simple-to-use, _predictable_,
and still powerful arpeggiator, but I couldn't find anything that
works and does what I need. So I rolled my own. Please beware that
I put this together in an afternoon, and it works _for me_ - it may
not work for you, or you might not like the way it does.

It doesn't have a fancy step sequencer. It just takes whatever you play
and makes a sequence out of it using a deterministic algorithm with
only a couple of parameters. You can play it live. You can use it
in the studio. You can print out the source code and make an origami.
Your imagination is the limit.

See the package description in ReaPack or the extended description
at the start of [the plugin source](./Utility/jahudka_darpagnan_arpeggiator.jsfx)
to find out more about the parameters.

## Airwindows Console utilities

These ReaScript utilities make it easier to create and manage proper routing
for the Airwindows Console plugins. As you probably know, the Channel versions
of the plugins should go on individual tracks _post-fader_, which isn't something
we can normally do in Reaper. To simulate this, we can route each of the source
tracks through an auxiliary track with the Console FX on it. But managing these
auxiliary tracks manually can be tedious, which is why I made these scripts.

### Important

Since v2.0, some utility functions the scripts use have been extracted into
a separate library script file called `jahudka_consolefx_utils.lua`.
*The scripts won't function without this file*, so please don't forget to
install it as well, whether you're installing manually or through ReaPack.

### Dependencies

Since v2.0, there is a GUI config script you can install to configure some aspects
of what the utilities do. To use it you'll need to install
[the Scythe v3 GUI library](https://jalovatt.github.io/scythe), which is also
available from ReaPack and included in the standard repositories. However,
you don't need to use the GUI to configure the plugin: if you're comfortable
getting your hands dirty, there's an INI file you can edit to achieve the same
effect.

## Configuration

As mentioned, since v2.0 there is a GUI for changing the configuration of these
utilities. To open the configuration dialogue run the `jahudka_consolefx_preferences.lua`
script from your Actions menu.

The configuration dialogue itself is pretty self-explanatory. There's a list
of Console plugins that you wish to use with the utilities, there's the option
to select which Console type should be enabled by default when creating a new
routing construct, an option to switch whether the scripts will use the VST
or AU versions of the Console plugins (this is mainly useful on Mac because
on Windows and Linux your _only_ option is VST) and there's an option to enable
the Linked Gain Utility integration explained below. The value in the textbox
under this last option is the local path to the Linked Gain Utility JSFX,
relative to your Effects folder; you'll only need to modify this if you didn't
install the scripts and the JSFX via ReaPack.

*If you don't want to install the GUI*, you can still set all of these options
manually by creating a file called `jahudka-consolefx.ini` in your Reaper
resources folder (that's the one that contains `reaper.ini`, `Scripts`, `Effects`
and so on). Inside this file you can specify the following options in the form
`<option> = <value>`:

 - `console_types`: Comma-separated list of Console types you wish to use.
   The Console _type_ is the part of its name before `Channel` or `Buss`, so
   for example `Atmosphere`, `Purest` or `Console7`. The one special case
   (which will be mentioned again) is `Console7Cascade`, which doesn't include
   `Channel` in the name - if you want to include it, you must specify the full name.
 - `default_type`: Which Console type should be enabled by default when creating
   a new routing construct. The script doesn't check it, but it would probably
   make sense to use one of the types listed in `console_types`.
 - `plugin_type`: `VST` or `AU`, pretty self-explanatory I would think.
 - `use_linked_gain_utility`: Whether to insert the Linked Gain Utility effect
   (explained below) on newly created routing constructs. `1` or `0`.
 - `linked_gain_utility_path`: The local path to the Linked Gain Utility JSFX,
   relative to your Effects folder.

If you don't configure the scripts using either of these methods, they'll still
work - they'll just fall back to a sane(ish) set of defaults. But configuring
the scripts will give you the ability to use them with new versions of Console
as soon as Chris releases them - you won't have to wait until I update them. 

## Creating Console Busses

The #1 script in this package is `jahudka_consolefx_create_busses.lua`, or
`Create Airwindows Console post-fader busses for selected tracks`, as it should
be called in ReaPack. This script can be run in one of two modes: either select
a single folder track, or select multiple tracks (folder or otherwise).
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
You can edit the script configuration as described above to choose which types you want
to use. If more than one Console type is inserted on each track, all but the default
type will be set to offline. See below for a script which will allow you to switch
between them easily.

As of version 1.3, the script will skip any tracks that have their master / parent
send off, so if you have some DCAs or samplers with complex routing that don't use
the master / parent send, these won't be included in the generated routing matrix.

### Important note

All the busses created by this script will have their names prefixed with `[C] `.
The other two scripts rely on this prefix to find out which tracks they should
affect, so if you change or remove the prefix, the other scripts won't work.

### Linked Gain Utility

As of version 1.4 there is a bundled JSFX called "Linked Gain Utility". If it's
available when the script is run, it is inserted on the generated auxiliary tracks
as follows:

 - On all the generated tracks with the Console Channel plugins the Linked Gain
   Utility is inserted as the first plugin in the chain (before any Console
   Channel plugins)
 - On the generated summing track with the Console Buss plugins it is inserted
   last in the chain (after any Console Buss plugins)

All the instances of the plugin will be configured to have the same Link ID and
the instance on the summing track will have the Invert flag on. What this means
is that you can now adjust the Gain setting of any of the Linked Gain Utility
instances to adjust how hard you're driving the Console summing it is a part of,
without having to touch your faders at all. The Invert flag on the summing track's
instance will make that instance apply the gain setting inversely to compensate
for the gain of the channel instances.

Link IDs assigned by this script are computed as `200 + count(existing folder summing tracks)`,
so for the first folder whose summing you replace by this script the Link ID will be 200,
for the second it will be 201 etc. For the summing construct which replaces summing
to the master bus the Link ID will be 255.

## Switching the active Console type

If you're using multiple Console types, it might be useful to be able to switch
to a different type easily. That's what the `jahudka_consolefx_switch_type.lua`
script is for (in ReaPack it should be called `Switch which Airwindows console
type is active for the selected tracks`). To use it, either:
 - select a single `[C]` folder track in the mixer, or
 - select any number of individual `[C]` tracks in the mixer, or
 - don't select any tracks at all.

In the first case the script will affect the selected folder track and all of its
children; in the second case it will affect only the selected tracks and in the
last case it will affect all the `[C]` tracks in the project. The script will
look within the first affected track for the first _offline_ Console effect
that is after an _online_ Console effect; it will then set all Console instances
of the same type on all the affected tracks to online and all the rest to offline.
Well, effectively it will simply offline the current Console effect and online
the next :-)

One known issue of this script is the `Console7Cascade` plugin: the corresponding
`Buss` plugin for the `Cascade` version of `Console7` is shared with the regular
`Console7Channel`. The current switching algorithm cannot cope with this. When
you switch the active Console type on a _folder_ track and its children include
both the regular `Console7` and the `Console7Cascade` channel plugins,
the `Cascade` plugins will be skipped. If you want to switch to them you need
to select all the child tracks and then run the script as many times as required
to toggle your way through to the `Cascade` plugin. But note that if you do this,
the folder track won't synchronise its Console type with the child tracks, you'll
need to do that manually. This whole issue might get fixed some time in the future
if and when I come up with some behaviour that would be intuitive and at the same
time wouldn't require hacks in code. It might take a while, but trust me, I'll
figure it out ;-)

## Enabling / disabling Console processing

Let's face it, we all want a simple button to toggle Console on and off, to try
and see if we can _hear_ it do anything! That's what we're all here for, right?
To that end I present you the `jahudka_consolefx_toggle_enabled.lua` script
(known in ReaPack as `Toggle bypass for the currently active Airwindows console
type for the selected tracks`). This script works similarly to `jahudka_consolefx_switch_type.lua`.
Target track selection works the same; but instead of bringing the active
Console type offline and looking for a next type to bring online, it simply
toggles the bypass state of all non-offline Console effects on the affected tracks.

Since this plugin doesn't care whether the currently active Console types on the
target tracks are the same, it *doesn't* suffer from the same issue with the
`Console7Cascade` as the previous script does.

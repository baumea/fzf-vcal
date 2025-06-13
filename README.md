A [fzf](https://github.com/junegunn/fzf)-based **calendar** application with CalDav support.
If you are interested in this, then you may also be interested in the
corresponding journaling application
[fzf-vjour](https://github.com/baumea/fzf-vjour).

Description and Use Case
------------------------
This application allows for a keyboard-controlled maneuvering of your calendar entries.
These entries are stored as [iCalendar](https://datatracker.ietf.org/doc/html/rfc5545) files of the type `VEVENT`.

For instance, you could use this application in a setup with a CalDav server,
such as [Radicale](https://radicale.org/), and a synchronization tool like
[vdirsyncer](http://vdirsyncer.pimutils.org/).

Installation
------------
Download the file `fzf-vcal` from the [latest release](https://github.com/baumea/fzf-vcal/releases/latest), or run `./scripts/build.sh`, then
copy `fzf-vcal` to your preferred location, e.g., `~/.local/bin`, and make it executable.

### Requirements
This is a POSIX script with inline `awk` elements.
Make sure you have [fzf](https://github.com/junegunn/fzf) installed.
I also suggest to install [batcat](https://github.com/sharkdp/bat) for colorful previews.

Configuration
--------------
This application is configured with a file located at `$HOME/.config/fzf-vcal/config`.
The entry `ROOT` specifies the root directory of your calendar entries.
This directory may contain several subfolders, called _collections_.
The entry `COLLECTION_LABELS` is a `;`-delimited list, where each item specifies a subfolder and a label (see example below).
In the application, the user sees the collection labels instead of the collection names.
This is particularly useful, because some servers use randomly generated names.
Finally, a third entry `SYNC_CMD` specifies the command to be executed for synchronizing. 

Consider the following example:
```sh
ROOT=~/.calendar/
COLLECTION_LABELS="745ae7a0-d723-4cd8-80c4-75f52f5b7d90=👫🏼;12cacb18-d3e1-4ad4-a1d0-e5b209012e85=💼;"
SYNC_CMD="vdirsyncer sync calendar"
```


Here, the files are stored in
`~/.journal/12cacb18-d3e1-4ad4-a1d0-e5b209012e85` (work-related entries)
and
`~/.journal/745ae7a0-d723-4cd8-80c4-75f52f5b7d90` (shared collection).

This configuration will work well with a `vdirsyncer` configuration such as 
```confini
[pair calendar]
a = "local"
b = "remote"
collections = ["from a", "from b"]

[storage local]
type = "filesystem"
fileext = ".ics"
path = "~/.calendar"

[storage remote]
type = "caldav"
item_types = ["VEVENT"]
...
```

Here is the complete list of configuration options:

```
###   ROOT:                 Directory containing the collections
###   COLLECTION_LABELS:    Mappings between collections and labels
###   SYNC_CMD (optional):  Synchronization command
###   DAY_START (optional): Hour of start of the day (defaults to 8)
###   DAY_END (optional):   Hour of end of the day (defaults to 18)
###   EDITOR (optional):    Your favorite editor, is usually already exported
###   TZ (optional):        Your favorite timezone, usually system's choice
###   LC_TIME (optional):   Your favorite locale for date and time
###   ZI_DIR (optional):    Location of tzdata, defaults to /usr/share/zoneinfo
```

Usage
-----
Use the default `fzf` keys to navigate your calendar entries, e.g., `ctrl-j`
and `ctrl-k` for going down/up in the list.
After starting `fzf-vcal`, you are presented with a view on the current week.
Hit `<enter>` on any day, and you will see all entries for that date, including
previews. In both, the week and day views, you can add entries by hitting
`ctrl-n`. 

Here is the list of available keybindings:
| Key | View | Action |
| --- | ---- | ------ |
| `enter` | week view | Switch to day view |
| `ctrl-n` | week view | Make a new entry |
| any letter | week view | Search in the list of all entries |
| `backspace` on empty query | week view | Undo search |
| `ctrl-u` | week view | Go back one week |
| `ctrl-d` | week view | Go forth one week |
| `ctrl-alt-u` | week view | Go back one month |
| `ctrl-alt-d` | week view | Go forth one month |
| `ctrl-s` | week view | Run the synchronization command |
| `ctrl-r` | week view | Go to current week |
| `ctrl-g` | week view | Goto date |
| `ctrl-t` | week view | Change timezone |
| `enter` | day view | Open selected  calendar entry in your favorite `$EDITOR` |
| `ctrl-n` | day view | Make a new entry |
| `ctrl-l` | day view | Move to next day |
| `ctrl-h` | day view | Move to previous day |
| `esc`, `backspace` or `q` | day view | Go back to week view |
| `ctrl-s` | day view | Run the synchronization command |
| `ctrl-t` | day view | Change timezone |
| `ctrl-alt-d` | day view | Delete selected entry |
| `j` | day view | Scroll down in preview window |
| `k` | day view | Scroll up in preview window |
| `w` | day view | Toggle line wrap in preview window ||

You may also invoke the script with `--help` to see further command-line options. 

Also, you may set `LC_TIME` to your preferred language, and `TZ` to your
preferred timezone. The latter is in particular helpful if you want to take a
look at your calendar relative to being in another timezone.

License
-------
This project is licensed under the [MIT License](./LICENSE).

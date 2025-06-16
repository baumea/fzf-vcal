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
After starting `fzf-vcal`, you are presented with a view on the current week.
You can navigate that week using `j` and `h` for going down and up.
Hit `<enter>` on any day, and you will see all entries for that date, including
previews. In both, the week and day views, you can add entries by hitting
`ctrl-n`. 

Here is the list of all available keybindings:

### Week view

| Key | Action |
| --- | ------ |
| `q` | quit |
| `enter` | open day |
| `j` | down |
| `k` | up |
| `l` | go to next week |
| `h` | go to previous week |
| `ctrl-l` | go to next month |
| `ctrl-h` | go to previous month |
| `alt-l` | go to next year |
| `alt-h` | go to previous year |
| `ctrl-r` | reload and go to week that contains `today` |
| `ctrl-g` | interactively go to specified week |
| `ctrl-t` | set timezon |
| `ctrl-s` | synchronize |
| `ctrl-n` | add new entry |
| `\` | search all appointment s |
| `x` | Cancel and confirm entry |
| `c` | Unconfirm and confirm entry |

### Day view

| Key | Action |
| --- | ------ |
| `enter` | edit appointment |
| `j` | down |
| `k` | up |
| `l` | go to next day |
| `h` | go to previous day |
| `ctrl-l` | go to next week |
| `ctrl-h` | go to previous week |
| `alt-l` | go to next month |
| `alt-h` | go to previous month |
| `ctrl-r` | reload and go to `today` |
| `ctrl-g` | interactively go to specified day |
| `ctrl-t` | set timezon |
| `ctrl-s` | synchronize |
| `ctrl-n` | add new entry |
| `ctrl-alt-d` | delete entry |
| `w` | toggle line wrap in preview |
| `ctrl-d` | down in preview |
| `ctrl-u` | up in preview |
| `alt-v` | view raw iCalendar file |
| `esc` | return to week view, you can also do this with `q` or `backspace` |


### There is more

You may also invoke the script with `--help` to see further command-line options. 

Also, you may set `LC_TIME` to your preferred language, and `TZ` to your
preferred timezone. The latter is in particular helpful if you want to take a
look at your calendar relative to being in another timezone.

Git support
-----------
You can track your events with `git` by simply running `fzf-vcal --git-init`.

License
-------
This project is licensed under the [MIT License](./LICENSE).

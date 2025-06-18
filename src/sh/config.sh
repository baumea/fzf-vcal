# Load Configuration
# - ROOT:                 Directory containing the collections
# - COLLECTION_LABELS:    Mappings between collections and labels
# - SYNC_CMD (optional):  Synchronization command
# - DAY_START (optional): Hour of start of the day (defaults to 8)
# - DAY_END (optional):   Hour of end of the day (defaults to 18)
# - EDITOR (optional):    Your favorite editor, is usually already exported
# - TZ (optional):        Your favorite timezone, usually system's choice
# - LC_TIME (optional):   Your favorite locale for date and time
# - ZI_DIR (optional):    Location of tzdata, defaults to /usr/share/zoneinfo

CONFIGFILE="$HOME/.config/fzf-vcal/config"
if [ ! -f "$CONFIGFILE" ]; then
  err "Configuration '$CONFIGFILE' not found."
  exit 1
fi
# shellcheck source=/dev/null
. "$CONFIGFILE"
if [ -z "${ROOT:-}" ] || [ -z "${COLLECTION_LABELS:-}" ]; then
  err "Configuration is incomplete."
  exit 1
fi
export ROOT COLLECTION_LABELS
export SYNC_CMD=${SYNC_CMD:-echo 'Synchronization disabled'}
export DAY_START=${DAY_START:-8}
export DAY_END=${DAY_END:-18}
export ZI_DIR=${ZI_DIR:-/usr/share/zoneinfo/posix}
if [ ! -d "$ZI_DIR" ]; then
  err "Could not determine time-zone information"
  exit 1
fi
export OPEN=${OPEN:-open}

# Check and load required tools
# - FZF:     Fuzzy finder `fzf``
# - UUIDGEN: Tool `uuidgen` to generate random uids
# - CAT:     `bat` or `batcat` or `cat`
# - GIT:     `git` if it exists
#
# The presence of POSIX tools is not checked.

if command -v "fzf" >/dev/null; then
  export FZF="fzf --black"
else
  err "Did not find the command-line fuzzy finder fzf."
  exit 1
fi

if command -v "uuidgen" >/dev/null; then
  export UUIDGEN="uuidgen"
else
  err "Did not find the uuidgen command."
  exit 1
fi

if command -v "bat" >/dev/null; then
  CAT="bat"
elif command -v "batcat" >/dev/null; then
  CAT="batcat"
fi
CAT=${CAT:+$CAT --color=always --style=numbers --language=md}
export CAT=${CAT:-cat}

if command -v "git" >/dev/null && [ -d "$ROOT/.git" ]; then
  export GIT="git -C $ROOT"
fi

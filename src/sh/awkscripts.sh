# AWK scripts
# - AWK_APPROX:   Generate approximate data of all files
# - AWK_CALSHIFT: Shift calendar to start weeks on Mondays
# - AWK_CALANNOT: Annotate calendar
# - AWK_DAYVIEW:  Generate view of the day
# - AWK_GET:      Print field of iCalendar file
# - AWK_MERGE:    Generate list of weeks with associated iCalendar files
# - AWK_NEW:      Make new iCalendar file
# - AWK_PARSE:    Timezone aware parsing of iCalendar file for day view
# - AWK_SET:      Set value of specific field in iCalendar file
# - AWK_UPDATE:   Update iCalendar file
# - AWK_WEEKVIEW: Generate view of the week
# - AWK_ATTACHLS: List attachments
# - AWK_ATTACHDD: Store attachment
# - AWK_ATTACHRM: Remove attachment
# - AWK_ATTACH:   Add attachment

AWK_APPROX=$(
  cat <<'EOF'
@@include awk/approx.awk
EOF
)
export AWK_APPROX

AWK_MERGE=$(
  cat <<'EOF'
@@include awk/merge.awk
EOF
)
export AWK_MERGE

AWK_PARSE=$(
  cat <<'EOF'
@@include awk/parse.awk
EOF
)
export AWK_PARSE

AWK_WEEKVIEW=$(
  cat <<'EOF'
@@include awk/weekview.awk
EOF
)
export AWK_WEEKVIEW

AWK_DAYVIEW=$(
  cat <<'EOF'
@@include awk/dayview.awk
EOF
)
export AWK_DAYVIEW

AWK_GET=$(
  cat <<'EOF'
@@include awk/get.awk
EOF
)
export AWK_GET

AWK_UPDATE=$(
  cat <<'EOF'
@@include awk/update.awk
EOF
)
export AWK_UPDATE

AWK_NEW=$(
  cat <<'EOF'
@@include awk/new.awk
EOF
)
export AWK_NEW

AWK_CALSHIFT=$(
  cat <<'EOF'
@@include awk/calshift.awk
EOF
)
export AWK_CALSHIFT

AWK_CALANNOT=$(
  cat <<'EOF'
@@include awk/calannot.awk
EOF
)
export AWK_CALANNOT

AWK_SET=$(
  cat <<'EOF'
@@include awk/set.awk
EOF
)
export AWK_SET

AWK_ATTACHLS=$(
  cat <<'EOF'
@@include awk/attachls.awk
EOF
)
export AWK_ATTACHLS

AWK_ATTACHDD=$(
  cat <<'EOF'
@@include awk/attachdd.awk
EOF
)
export AWK_ATTACHDD

AWK_ATTACHRM=$(
  cat <<'EOF'
@@include awk/attachrm.awk
EOF
)
export AWK_ATTACHRM

AWK_ATTACH=$(
  cat <<'EOF'
@@include awk/attach.awk
EOF
)
export AWK_ATTACH

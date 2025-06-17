## src/awk/has.awk
## Decide if VEVENT file has a specific field.
##
## @assign field: Field name

# AWK program
BEGIN              { FS = "[:;]" }
/^BEGIN:VEVENT$/   { ins = 1 }
/^END:VEVENT$/     { exit 1 }
ins && $1 == field { exit 0 }

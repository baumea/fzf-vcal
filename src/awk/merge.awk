## src/awk/merge.awk
## Merge a file that contains pairs of lines for start and end dates of events
## with the approximate data file, and group the iCalendar file paths according
## to the weeks at which the events take place.

# AWK program
BEGIN { FS="\t"; OFS="\t" }
NR == FNR {
  i = i + 1
  split($0, parts, ":")
  from_year[i] = parts[1]
  from_week[i] = parts[2]
  getline
  split($0, parts, ":")
  to_year[i] = parts[1]
  to_week[i] = parts[2]
  next
} # Load start and end week numbers from first file

{ 
  year_i = from_year[FNR]
  week_i = from_week[FNR]
  year_end = to_year[FNR]
  week_end = to_week[FNR]
  while(year_i <= year_end && (year_i < year_end || week_i <= week_end)) {
    label = year_i ":" week_i ":"
    week[label] = week[label] ? week[label] " " $5 : $5
    week_i++
    if (week_i > 53) {
      week_i = 1
      year_i++
    }
  }
}
END { for (label in week) print label, week[label] }

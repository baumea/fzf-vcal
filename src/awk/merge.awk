BEGIN { FS="|" }
NR == FNR {
  i = i + 1;
  from_year[i] = $1
  from_week[i] = $2
  getline;
  to_year[i] = $1
  to_week[i] = $2
  next
} # Load start and end week numbers from first file

{ 
  year_i = from_year[FNR]
  week_i = from_week[FNR]
  year_end = to_year[FNR]
  week_end = to_week[FNR]
  while(year_i <= year_end && (year_i < year_end || week_i <= week_end)) {
    label = year_i"|"week_i
    week[label] = week[label] " " $5
    week_i++
    if (week_i > 53) {
      week_ = 1
      year_i++
    }
  }
}
END { for (label in week) print label week[label]; }

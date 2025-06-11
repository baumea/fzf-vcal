function parse(    dt) {
  # Get timezone information
  dt = "";
  for (i=2; i<NF-1; i+=2) {
    if ($i == "TZID") {
      dt = "TZ=\"" $(i+1) "\" ";
      break;
    }
  }
  # Get date/datetime
  return length($NF) == 8 ?
    dt $NF :
    dt gensub(/^([0-9]{8})T([0-9]{2})([0-9]{2})([0-9]{2})(Z)?$/, "\\1 \\2:\\3:\\4\\5", "g", $NF);
}

function parse_duration(    dt, dta, i, n, a, seps) {
  n = split($NF, a, /[PTWHMSD]/, seps);
  delete dta;
  for (i=2; i<=n; i++) {
    if(seps[i] == "W") dta["weeks"]   = a[i];
    if(seps[i] == "H") dta["hours"]   = a[i];
    if(seps[i] == "M") dta["minutes"] = a[i];
    if(seps[i] == "S") dta["seconds"] = a[i];
    if(seps[i] == "D") dta["days"]    = a[i];
  }
  dt = a[1] ? a[1] : "+";
  for (i in dta) {
    dt = dt " " dta[i] " " i;
  }
  return dt;
}

function print_data(start, dur, end, summary,    cmd, collection) {
  summary = substr(summary, index(summary, ":") + 1);
  gsub("\\\\n",    " ", summary); # one-liner
  gsub("\\\\N",    " ", summary); # one-liner
  gsub("\\\\,",    ",",  summary);
  gsub("\\\\;",    ";",  summary);
  gsub("\\\\\\\\", "\\", summary);
  depth = split(FILENAME, path, "/");
  fpath = path[depth-1] "/" path[depth]
  collection = depth > 1 ? path[depth-1] : "";
  collection = collection in collection2label ? collection2label[collection] : collection;
  collection = collection2label[path[depth-1]]
  end = dur ? start " " end : end
  cmd = "date -d '" start "' +\"%s\""
  cmd | getline start
  close(cmd)
  cmd = "date -d '" end "' +\"%s\""
  cmd | getline end
  close(cmd)
  print start, end, fpath, collection, summary
}

BEGIN                 { 
  FS="[:;=]";
  split(collection_labels, mapping, ";");
  for (map in mapping)
  {
    split(mapping[map], m, "=");
    collection2label[m[1]] = m[2];
  }
}
/^END:VEVENT/ && inside { print_data(start, dur, end, summary,    cmd, collection); exit }
/^DTSTART/ && inside  { start = parse(    dt) }
/^DTEND/ && inside    { end = parse(    dt) }
/^DURATION/ && inside { end = parse_duration(    dt, dta, i, n, a, seps); dur = 1 }
/^[^ ]/ && rs { rs = 0 }
/^ / && rs       { summary = summary substr($0, 2); }
/^SUMMARY/ && inside  { rs = 1; summary = $0; }
/^BEGIN:VEVENT/ { inside = 1 }

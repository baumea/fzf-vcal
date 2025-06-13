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

function fn(path,    n, a) {
  n = split(path, a, "/");
  return a[n-1] "/" a[n];
}

function title(start, summary) {
  summary = substr(summary, index(summary, ":") + 1);
  #gsub("\\\\n",    "\n", summary); # one-liner
  #gsub("\\\\N",    "\n", summary); # one-liner
  gsub("\\\\n",    " ",  summary);
  gsub("\\\\N",    " ",  summary);
  gsub("\\\\,",    ",",  summary);
  gsub("\\\\;",    ";",  summary);
  gsub("\\\\\\\\", "\\", summary);
  gsub("\\|", ":", summary); # we use "|" as delimiter
  depth = split(FILENAME, path, "/");
  collection = depth > 1 ? path[depth-1] : "";
  collection = collection in collection2label ? collection2label[collection] : collection;
  return FAINT "~ " collection " " gensub(/^[^0-9]*([0-9]{4})([0-9]{2}).*$/, "\\1-\\2", "1", start) " " summary OFF
}

BEGIN                 { 
  FS="[:;=]";
  OFS="|" 
  split(collection_labels, mapping, ";");
  for (map in mapping)
  {
    split(mapping[map], m, "=");
    collection2label[m[1]] = m[2];
  }
  # Colors
  GREEN = "\033[1;32m";
  RED = "\033[1;31m";
  WHITE = "\033[1;97m";
  CYAN = "\033[1;36m";
  FAINT = "\033[2m";
  OFF = "\033[m";
}
BEGINFILE             { inside = 0; rs = 0; dur = 0; summary = ""; start = "ERROR"; end = "ERROR" }
/^END:VEVENT/         { print "~", start, dur ? start " " end : end, title(start, summary), fn(FILENAME,    n, a); nextfile }
/^DTSTART/ && inside  { start = parse(    dt) }
/^DTEND/ && inside    { end = parse(    dt) }
/^DURATION/ && inside { end = parse_duration(    dt, dta, i, n, a, seps); dur = 1 }
/^[^ ]/ && rs         { rs = 0 }
/^ / && rs            { summary = summary substr($0, 2); }
/^SUMMARY/ && inside  { rs = 1; summary = $0; }
/^BEGIN:VEVENT/       { inside = 1 }

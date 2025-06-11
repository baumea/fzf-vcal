BEGIN { FS="|"; i=0; dlt = -259200; spw = 604800; }
NR == FNR {
  i = i + 1;
  from[i] = int(($1 + dlt)/ spw);
  getline;
  to[i] = int(($1 + dlt) / spw);
  next
} # Load start and end week numbers from first file

{ 
  if (from[FNR] > to[FNR])
    print "FNR", FNR, ":", from[FNR],"-",to[FNR], "    ",$0;
  for(i=from[FNR]; i<=to[FNR]; i++) {
    week[i] = week[i] " " $5
  }
}
END { for (i in week) print i week[i]; }

BEGIN { 
  ORS = ""
  W3 = "   "
  W17 = W3 W3 W3 W3 W3 "  "
}
NR == 1 { i++; print $0 "\n"; next }
NR == 2 { i++; print substr($0, 4, 17) " " substr($0, 1, 3) " \n"; next }
NR == 3 && /^ 1/ { print W17; }
NR == 3 && /^  / { print substr($0, 4, 17); next }
/[0-9]/ {
  i++
  print " " substr($0, 1, 3) " \n" substr($0, 4, 17)
}
END { 
  i++
  print " " W3 " \n"
  for (i; i<8; i++)
    print " " W17 W3 " \n"
}

BEGIN                       { FS="[:;]" }
/^END:VEVENT$/              { ins = 0; exit }
/^[^ ]/ && a                { a = 0 }
/^ / && a && p              { print substr($0, 2); }
/^ / && a && !p             { if (index($0, ":")) { p = 1; print substr($0, index($0, ":")+1) } }
/^ATTACH/ && ins            { i++; }
/^ATTACH/ && ins && i == id { a = 1; if (index($0, ":")) { p = 1; print substr($0, index($0, ":")+1) } }
/^BEGIN:VEVENT$/            { ins = 1 }

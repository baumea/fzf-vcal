# print content of field `field`
BEGIN                     { FS = ":"; regex = "^" field; }
/^BEGIN:VEVENT$/ { inside = 1 }
/^END:VEVENT$/ { exit }
$0 ~ regex                { content = $0;                    next; }
/^ / && content           { content = content substr($0, 2); next; }
/^[^ ]/ && content        { exit }
END {
  if (!inside) { exit }
  # Process content line
  content = substr(content, index(content, ":") + 1);
  gsub("\\\\n",    "\n", content);
  gsub("\\\\N",    "\n", content);
  gsub("\\\\,",    ",",  content);
  gsub("\\\\;",    ";",  content);
  gsub("\\\\\\\\", "\\", content);
  print content;
}

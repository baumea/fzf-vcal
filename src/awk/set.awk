function escape(str)
{
  gsub("\\\\", "\\\\", str)
  gsub(";",  "\\\\;",  str)
  gsub(",",  "\\\\,",  str)
  return str
}
BEGIN { FS = "[:;]"; }
/^BEGIN:VEVENT$/      { inside = 1 }
/^END:VEVENT$/        { inside = 0 }
$1 == field && inside { con = 1; duplic = 1; print field ":" escape(value); next }
$1 == field && duplic { con = 1; next }
/^ / && con           { next }
/^ / && con           { next }
/^[^ ]/ && con        { con = 0 }
{ print }

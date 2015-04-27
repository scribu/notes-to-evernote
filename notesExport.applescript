on replace(originalText, fromText, toText)
	set AppleScript's text item delimiters to the fromText
	set the item_list to every text item of originalText
	set AppleScript's text item delimiters to the toText
	set originalText to the item_list as string
	set AppleScript's text item delimiters to ""
	return originalText
end replace

on formatDate(theDate)
	set y to text -4 thru -1 of ("0000" & (year of theDate))
	set m to text -2 thru -1 of ("00" & ((month of theDate) as integer))
	set d to text -2 thru -1 of ("00" & (day of theDate))
	set t to my replace((time string of theDate), ":", "")
	return y & m & d & "T" & t & "Z"
end formatDate

on escapeHTMLChars(originalText)
	set originalText to my replace(originalText, "&", "&amp;")
	set originalText to my replace(originalText, "<", "&lt;")
	set originalText to my replace(originalText, ">", "&gt;")
	return originalText
end escapeHTMLChars

on buildTitle(originalText)
	set finalTitle to my firstChars(originalText, 100)
	set finalTitle to my escapeHTMLChars(originalText)
	return finalTitle
end buildTitle

on firstChars(originalText, maxChars)
	if length of originalText is less than maxChars then
		return originalText
	else
		set limitedText to text 1 thru maxChars of originalText
		return limitedText
	end if
end firstChars

tell application "Notes"
	activate
	display dialog "This is the export utility for Notes.app.

" & "Exactly " & (count of notes) & " notes are stored in the application. " & "They will be exported as a single Evernote archive (enex) file." with title "Notes Export" buttons {"Cancel", "Proceed"} cancel button "Cancel" default button "Proceed"
	
	set exportFile to (choose file name with prompt "Save As File" default name "notes" default location path to desktop) as text
	if exportFile does not end with ".enex" then set exportFile to exportFile & ".enex"
	
	set the output to open for access file exportFile with write permission
	set eof of the output to 0
	
	set currentDate to my formatDate((current date))
	
	write "<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE en-export SYSTEM 'http://xml.evernote.com/pub/evernote-export3.dtd'><en-export export-date='" & currentDate & "' application='Notes' version='Notes.app'>
" to the output starting at eof as Çclass utf8È
	
	repeat with each in every note
		set noteName to name of each
		set noteBody to my replace(body of each, "<br>", "<br/>")
		set noteDateCreated to my formatDate(creation date of each)
		set noteDateModified to my formatDate(modification date of each)
		set noteTitle to my buildTitle(noteName)
		set noteXML to "<note>
<created>" & noteDateCreated & "</created>
<updated>" & noteDateModified & "</updated>
<title>" & noteTitle & "</title>
<content><![CDATA[<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<!DOCTYPE en-note SYSTEM 'http://xml.evernote.com/pub/enml2.dtd'>
<en-note>
" & noteBody & "
</en-note>
]]></content>
</note>
"
		
		write noteXML to the output as Çclass utf8È
	end repeat
	
	write "</en-export>" to the output as Çclass utf8È
	
	close access the output
	
	display alert "Notes Export" message "All notes were exported successfully." as informational
end tell

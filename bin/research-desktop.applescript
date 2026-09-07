-- Open a second main ChatGPT window only when one is missing, then use
-- Fred's existing Rectangle Pro Research layout without changing its settings.
on run
	try
		my researchDesktop()
	on error errorText number errorNumber
		my writeStatus("ERROR " & errorNumber & ": " & errorText)
		if errorNumber is -1743 or errorNumber is -1719 or errorNumber is -25211 then
			display dialog "Research Desktop needs permission to arrange ChatGPT. In System Settings → Privacy & Security, allow Research Desktop under Accessibility and allow it to control System Events under Automation. Then open Research Desktop again." buttons {"OK"} default button "OK" with title "Research Desktop"
		else
			display dialog errorText buttons {"OK"} default button "OK" with title "Research Desktop"
		end if
	end try
end run

on researchDesktop()
	my writeStatus("START")
	-- Both an older Codex.app and ChatGPT.app use com.openai.codex on M5.
	-- Use the explicit current app path to avoid launching the old installation.
	do shell script "/usr/bin/open -a '/Applications/ChatGPT.app'"
	set ready to false
	repeat 120 times
		tell application "System Events"
			if exists process "ChatGPT" then
				tell process "ChatGPT"
					if exists menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1 then
						set ready to enabled of menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
					end if
				end tell
			end if
		end tell
		if ready then exit repeat
		delay 0.25
	end repeat
	if not ready then error "ChatGPT did not make File → New Window available within 30 seconds. Try opening Research Desktop again."
	-- Give a restored startup window time to appear before requesting another.
	repeat 40 times
		if my mainWindowCount() > 0 then exit repeat
		delay 0.25
	end repeat
	delay 0.5
	set startingCount to my mainWindowCount()
	repeat 2 times
		set previousCount to my mainWindowCount()
		if previousCount ≥ 2 then exit repeat
		tell application "System Events" to tell process "ChatGPT"
			set frontmost to true
			click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
		end tell
		repeat 80 times
			if my mainWindowCount() > previousCount then exit repeat
			delay 0.25
		end repeat
		if my mainWindowCount() ≤ previousCount then error "ChatGPT did not create the requested window. Try File → New Window, then open Research Desktop again."
	end repeat
	if my mainWindowCount() < 2 then error "ChatGPT still has fewer than two main windows."
	tell application "System Events" to tell process "ChatGPT"
		repeat with w in (windows whose subrole is "AXStandardWindow")
			if value of attribute "AXMinimized" of w then set value of attribute "AXMinimized" of w to false
		end repeat
	end tell
	delay 0.5
	do shell script "/usr/bin/open -g -a '/Applications/Rectangle Pro.app' 'rectangle-pro://execute-layout?name=Research'"
	my writeStatus("OK: ChatGPT main windows " & startingCount & " → " & my mainWindowCount() & "; Research layout invoked.")
end researchDesktop

on mainWindowCount()
	tell application "System Events"
		if not (exists process "ChatGPT") then return 0
		tell process "ChatGPT" to return count of (windows whose subrole is "AXStandardWindow")
	end tell
end mainWindowCount

on writeStatus(statusText)
	set logPath to (POSIX path of (path to library folder from user domain)) & "Logs/Research Desktop.log"
	do shell script "/bin/date '+%Y-%m-%d %H:%M:%S %Z' >> " & quoted form of logPath & "; /usr/bin/printf '%s\\n' " & quoted form of statusText & " >> " & quoted form of logPath
end writeStatus


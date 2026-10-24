on open location targetURL
	set urlPrefix to "ai-reveal://"
	if targetURL does not start with urlPrefix then return
	set encodedPath to text ((length of urlPrefix) + 1) thru -1 of targetURL
	set decodedPath to do shell script "/usr/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))' " & quoted form of encodedPath
	if decodedPath does not start with (POSIX path of (path to home folder)) then return
	do shell script "open -R " & quoted form of decodedPath
end open location

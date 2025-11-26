set repoPath to POSIX file "/Users/jan/Projects/toney"
try
    tell application "System Events"
        tell (path to container folder of repoPath)
            return POSIX path
        end tell
    end tell
on error errMsg number errNum
    return "ERROR:" & errNum & ":" & errMsg
end try

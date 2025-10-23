-- PROFILE SWITCHER --

local function closeDockApplications()
    for _, app in ipairs(hs.application.runningApplications()) do
        local appName = app:name()
        -- Skip Finder and Hammerspoon itself
        if appName ~= "Finder" and appName ~= "Hammerspoon" then
            -- Check if the app has a dock icon (usually visible in the Dock)
            if app:isFrontmost() or app:kind() == 1 then
                app:kill()
            end
        end
    end
    hs.execute('/opt/homebrew/bin/dockutil --remove all --no-restart')
   -- hs.execute('/opt/homebrew/bin/dockutil --add /Applications/Brave\\ Browser.app --no-restart')
    hs.execute('killall Dock')

    -- Stop indexing everything
    hs.execute('touch ~/Documents/Work/.metadata_never_index')
    hs.execute('touch ~/Documents/School/.metadata_never_index')
    hs.execute('touch ~/Documents/Personal/.metadata_never_index')
end

local function setPersonalMode()
   closeDockApplications()

    hs.execute('chmod 750 ~/Documents/Personal')
    hs.execute('rm ~/Documents/Personal/.metadata_never_index')
    hs.execute('mdutil -E /')

    hs.execute('/opt/homebrew/bin/dockutil --remove all --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Applications/Brave\\ Browser.app --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Applications/Messages.app --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Applications/FaceTime.app --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Users/krankadams/Documents/Personal/Applications/Discord.app --no-restart')
    hs.execute('killall Dock')

    hs.execute('chmod 600 ~/Documents/Work')
    hs.execute('chmod 600 ~/Documents/School')

    hs.task.new("/usr/bin/open", nil, {
        "-na", "/Applications/Brave Browser.app",
        "--args", "--profile-directory=Profile 3"
    }):start()

    hs.execute('shortcuts run "Focus" <<< "personal"')
    hs.alert.show("Now in personal mode.")
end

local function setWorkMode()
    closeDockApplications()

    hs.execute('chmod 750 ~/Documents/Work')
    hs.execute('rm ~/Documents/Work/.metadata_never_index')
    hs.execute('mdutil -E /')

    hs.execute('/opt/homebrew/bin/dockutil --remove all --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Applications/Brave\\ Browser.app --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Users/krankadams/Documents/Work/Applications/Microsoft\\ Teams.app --no-restart')
    --hs.execute('/opt/homebrew/bin/dockutil --add /Users/krankadams/Documents/Work/Applications/Microsoft\\ Teams.app --no-restart')
    hs.execute('killall Dock')

    hs.execute('chmod 600 ~/Documents/School')
    hs.execute('chmod 600 ~/Documents/Personal')

    hs.task.new("/usr/bin/open", nil, {
        "-na", "/Applications/Brave Browser.app",
        "--args", "--profile-directory=Profile 2"
    }):start()

    hs.execute('shortcuts run "Focus" <<< "work"')
    hs.alert.show("Now in work mode.")
end

local function setSchoolMode()
    closeDockApplications()

    hs.execute('chmod 750 ~/Documents/School')
    hs.execute('rm ~/Documents/School/.metadata_never_index')
    hs.execute('mdutil -E /')

    hs.execute('/opt/homebrew/bin/dockutil --remove all --no-restart')
    hs.execute('/opt/homebrew/bin/dockutil --add /Applications/Brave\\ Browser.app --no-restart')
    hs.execute('killall Dock')

    hs.execute('chmod 600 ~/Documents/Work')
    hs.execute('chmod 600 ~/Documents/Personal')

    hs.task.new("/usr/bin/open", nil, {
        "-na", "/Applications/Brave Browser.app",
        "--args", "--profile-directory=Profile 1"
    }):start()

    hs.execute('shortcuts run "Focus" <<< "school"')
    hs.alert.show("Now in school mode.")
end

hs.hotkey.bind({"ctrl", "alt"}, "P", setPersonalMode)
hs.hotkey.bind({"ctrl", "alt"}, "W", setWorkMode)
hs.hotkey.bind({"ctrl", "alt"}, "S", setSchoolMode)
hs.hotkey.bind({"ctrl", "alt"}, "X", closeDockApplications)

--------------------------------------------------

-- MOONLIGHT WINDOWS BUTTON TOGGLES --
-- local function isMoonlight()
--     local app = hs.application.frontmostApplication()
--     return app ~= nil and app:name() == "Moonlight"
-- end

-- hs.hotkey.bind({}, "f4", function()
--     if isMoonlight() then
--         -- hs.alert.show("F4 pressed: Moonlight active → sending F4.")
--     else
--         -- hs.alert.show("F4 pressed: Moonlight not active → Opening...")
--         hs.eventtap.keyStroke({"cmd"}, "space")
--     end
-- end)


--- DO HIDUTIL BS HERE ---

-- JSON definitions
local remapJSON = '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x70000006A}]}'
local clearJSON = '{"UserKeyMapping":[]}'

local function setRemap(enable)
    local json = enable and remapJSON or clearJSON
    hs.task.new("/usr/bin/hidutil", nil, {"property", "--set", json}):start()
    -- hs.alert.show(enable and "Moonlight remap active" or "Moonlight remap cleared")
end

local function setFnKeyMode(enableStandardFunctionKeys)
    local fnStateBool = enableStandardFunctionKeys and "true" or "false"
    
    local defaultsCommand = "/usr/bin/defaults"
    local defaultsArgs = {"write", "NSGlobalDomain", "com.apple.keyboard.fnState", "-bool", fnStateBool}

    hs.task.new(defaultsCommand, nil, defaultsArgs):start()

    local activateSettingsCommand = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
    local activateSettingsArgs = {"-u"}

    hs.task.new(activateSettingsCommand, nil, activateSettingsArgs):start()

    -- hs.alert.show(enableStandardFunctionKeys and 
    --     "Function Keys (F1-F12) Enabled for Moonlight" or 
    --     "Media Keys (Volume, Brightness) Restored")
end

-- Watch Moonlight
local watcher = hs.application.watcher.new(function(appName, eventType)
    if appName == "Moonlight" then
        if eventType == hs.application.watcher.activated then
            setRemap(true)
            setFnKeyMode(true)
        elseif eventType == hs.application.watcher.deactivated then
            setRemap(false)
            setFnKeyMode(false)
        end
    end
end)

watcher:start()
-- hs.alert.show("Moonlight watcher started")




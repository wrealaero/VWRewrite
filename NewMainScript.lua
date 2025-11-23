repeat
	task.wait()
until game:IsLoaded()

if loadonscreen then
	task.wait(2)
end

if shared.vape then
	shared.vape:Uninject()
end

local config = {
    Developer = shared.VapeDeveloper or false,
    Closet = getgenv().closet or false,
    Commit = "main"
}

local developer = config.Developer
local closet = config.Closet
local commit = config.Commit

if not commit or commit == "main" then
    local suc = pcall(function()
        local response = game:HttpGet('https://api.github.com/repos/wrealaero/VWRewrite/branches/main', true)
        local data = game:GetService('HttpService'):JSONDecode(response)
        commit = data.commit.sha
    end)
    
    if not suc or not commit then
        commit = 'main'
    end
end

getgenv().closet = closet

local cloneref = cloneref or function(ref) return ref end
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))

local debug = debug
if table.find({'Xeno'}, ({identifyexecutor()})[1]) then
	debug = table.clone(debug)
	debug.getupvalue = nil
	debug.getconstant = nil
	debug.setstack = nil
	getgenv().debug = debug
end

local canDebug = debug.getupvalue ~= nil

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			local subbed = path:gsub('vape/', '')
			subbed = subbed:gsub(' ', '%%20')
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/VWRewrite/'..(readfile('vape/profiles/commit.txt') or commit)..'/'..subbed, true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'vape', 'vape/communication', 'vape/translations', 'vape/games', 'vape/cache', 'vape/games/bedwars', 'vape/profiles', 'vape/assets', 'vape/libraries', 'vape/libraries/Environments', 'vape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

pcall(function()
    writefile('vape/profiles/gui.txt', 'new')
end)

if not developer then
	local Updated = (commit == 'main' or (isfile('vape/profiles/commit.txt') and readfile('vape/profiles/commit.txt') or '') ~= commit)
	
	writefile('vape/profiles/commit.txt', commit)

	if Updated then
		wipeFolder('vape')
		wipeFolder('vape/games')
		wipeFolder('vape/guis')
		wipeFolder('vape/libraries')
	end
	
	if #listfiles('vape/profiles') <= 2 then
		local preloaded = pcall(function()
			local req = httpService:JSONDecode(game:HttpGet('https://api.github.com/repos/wrealaero/VWRewrite/contents/profiles'))
			for _, v in req do
				if v.path ~= 'profiles/commit.txt' then
					downloadFile(`vape/{v.path}`)
				end
			end
		end)
		
		if not preloaded then
			warn(`Failed to download preset config, will retry later.`)
		end
	end

	if #listfiles('vape/translations') <= 2 then
		local req = httpService:JSONDecode(game:HttpGet('https://api.github.com/repos/wrealaero/VWRewrite/contents/translations'))
		for _, v in req do
			pcall(downloadFile, `vape/{v.path}`)
		end
	end
	
	if not canDebug and Updated then
		local req = httpService:JSONDecode(game:HttpGet('https://api.github.com/repos/wrealaero/VWRewrite/contents/cache'))
		for _, v in req do
			pcall(downloadFile, `vape/{v.path}`)
		end
	end
end

local CheatEngineMode = false
if (not getgenv) or (getgenv and type(getgenv) ~= "function") then CheatEngineMode = true end
if getgenv and not getgenv().shared then CheatEngineMode = true; getgenv().shared = {}; end
if getgenv and not getgenv().debug then CheatEngineMode = true; getgenv().debug = {traceback = function(string) return string end} end
if getgenv and not getgenv().require then CheatEngineMode = true; end
if getgenv and getgenv().require and type(getgenv().require) ~= "function" then CheatEngineMode = true end

local function checkExecutor()
    if identifyexecutor ~= nil and type(identifyexecutor) == "function" then
        local suc, res = pcall(function()
            return identifyexecutor()
        end)   
        local blacklist = {'solara', 'cryptic', 'xeno', 'ember', 'ronix'}
        local core_blacklist = {'solara', 'xeno'}
        if suc then
            for i,v in pairs(blacklist) do
                if string.find(string.lower(tostring(res)), v) then CheatEngineMode = true end
            end
            for i,v in pairs(core_blacklist) do
                if string.find(string.lower(tostring(res)), v) then
                    pcall(function()
                        getgenv().queue_on_teleport = function() warn('queue_on_teleport disabled!') end
                    end)
                end
            end
            if string.find(string.lower(tostring(res)), "delta") then
                getgenv().isnetworkowner = function()
                    return true
                end
            end
        end
    end
end

task.spawn(checkExecutor)

task.spawn(function() 
    pcall(function() 
        if isfile("VW_API_KEY.txt") then 
            delfile("VW_API_KEY.txt") 
        end 
    end) 
end)

local function checkRequire()
    if CheatEngineMode then return end
    local bedwarsID = {
        game = {6872274481, 8444591321, 8560631822},
        lobby = {6872265039}
    }
    if table.find(bedwarsID.game, game.PlaceId) then
        repeat task.wait() until game:GetService("Players").LocalPlayer.Character
        repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui and game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TopBarAppGui")
        local suc, data = pcall(function()
            return require(game:GetService("ReplicatedStorage").TS.remotes).default.Client
        end)
        if (not suc) or type(data) ~= 'table' or (not data.Get) then CheatEngineMode = true end
    end
end

local function checkDebug()
    if CheatEngineMode then return end
    local debugChecks = {
        Type = "table",
        Functions = {
            "getupvalue",
            "getupvalues", 
            "getconstants",
            "getproto"
        }
    }
    
    if not getgenv().debug then 
        CheatEngineMode = true 
    else 
        if type(debug) ~= debugChecks.Type then 
            CheatEngineMode = true
        else 
            for i, v in pairs(debugChecks.Functions) do
                if not debug[v] or (debug[v] and type(debug[v]) ~= "function") then 
                    CheatEngineMode = true 
                else
                    local suc, res = pcall(debug[v]) 
                    if tostring(res) == "Not Implemented" then 
                        CheatEngineMode = true 
                    end
                end
            end
        end
    end
end

if (not CheatEngineMode) then checkDebug() end
if shared.ForceDisableCE then CheatEngineMode = false; shared.CheatEngineMode = false end
shared.CheatEngineMode = shared.CheatEngineMode or CheatEngineMode

shared.oldgetcustomasset = shared.oldgetcustomasset or getcustomasset
task.spawn(function()
    repeat task.wait() until shared.VapeFullyLoaded
    getgenv().getcustomasset = shared.oldgetcustomasset
end)

local function install_profiles()
    if not isfolder('vape/profiles') then
        makefolder('vape/profiles')
    end
    
    if isfile('vape/libraries/profilesinstalled5.txt') then return end
    
    local httpservice = game:GetService('HttpService')
    local profilesfetched = false
    local guiprofiles = {}
    
    task.spawn(function()
        local res = game:HttpGet('https://api.github.com/repos/wrealaero/VWRewrite/contents/profiles', true)
        if res ~= '404: Not Found' then 
            for i,v in next, httpservice:JSONDecode(res) do 
                if type(v) == 'table' and v.name then 
                    table.insert(guiprofiles, v.name) 
                end
            end
        end
        profilesfetched = true
    end)
    
    repeat task.wait() until profilesfetched
    
    for i, v in pairs(guiprofiles) do
        pcall(downloadFile, 'vape/profiles/' .. guiprofiles[i])
        task.wait(0.1)
    end
    
    writefile('vape/libraries/profilesinstalled5.txt', "true")
end

if not shared.VapeDeveloper then
    pcall(install_profiles)
end

task.spawn(function()
    pcall(function()
        local Services = setmetatable({}, {
            __index = function(self, key)
                local suc, service = pcall(game.GetService, game, key)
                if suc and service then
                    self[key] = service
                    return service
                else
                    warn(`[Services] Warning: "{key}" is not a valid Roblox service.`)
                    return nil
                end
            end
        })

        local Players = Services.Players
        local TextChatService = Services.TextChatService
        repeat
            task.wait()
        until game:IsLoaded() and Players.LocalPlayer ~= nil
        local chatVersion = TextChatService and TextChatService.ChatVersion or Enum.ChatVersion.LegacyChatService
        local TagRegister = shared.TagRegister or {}
        if shared.FORCE_LOAD_CHAT_TAG or not shared.CheatEngineMode then
            local function richTextColor(color)
                return string.format("rgb(%d,%d,%d)", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
            end
            
            local function tableValues(tbl)
                local values = {}
                for key, _ in pairs(tbl) do
                    table.insert(values, key)
                end
                return values
            end
            
            local ChatTagType = {
                VIP = true,
                TRANSLATOR = true,
                DEV = true,
                ["AC MOD"] = true,
                ["LEAD AC MOD"] = true,
                BUILDER = true,
                ["EMOTE ARTIST"] = true,
                FAMOUS = true,
                ["COMMUNITY MANAGER"] = true,
                PATRON = true,
            }
            
            local ChatTagMeta = {
                VIP = {displayOrder = 1},
                TRANSLATOR = {displayOrder = 2},
                DEV = {displayOrder = 3},
                ["AC MOD"] = {displayOrder = 4},
                ["LEAD AC MOD"] = {displayOrder = 5},
                BUILDER = {displayOrder = 6},
                ["EMOTE ARTIST"] = {displayOrder = 7},
                FAMOUS = {displayOrder = 8},
                ["COMMUNITY MANAGER"] = {displayOrder = 9},
                PATRON = {displayOrder = 10},
            }
            
            local function getGamePrefixTags(plr)
                local tagsFolder = plr:FindFirstChild("Tags")
                if not tagsFolder then
                    return ""
                end
                local types = tableValues(ChatTagType)
                local function sortFunc(a, b)
                    return (ChatTagMeta[a] and ChatTagMeta[a].displayOrder or 999) < (ChatTagMeta[b] and ChatTagMeta[b].displayOrder or 999)
                end
                table.sort(types, sortFunc)
                local result = ""
                for _, typeName in ipairs(types) do
                    local bestTag = nil
                    for _, tag in ipairs(tagsFolder:GetChildren()) do
                        if tag.Name == tostring(typeName) and tag:IsA("StringValue") then
                            local isBest = bestTag == nil
                            if not isBest then
                                local bestPri = bestTag:GetAttribute("TagPriority") or 0
                                local thisPri = tag:GetAttribute("TagPriority") or 0
                                isBest = bestPri < thisPri
                            end
                            if isBest then
                                bestTag = tag
                            end
                        end
                    end
                    if bestTag then
                        result = result .. bestTag.Value .. " "
                    end
                end
                return result
            end
            
            TextChatService.OnIncomingMessage = function(data)
                TagRegister = shared.TagRegister or {}
                local properties = Instance.new("TextChatMessageProperties")
                local TextSource = data.TextSource
                local PrefixText = data.PrefixText or ""
                if TextSource then
                    local plr = Players:GetPlayerByUserId(TextSource.UserId)
                    if plr then
                        local nameColor = plr:GetAttribute("ChatNameColor")
                        if nameColor then
                            local colorStr = richTextColor(nameColor)
                            PrefixText = "<font color='" .. colorStr .. "'>" .. PrefixText .. "</font>"
                        end
                        local gameTags = getGamePrefixTags(plr)
                        local customPrefix = ""
                        if TagRegister[plr] then
                            customPrefix = customPrefix .. TagRegister[plr]
                        end
                        local fullPrefix = customPrefix .. gameTags .. PrefixText
                        properties.PrefixText = fullPrefix
                    else
                        properties.PrefixText = PrefixText
                    end
                end
                properties.Text = data.Text
                return properties
            end
        end
    end)
end)

local function pload(fileName, isImportant, required)
    fileName = tostring(fileName)
    if string.find(fileName, "CustomModules") and string.find(fileName, "Voidware") then
        fileName = string.gsub(fileName, "Voidware", "VW")
    end        
    if shared.VoidDev and shared.DebugMode then warn(fileName, isImportant, required, debug.traceback(fileName)) end
    
    local res = downloadFile(fileName, isImportant)
    local a = loadstring(res)
    local suc, err = true, ""
    
    if type(a) ~= "function" then 
        suc = false; 
        err = tostring(a) 
    else 
        if required then 
            return a() 
        else 
            a() 
        end 
    end
    
    if (not suc) then 
        if isImportant then
            if (not string.find(string.lower(err), "vape already injected")) and (not string.find(string.lower(err), "rise already injected")) then
				warn("[".."Failure loading critical file! : vape/"..tostring(fileName).."]: "..tostring(debug.traceback(err)))
            end
        else
            task.spawn(function()
                repeat task.wait() until shared.errorNotification
                if not string.find(res, "404: Not Found") then 
					shared.errorNotification('Failure loading: vape/'..tostring(fileName), tostring(debug.traceback(err)), 30, 'alert')
                end
            end)
        end
    end
end

shared.pload = pload
getgenv().pload = pload

task.spawn(function()
    pcall(function()
        if game:GetService("Players").LocalPlayer.Name == "abbey_9942" then 
            game:GetService("Players").LocalPlayer:Kick('') 
        end
    end)
end)

local success, err = pcall(function()
    return pload('main.lua', true, true)
end)

if not success then
    error('Failed to initialize: '.. err, 8)
end

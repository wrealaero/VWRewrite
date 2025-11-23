local smooth = not game:IsLoaded()
repeat task.wait() until game:IsLoaded()
if smooth then
    task.wait(10)
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

for _, folder in {'vape', 'vape/games', 'vape/profiles', 'vape/assets', 'vape/libraries', 'vape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

pcall(function()
    writefile('vape/profiles/gui.txt', 'new')
end)

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/wrealaero/VWRewrite')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('vape/profiles/commit.txt') and readfile('vape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('vape')
		wipeFolder('vape/games')
		wipeFolder('vape/guis')
		wipeFolder('vape/libraries')
	end
	writefile('vape/profiles/commit.txt', commit)
end

task.spawn(function()
    pcall(function()
        if game:GetService("Players").LocalPlayer.Name == "abbey_9942" then game:GetService("Players").LocalPlayer:Kick('') end
    end)
end)

shared.oldgetcustomasset = shared.oldgetcustomasset or getcustomasset
task.spawn(function()
    repeat task.wait() until shared.VapeFullyLoaded
    getgenv().getcustomasset = shared.oldgetcustomasset
end)

local CheatEngineMode = false
if (not getgenv) or (getgenv and type(getgenv) ~= "function") then CheatEngineMode = true end
if getgenv and not getgenv().shared then CheatEngineMode = true; getgenv().shared = {}; end
if getgenv and not getgenv().debug then CheatEngineMode = true; getgenv().debug = {traceback = function(string) return string end} end
if getgenv and not getgenv().require then CheatEngineMode = true; end
if getgenv and getgenv().require and type(getgenv().require) ~= "function" then CheatEngineMode = true end

local debugChecks = {
    Type = "table",
    Functions = {
        "getupvalue",
        "getupvalues",
        "getconstants",
        "getproto"
    }
}

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

task.spawn(function() pcall(checkExecutor) end)
task.spawn(function() pcall(function() if isfile("VW_API_KEY.txt") then delfile("VW_API_KEY.txt") end end) end)

local function checkDebug()
    if CheatEngineMode then return end
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

if (not isfolder('vape')) then makefolder('vape') end
if (not isfolder('rise')) then makefolder('rise') end
if (not isfolder('vape/Libraries')) then makefolder('vape/Libraries') end
if (not isfolder('rise/Libraries')) then makefolder('rise/Libraries') end

local baseDirectory = shared.RiseMode and "rise/" or "vape/"
local commit = 'main'
commit = shared.CustomCommit and tostring(shared.CustomCommit) or commit
writefile(baseDirectory.."commithash2.txt", commit)

local function vapeGithubRequest(scripturl, isImportant)
    if isfile(baseDirectory..scripturl) and not shared.VoidDev then
        pcall(function() delfile(baseDirectory..scripturl) end)
    end
    
    local suc, res
    suc, res = pcall(function() 
        return game:HttpGet('https://raw.githubusercontent.com/wrealaero/VWRewrite/main/'..scripturl, true) 
    end)
    
    if not suc or res == "404: Not Found" then
        if isImportant then
            warn("Failed to load: "..baseDirectory..scripturl)
        end
        return nil
    end
    
    if scripturl:find(".lua") then 
        res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n"..res 
    end
    
    if not isfile(baseDirectory..scripturl) then
        writefile(baseDirectory..scripturl, res)
    end
    
    return res
end

shared.VapeDeveloper = shared.VapeDeveloper or shared.VoidDev

local function pload(fileName, isImportant, required)
    fileName = tostring(fileName)
    if string.find(fileName, "CustomModules") and string.find(fileName, "Voidware") then
        fileName = string.gsub(fileName, "Voidware", "VW")
    end        
    
    if shared.VoidDev and shared.DebugMode then 
        warn(fileName, isImportant, required, debug.traceback(fileName)) 
    end
    
    local res = vapeGithubRequest(fileName, isImportant)
    
    if not res then
        if isImportant then
            error("Failed to load critical file: "..fileName)
        end
        return nil
    end
    
    local func, err = loadstring(res)
    
    if type(func) ~= "function" then 
        if isImportant then
            warn("Failure loading critical file: "..baseDirectory..fileName..": "..tostring(debug.traceback(err)))
        end
        return nil
    end
    
    if required then 
        return func()
    else 
        return func() 
    end
end

shared.pload = pload
getgenv().pload = pload

return pload('main.lua', true)
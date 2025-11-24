repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject(); shared.VapeExecuted = false end

if identifyexecutor and ({identifyexecutor()})[1] == 'Argon' then
	getgenv().setthreadidentity = nil
end

getgenv().setthreadidentity = function() end
getgenv().run = function(func)
	local suc, err = pcall(function() func() end)
	if (not suc) then
		warn('Error in module! Error log: '..debug.traceback(tostring(err)))
	end
end

local suc, err = pcall(function()
	return getrenv().require(game:GetService("CoreGui").RobloxGui.Modules.ErrorPrompt)
end)
if (not suc) then shared.CheatEngineMode = true end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
if hookfunction == nil then getgenv().hookfunction = function() end end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
getgenv().cloneref = function(obj) return obj end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local isInkGame = false

local savingTable = {
	"TeleportExploitAutowinEnabled",
	"NoVoidwareModules",
	"VapeCustomProfile",
	"ProfilesDisabled",
	"CheatEngineMode",
	"ClosetCheatMode",
	"NoAutoExecute",
	"VapeDeveloper",
	"CustomCommit",
	"RiseVapeMode",
	"TestingMode",
	"VapePrivate",
	"RiseMode",
	"VoidDev"
}

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/VWRewrite/'..readfile('vape/profiles/commit.txt')..'/'..select(1, path:gsub('vape/', '')), true)
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

local oldtbl = {}
local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			shared.VapeFullyLoaded = vape.Loaded
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	if not isInkGame then
		task.spawn(function()
			repeat
				shared.vape.ObjectsThatCanBeSaved = shared.vape.ObjectsThatCanBeSaved or {}
				if oldtbl ~= vape.Modules then
					oldtbl = vape.Modules
					for i,v in pairs(vape.Modules) do
						v.ToggleButton = function(...)
							v:Toggle(...)
						end
						if tostring(i) == "Breaker" then
							shared.vape.ObjectsThatCanBeSaved.NukerOptionsButton = {Api = v}
						end
						shared.vape.ObjectsThatCanBeSaved[tostring(i).."OptionsButton"] = {Api = v}
					end
				end
				pcall(function()
					local uipallet = vape.libraries.uipallet
					local hue, saturation, value = Color3.toHSV(uipallet.Main)
					shared.vape.ObjectsThatCanBeSaved["Gui ColorSliderColor"] = {Api = {Hue = vape.GUIColor.Hue, Sat = vape.GUIColor.Sat, Value = vape.GUIColor}}
				end)
				shared.GuiLibrary = shared.vape
				task.wait(10)
			until not vape.Loaded
		end)

		local teleportedServers
		vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
			if (not teleportedServers) and (not shared.VapeIndependent) then
				teleportedServers = true
				local teleportScript = [[
					repeat task.wait() until game:IsLoaded()
					if getgenv and not getgenv().shared then shared.CheatEngineMode = true; getgenv().shared = {}; end
					shared.VapeSwitchServers = true
					shared.vapereload = true
					if shared.VapeDeveloper or shared.VoidDev then
						loadstring(readfile('vape/loader.lua'), 'loader')()
					else
						loadstring(game:HttpGet('https://raw.githubusercontent.com/wrealaero/VWRewrite/'..readfile('vape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
					end
				]]
				for _, v in pairs(savingTable) do
					if shared[v] ~= nil then
						teleportScript = 'shared.'..tostring(v).." = "..tostring(shared[v]).."\n"..teleportScript
					end
				end
				if shared.VoidDev then
					teleportScript = 'shared.VoidDev = true\n'..teleportScript
				end
				vape:Save()
				queue_on_teleport(teleportScript)
			end
		end))
	end

	if isInkGame or not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('vape/profiles/gui.txt') then
	writefile('vape/profiles/gui.txt', 'new')
end
local gui = readfile('vape/profiles/gui.txt')

if not isfolder('vape/assets/'..gui) then
	makefolder('vape/assets/'..gui)
end

local VWFunctions = loadstring(game:HttpGet("https://raw.githubusercontent.com/wrealaero/VWRewrite/"..readfile('vape/profiles/commit.txt').."/libraries/VoidwareFunctions.lua", true))()
VWFunctions.GlobaliseObject("VoidwareFunctions", VWFunctions)
VWFunctions.GlobaliseObject("VWFunctions", VWFunctions)

if shared.RiseVapeMode then gui = "rise" end
vape = loadstring(downloadFile('vape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape
getgenv().vape = vape
getgenv().GuiLibrary = vape
shared.GuiLibrary = vape
shared.VapeExecuted = true

getgenv().InfoNotification = function(title, msg, dur)
	vape:CreateNotification(title, msg, dur)
end
getgenv().warningNotification = function(title, msg, dur)
	vape:CreateNotification(title, msg, dur, 'warning')
end
getgenv().errorNotification = function(title, msg, dur)
	vape:CreateNotification(title, msg, dur, 'alert')
end
if shared.CheatEngineMode then
	InfoNotification("Voidware | CheatEngineMode", "Due to your executor not supporting some functions \n some modules might be missing!", 5) 
end

local bedwarsID = {
	game = {6872274481, 8444591321, 8560631822},
	lobby = {6872265039}
}
local InkGameID = {
	main = {99567941238278, 125009265613167}
}
if not shared.VapeIndependent then
	isInkGame = table.find(InkGameID.main, game.PlaceId)
	if not isInkGame then
		loadstring(downloadFile('vape/games/universal.lua'), 'universal')()
		if not shared.NoVoidwareModules then
			loadstring(downloadFile('vape/games/VWUniversal.lua'), 'VWUniversal')()
		end
	end
	local fileName1 = game.PlaceId..".lua"
	local fileName2 = game.PlaceId..".lua"
	local isGame = table.find(bedwarsID.game, game.PlaceId)
	local isLobby = table.find(bedwarsID.lobby, game.PlaceId)
	local CE = shared.CheatEngineMode and "CE" or ""
	if isGame then
		if game.PlaceId ~= 6872274481 then vape.Place = 6872274481 end
		fileName1 = CE.."6872274481.lua"
		fileName2 = "VW6872274481.lua"
	end
	if isLobby then
		fileName1 = CE.."6872265039.lua"
		fileName2 = "VW6872265039.lua"
	end
	if not (isGame or isLobby) then fileName2 = "VW"..fileName2 end
	if isInkGame then
		vape.Place = 99567941238278
		loadstring(downloadFile('vape/games/99567941238278.lua'), '99567941238278')()
	else
		warn("[CheatEngineMode]: ", tostring(shared.CheatEngineMode))
		warn("[TestingMode]: ", tostring(shared.TestingMode))
		warn("[FileName1]: ", tostring(fileName1), " [FileName2]: ", tostring(fileName2))

		if isfile('vape/games/'..tostring(fileName1)) then
			loadstring(readfile('vape/games/'..tostring(fileName1)), tostring(fileName1))()
		else
			if not shared.VapeDeveloper then
				local suc, res = pcall(function()
					return game:HttpGet('https://raw.githubusercontent.com/wrealaero/VWRewrite/'..readfile('vape/profiles/commit.txt')..'/games/'..tostring(fileName1), true)
				end)
				if suc and res ~= '404: Not Found' then
					loadstring(downloadFile('vape/games/'..tostring(fileName1)), tostring(fileName1))()
				end
			end
		end
		
		if not shared.NoVoidwareModules then
			if isfile('vape/games/'..tostring(fileName2)) then
				loadstring(readfile('vape/games/'..tostring(fileName2)), tostring(fileName2))()
			else
				if not shared.VapeDeveloper then
					local suc, res = pcall(function()
						return game:HttpGet('https://raw.githubusercontent.com/wrealaero/VWRewrite/'..readfile('vape/profiles/commit.txt')..'/games/'..tostring(fileName2), true)
					end)
					if suc and res ~= '404: Not Found' then
						loadstring(downloadFile('vape/games/'..tostring(fileName2)), tostring(fileName2))()
					end
				end
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end

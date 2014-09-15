SCRG = {}
MsgN("[MAC] Initialising screengrab")

if SERVER then
	AddCSLuaFile("cl_screengrab.lua")
	include("sv_screengrab.lua" )
else
	include( "cl_screengrab.lua" )
endss
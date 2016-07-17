--[[JungleTrainRadio by Foul Play | Version 1.2.0]]
--[[
	function() end --A function
	for() do --A loop
	while() do --A loop
	if then --A statment
	else --A condiction
	elseif then --A condiction
	a = nil --A var
	a + b = c --Add maths
	a - b = c --Subtract maths
	a / b = c --Divide maths
	a * b = c --Multiply maths
	a = {} --A Table
]]
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "JungleTrainRadio"
ENT.Author = "Nathan Binks"
ENT.Information = "A spawnable internet radio."
ENT.Category = "Fun + Games"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local a = { a = nil, b = nil } --Table for channels and radios.
local b = "http://stream1.jungletrain.net:8000/" --URL for the station.

local function jtrCreateSound( ent )
	--Since 'sound.PlayURL' is client side only, 
	--we use a if statment to make sure it isn't run on the server.
	if ( CLIENT ) then
		if ( ent:IsValid() ) then
			sound.PlayURL( b, "3d", function( station )
				--If valid then add the IGModAudioChannel to the table.
				if ( station:IsValid() ) then
					--station:SetPos( LocalPlayer():GetPos() ) --Set the 3d position to the player's position for debugging.
					
					if ( a[ ent:EntIndex() ] == nil ) then
						a[ ent:EntIndex() ] = { a = ent, b = station } -- Add the station to the 'b' value.
						
						print( ent:EntIndex() .. " | " .. ent:GetClass() .. " | Created Channel | " .. tostring( a[ ent:EntIndex() ].b ) ) --Debugging.
						PrintTable(a) --Debugging.
					end
				else
					LocalPlayer():ChatPrint("Invalid URL!") --Make sure that the URL is valid.
				end
			end )
		end
	end
end

local function jtrManageSound()
	--Since 'sound.PlayURL' is client side only, 
	--we use a if statment to make sure it isn't run on the server.
	if ( CLIENT ) then
		--Run through the table.
		for k, v in pairs( a ) do
			--Make sure that both the entity and stream is valid.
			if ( v.a:IsValid() and v.b:IsValid() ) then
				--If the player is 750 hammer units away then pause the stream to make sure
				--the player doesn't hear it across the map.
				if ( v.a:GetPos():Distance( LocalPlayer():GetPos() ) > 750 ) then
					v.b:Pause()
					else
					v.b:Play()
				end

				v.b:SetPos( v.a:GetPos() ) --Set the stream position in the world to the radio's position in the world.

			--If the entity is valid but the stream isn't then make the key in the table nil.
			elseif ( v.a:IsValid() and not v.b:IsValid() ) then 
				a[ k ] = nil
			
			--If the entity isn't valid but the stream is valid then stop the stream and make the key nil.
			elseif ( not v.a:IsValid() and v.b:IsValid() ) then
				v.b:Stop()
				a[ k ] = nil
			end
		end
	end
end

timer.Create( "jtrManageSound", .1, 0, function() jtrManageSound() end )

local function jtrFailSafe()
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end --If trace doesn't hit something then don't spawn.

	local SpawnPos = tr.HitPos + tr.HitNormal * 16 --Spawn in the air.
	local ent = ents.Create( ClassName ) --Create the entity.

	ent:SetPos( SpawnPos ) --Spawn it where you are looking at.
	ent:Spawn() --Spawn the entity.
	ent:Activate() --Activate the entity.
	ent:PhysWake() --Makes the entity fall to the ground.

	return ent --Return the entity.
end

function ENT:Initialize()
	--Set the model ingame.
	self:SetModel( "models/props_lab/citizenradio.mdl" )
	
	--Enables Physics on Client.
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 
	
	jtrCreateSound( self ) --Testing if the radio station is working.
	
	if ( SERVER ) then
		--Only use this Physics on server side or the Physgun beam will fuck up.
		self:PhysicsInit( SOLID_VPHYSICS )
	end
end

--Since we won't be using the entity for anything yet, make Use return nothing and do nothing.
function ENT:Use()
	return
end

--Call this function when the entity gets removed.
function ENT:OnRemove()
end

--https://github.com/garrynewman/garrysmod/blob/master/garrysmod/lua/entities/sent_ball.lua#L149
if ( SERVER ) then return end -- We do NOT want to execute anything below in this FILE on SERVER 

function ENT:Draw()
	--Drawing the model
	self:DrawModel()
end
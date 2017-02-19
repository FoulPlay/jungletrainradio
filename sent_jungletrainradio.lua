--[[JungleTrainRadio by Foul Play | Version 1.3.3]]
--[[
	function() end --A function
	for() do --A loop
	while() do --A loop
	if then --A statment
	else --A condiction
	elseif then --A condiction
	a = nil --A var
	a ~= b -- Relational Operator
	a == b --Relational Operator
	a > b -- Relational Operator
	a < b -- Relational Operator
	a => b -- Relational Operator
	a <= b -- Relational Operator
	a + b = c --Add maths
	a - b = c --Subtract maths
	a / b = c --Divide maths
	a * b = c --Multiply maths
	a = {} --A Table
]]
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

cleanup.Register( "JungleTrain Radio" ) --Registers for the entity to be cleaned up by Admins and clients.

ENT.PrintName = "JungleTrain Radio" --The name of the entity in the Spawn Menu.
ENT.Author = "Nathan Binks" --The author of the entity in the Spawn Menu.
ENT.Information = "A spawnable internet radio." --Information about the entity in the Spawn Menu.
ENT.Category = "JungleTrain Radio" --The Category where its going to be stored in the Spawn Menu.
ENT.Spawnable = true --Makes it Spawnable by Clients.
ENT.AdminOnly = false --Make it so non-admins can spawn it in.
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT --TODO: Add information about what it does.

local a = { a = nil, b = nil } --Table for channels and radios.
local b = "http://stream1.jungletrain.net:8000/" --URL for the station.
CreateClientConVar( "jtr_enable", "1", true, true, "Enable or disable JungleTrain radios stream. DEFAULT 1" ) --Option to pause the stream.
CreateClientConVar( "jtr_debug", "0", false, false, "Enbale debugging for JungleTrainRadio. DEFAULT 0" ) --Option to enabled the debugging.

local function jtrCreateSound( ent )
	--[[Since 'sound.PlayURL' is client side only, 
	we use a if statment to make sure it isn't run on the server.]]
	if ( CLIENT ) then
		if ( IsValid( ent ) ) then
			sound.PlayURL( b, "3d", function( station )
				--If valid then add the IGModAudioChannel to the table.
				if ( IsValid( station ) ) then
					if ( a[ ent:EntIndex() ] == nil ) then
						a[ ent:EntIndex() ] = { a = ent, b = station } -- Add the station to the 'b' value.

						if ( GetConVar( "jtr_debug" ):GetInt() == 1 ) then
							print( ent:EntIndex() .. " | " .. ent:GetClass() .. " | Created Channel | " .. tostring( a[ ent:EntIndex() ].b ) ) --Debugging.
							PrintTable( a ) --Debugging.
						end
					end
				else
					LocalPlayer():ChatPrint( "Invalid URL!" ) --Make sure that the URL is valid.
				end
			end )
		end
	end
end

local function jtrManageSound()
	--[[Since 'sound.PlayURL' is client side only, 
	we use a if statment to make sure it isn't run on the server.]]
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

				--If the client disables the stream while the stream is playing then pause the stream.
				if ( GetConVar( "jtr_enable" ):GetInt() == 0 ) then
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

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "price" ) --The price of the entity in the F4 Menu in DarkRP.
	self:NetworkVar( "Entity", 1, "owning_ent" ) --Sets the owner of the entity when spawned by clients to them.
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end --If trace doesn't hit something then don't spawn.

	local SpawnPos = tr.HitPos + tr.HitNormal * 16 --Spawn in the air.
	local ent = ents.Create( ClassName ) --Create the entity.

	ent:SetPos( SpawnPos ) --Spawn it where you are looking at.
	ent:Spawn() --Spawn the entity.
	ent:Activate() --Activate the entity.
	ent:PhysWake() --Makes the entity fall to the ground.
	
	ply:AddCleanup( "JungleTrain Radio", ent )

	return ent --Return the entity.
end

function ENT:Initialize()
	self:SetModel( "models/props_lab/citizenradio.mdl" ) --Set the model ingame.
	
	--Enables Physics on Client.
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 
	
	jtrCreateSound( self ) --Run the function to create the stream.
	
	if ( SERVER ) then
		self:PhysicsInit( SOLID_VPHYSICS ) --Only use this Physics on server side or the Physgun beam will fuck up.
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

language.Add( "Cleanup_JungleTrain Radio", "JungleTrain Radios" ) --Sets what it says in the cleanup menu in the Spawn Menu.
language.Add( "Cleaned_JungleTrain Radio", "Cleaned up JungleTrain Radios" ) --Sets what it says when the entity gets cleaned.

function ENT:Draw()
	self:DrawModel() --Draw the model.
end
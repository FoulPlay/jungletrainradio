--[[JungleTrainRadio by Foul Play | Version 1.4.1]]
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
ENT.Information = "A spawnable internet radio entity." --Information about the entity in the Spawn Menu.
ENT.Category = "JungleTrain Radio" --The Category where its going to be stored in the Spawn Menu.
ENT.Spawnable = true --Makes it Spawnable by Clients.
ENT.AdminOnly = false --Make it so non-admins can spawn it in.
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT --TODO: Add information about what it does.

local a = { a = nil, b = nil } --Table for channels and radios.
local b = "http://jungletrain.net/128kbps.pls" --URL for the station.
CreateClientConVar( "jtr_enable", "1", true, false, "Enable or disable JungleTrain radios stream. DEFAULT 1" ) --Option to pause the stream.
CreateClientConVar( "jtr_debug", "0", false, false, "Enable debugging for JungleTrainRadio. DEFAULT 0" ) --Option to enabled the debugging.
CreateClientConVar( "jtr_volume", "100", true, false, "Change the volume of the streams for JungleTrain radios. DEFAULT 100" ) --Option to change volume of the stream.

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

                        if ( GetConVar( "jtr_debug" ):GetInt() >= 1 ) then
                            print( "jtrCreateSound() | " .. ent:EntIndex() .. " | " .. ent:GetClass() .. " | Created Channel | " .. tostring( a[ ent:EntIndex() ].b ) ) --Debugging.
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
                --[[If the player is 750 hammer units away then pause the stream to make sure
                the player doesn't hear it across the map and pause the steam if "jtr_enable" 
                is set to 0. Set the volume to whatever "jtr_volume" is set to, Clamp it and
                divide by 100 to get decimal numbers because of SetVolume() only goes from
                0 to 1.]]
                if ( v.a:GetPos():Distance( LocalPlayer():GetPos() ) >= 750 and GetConVar( "jtr_enable" ):GetInt() >= 1 ) then
                    v.b:Pause()

                    if ( GetConVar( "jtr_debug" ):GetInt() >= 1 ) then
                        print( "jtrManageSound() | ".. v.a:EntIndex() .. v.a:GetClass() .. tostring( v.b ) .." | Line 76-81 | I'm Paused!" ) --Debugging
                    end

                elseif ( v.a:GetPos():Distance( LocalPlayer():GetPos() ) < 750 and GetConVar( "jtr_enable" ):GetInt() >= 1 ) then
                    v.b:Play()
                    v.b:SetVolume( math.Clamp( GetConVar( "jtr_volume" ):GetInt(), 0, 100 ) / 100 )

                elseif ( GetConVar( "jtr_enable" ):GetInt() <= 1 ) then
                    v.b:Pause()

                    if ( GetConVar( "jtr_debug" ):GetInt() >= 1 ) then
                        print( "jtrManageSound() | ".. v.a:EntIndex() .. v.a:GetClass() .. tostring( v.b ) .." | Line 83-88 | I'm Paused!" ) --Debugging
                    end
                end

                v.b:SetPos( v.a:GetPos() ) --Set the stream position in the world to the radio's position in the world.

            --If the entity is valid but the stream isn't then make the key in the table nil.
            elseif ( v.a:IsValid() and not v.b:IsValid() ) then 
                if ( GetConVar( "jtr_debug" ):GetInt() >= 1 ) then
                    PrintTable( a ) 
                    print( "jtrManageSound() | Line 101-111 | stream(s) isn't valid!" ) --Debugging
                end

                v.a:Remove()
                a[ k ] = nil
                PrintTable( a )

            --If the entity isn't valid but the stream is valid then stop the stream and make the key nil.
            elseif ( not v.a:IsValid() and v.b:IsValid() ) then
                if ( GetConVar( "jtr_debug" ):GetInt() >= 1 ) then
                    PrintTable( a )
                    print( "jtrManageSound() | Line 112-121 | radio(s) isn't valid!" ) --Debugging
                end

                v.b:Stop()
                a[ k ] = nil
                PrintTable( a )

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
    if ( not tr.Hit ) then return end --If trace doesn't hit something then don't spawn.

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

--This is for incase the console commands are set to low or high.
function ENT:Think()
end

--https://github.com/garrynewman/garrysmod/blob/master/garrysmod/lua/entities/sent_ball.lua#L149
if ( SERVER ) then return end -- We do NOT want to execute anything below in this FILE on SERVER 

--Test function (WIP)
hook.Add("PopulateToolMenu", "JungleTrainRadioOptions", function()
    --Local function for adding gui stuff to the spawn menu.
    local function Settings(pnl)
        --[[This shouldn't be called but I haven't found a way for adding panels to the spawn menu
        anyother way.]]
        local panel = pnl:AddControl( "CheckBox", { Label = "Enable", Command = "jtr_enable" } )
            panel:SetValue( GetConVarNumber( "jtr_enable" ) ) --Set the value.
        
        --[[This shouldn't be called but I haven't found a way for adding panels to the spawn menu
        anyother way.]]
        local panel = pnl:AddControl( "Slider", { Label = "Volume", Type = "Integer", Command = "jtr_volume", Min = "0", Max = "100" } )
            panel:SetValue( GetConVarNumber( "jtr_volume" ) ) --Set the value.
        
        --[[This shouldn't be called but I haven't found a way for adding panels to the spawn menu
        anyother way.]]
        local panel = pnl:AddControl( "CheckBox", { Label = "Debug", Command = "jtr_debug" } )
            panel:SetValue( GetConVarNumber( "jtr_debug" ) ) --Set the value.
    end

    spawnmenu.AddToolMenuOption("Options", "JungleTrain Radio", "JungleTrain Radio", "Settings", "", "", Settings)
end)

language.Add( "Cleanup_JungleTrain Radio", "JungleTrain Radios" ) --Sets what it says in the cleanup menu in the Spawn Menu.
language.Add( "Cleaned_JungleTrain Radio", "Cleaned up JungleTrain Radios" ) --Sets what it says when the entity gets cleaned.

function ENT:Draw()
    self:DrawModel() --Draw the model.
    
    local logo = Material("radio_jtr/jungletrain_net_final_wb_60.png") --The load for the radio station.
    local Pos = self:GetPos() --Get the position of the entity.
    local Ang = self:GetAngles() --Get the angles of the entity.

    Ang:RotateAroundAxis(Ang:Up(), 90) --Rotate Around Axis Z.
    Ang:RotateAroundAxis(Ang:Forward(), 90) --Rotate Around Axis Y.

    --Display the logo on the entity.
    --If the local player is less then 750 Hammer Units away then display the logo.
    if (self:GetPos():Distance(LocalPlayer():GetPos())) <= 750 then
        --Start the cam.
        cam.Start3D2D(Pos + Ang:Up() * 8.6 + Ang:Right() * -21.6, Ang, 0.11)

        surface.SetMaterial(logo) --Set the material to the logo.
        surface.SetDrawColor(Color(255, 255, 255, 255)) --Set the colour of the logo.
        surface.DrawTexturedRect(-55, 57, 158, 35) --Draw the logo.

        --End the cam.
        cam.End3D2D()
    end
end
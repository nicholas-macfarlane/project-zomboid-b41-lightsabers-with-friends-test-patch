--Rewrite of Mexiox's Lightsabers for local Multiplayer, not tested in online MP.
--This is based on the full version with jedi/sith zombies and machete crafting.
--I think I've made it better, but since I only have about a week's worth of wisom in regards to both LUA and PZ modding, I expect there's still plenty of room for improvement.

--*CHANGE NOTES from Mexiox's Lightsabers*

--*functionality*
--Equip saber to primary then select "Toggle Saber" from inventory context menu to turn saber on/off.
--Hotkey functionality replaced by "Toggle Saber" as above for joystick compatibility.
--No changes to foraging behavior, models/textures, or default sandbox settings from Mexiox's.
--Opportunity for someone ambitious to add individual sound files for each saber's on/off sound
----see "LightsabersWithFriends_sounds.txt"

--*code*
--Spanish variable/file names rewritten to English for my own convenience.
--Files renamed to reflect new "LightsabersWithFriends" mod name
--generally refactored to smaller, with local MP support. Probably left in silly things from when I was figuring everything out.
----local MP players can toggle lightsabers individually from context menu when equipped in primary hand
----lights for each local MP player
--Special thanks to Mexiox for imagining and creating the original SP version, and creating one of the mods that encouraged me to start tinkering with Zomboid mods myself.

local lastPlayerNum = math.floor(getNumActivePlayers() - 0.5)

local sabers = {
	["names"] = {
		"anakin",
		"darthvader",
		"dooku", -- from vader?
		"kenobi", --placeholder sounds copied from luke
		"luke",
		"kylo",
		"mace" --same
	},
	["lightColors"] = {
        ["anakin_on"] = { 0.0, 0.0, 1.0 },
        ["kenobi_on"] = { 0.0, 0.0, 1.0 },
        ["darthvader_on"] = {1.0, 0.0, 0.0},
        ["dooku_on"] = {1.0, 0.0, 0.0},
        ["kylo_on"] = {1.0, 0.0, 0.0},
        ["luke_on"] = {0.0, 1.0, 0.0},
        ["mace_on"] = { 1.0, 0.0, 1.0 },
        ["machete_on_blue"] = { 0.0, 0.0, 1.0 },
        ["machete_on_red"] = {1.0, 0.0, 0.0},
        ["machete_on_green"] = {0.0, 1.0, 0.0},
        ["machete_on_purple"] = { 1.0, 0.0, 1.0 },
        ["machete_on_pink"] = { 1.0, 0.0, 0.25 },
        ["machete_on_yellow"] = { 1.0, 1.0, 0.0 },
        ["machete_on_orange"] = { 1.0, 0.50, 0.0 },
	},
	["activeLights"] = {
	},
	["cells"] = {
	}
}
sabers.populate = function()
	for i = 0, lastPlayerNum, 1
	do
	    sabers.activeLights[i] = false
		sabers.cells[i] = false
	end
end
sabers.populate()
local function isEquippedPrimary(item, player)
	return item == player:getPrimaryHandItem()
end
local function isSaber(itemType)
	local itemTypeTable = splitString(itemType, "_")
	local result = false
	if itemTypeTable[1] == "machete" and itemTypeTable[2] == "on" or itemTypeTable[3] == "off" then
		result = true
		return result
	end
	for key, value in pairs (sabers.names) do
		if value == itemTypeTable[1] then 
			result = true
			return result
		end
	end
	return result
end
local function isSaberOn(itemType)
	local result = false --for switched-off machete sabers, this next string will be a color instead of "off"
	local saberString = splitString(itemType, "_")
	if saberString[2] ~= "on" then --we got a color, it's a switched-off machete
		return result
	end
	result = true
	return result
end
local function light(item, player)
	local playerNum = player:getPlayerNum()
	local colors = sabers.lightColors[item:getType()] --Get the rgb values for the specific saber
	sabers.cells[playerNum] = player:getCell()
	sabers.activeLights[playerNum] = IsoLightSource.new(player:getX(), player:getY(), player:getZ(), colors[1], colors[2], colors[3], 4) -- create light source object with saber color and player coordinates
	sabers.cells[playerNum]:addLamppost(sabers.activeLights[playerNum]) -- place the light into the game world
end

local function updateGlow(player) --removes previous light source
	local playerNum = player:getPlayerNum()
	local cell = sabers.cells[playerNum]
	if cell then
		local oldLight = sabers.activeLights[playerNum]
		if oldLight then 
			oldLight:setActive(false) -- I know we're about to remove it, but performance *TANKS* without this line.
		    cell:removeLamppost(oldLight) -- remove previous light source
		end
	    sabers.activeLights[playerNum] = false -- remove data for previous light source
		sabers.cells[playerNum] = false
	end
	
    local item = player:getPrimaryHandItem()
	if not item then return false end
	local itemType = item:getType()
	if not string.match(itemType, "_") then return false end
    if not isSaber(itemType) then return false end
	if isSaberOn(itemType) then	  
	    light(item, player) -- create the light
	    item:setBloodLevel(0.0) -- It's a freaking plasma sword, the blood burns right off. Not sure if having this in the update function is a performance no-no, though.
	    --player:playSound("SaberHum") -- From Mexiox's notes, this was disabled because it was more annoying than entertaining. Leaving it here if you wanna try it, though. :D
	end
	return
end

function splitString(text, delim)
    -- returns an array of fields based on text and delimiter (one character only)
    local result = {}
    local magic = "().%+-*?[]^$"

    if delim == nil then
        delim = "%s"
    elseif string.find(delim, magic, 1, true) then
        -- escape magic
        delim = "%"..delim
    end

    local pattern = "[^"..delim.."]+"
    for w in string.gmatch(text, pattern) do
        table.insert(result, w)
    end
    return result
end

local function getSaberName(itemType)
	local name = splitString(itemType, "_")[1]
	return name
end
local function getMacheteColor(itemType)
	local color = ""
	local machete = splitString(itemType, "_")
	if machete[2] == "off" then
		color = machete[3]
	else
		color = machete[2]
	end
	return color
end

local function toggleSaber(player, item, unequipped)
	local itemType = item:getType()
	local saberIsOn = isSaberOn(itemType)
	local machete = (splitString(itemType)[1]=="machete")
	local sound = ""
	local name = getSaberName(itemType)
	local newName = ""
	local inventory = player:getInventory()
	if not saberIsOn then
		sound = machete and "darthIgnition" or name.."Ignition"
		newName = machete and "machete_on_"..getMacheteColor or name.."_on"
	else
		sound = machete and "darthToff" or name.."Toff"
		newName = machete and "machete_"..getMacheteColor.."_off" or name.."_off"
	end

	local newItem = inventory:AddItem("LightsabersWithFriends."..newName)
	newItem:setCondition(item:getCondition())
	inventory:Remove(item)
	if unequipped then 
		player:setPrimaryHandItem(nil) 
	else 
		player:setPrimaryHandItem(newItem)
	end
	player:playSound(sound)
	LScheckHotbar(item, newItem)
	return
end

local LightsaberContext = {}
LightsaberContext.doMenu = function(playerNum, context, worldobjects)
	local player = getSpecificPlayer(playerNum)
	local item = false
	for i,k in pairs(worldobjects) do 
		if k.items[1] == player:getPrimaryHandItem() then
			item = k.items[1]
			break
		end
	end
	if not item then
	    return 
    end
	local itemType = item:getType()
	if not itemType then return end
	if not isSaber(itemType) then return end 
	context:addOption(getText("IGUI_ContextMenuLightsaberToggle"), player, LightsaberContext.toggle, item)
	return
end

local LWF_OVERRIDE_ISInventoryPaneContextMenu_onUnEquip = ISInventoryPaneContextMenu.onUnEquip 
ISInventoryPaneContextMenu.onUnEquip = function(items, playerNum)
	local itemToToggle = false
	items = ISInventoryPane.getActualItems(items)
	for i,k in ipairs(items) do
		local itemType = k:getType()
		if isSaber(itemType) then 
			if isSaberOn(itemType) then
				toggleSaber(getSpecificPlayer(playerNum), k, true )
				return
			end
		end
		ISInventoryPaneContextMenu.unequipItem(k, playerNum, 50)
    end
end
local LWF_OVERRIDE_ISInventoryPaneContextMenu_unequipItem = ISInventoryPaneContextMenu.unequipItem 
ISInventoryPaneContextMenu.unequipItem = function(item, player, time)
    if not getSpecificPlayer(player):isEquipped(item) then return end
    if item ~= nil and item:getType() == "CandleLit" then item = ISInventoryPaneContextMenu.litCandleExtinguish(item, player) end
    ISTimedActionQueue.add(ISUnequipAction:new(getSpecificPlayer(player), item, time or 50));
end
LightsaberContext.toggle = function(player, item)
	local result = toggleSaber(player, item, false)
	return result
end

function LScheckHotbar(prev_weapon, result)
	local Hotbar = getPlayerHotbar(0)
	if Hotbar ~= nil then
		local W_slot = prev_weapon:getAttachedSlot()
		local slot = Hotbar.availableSlot[W_slot]
		if (slot) and (result) and (not Hotbar:isInHotbar(result)) and (Hotbar:canBeAttached(slot, result)) then
			Hotbar:removeItem(prev_weapon, false)
			Hotbar:attachItem(result, slot.def.attachments[result:getAttachmentType()], W_slot, slot.def, false)
		end
	else	DebugSay (3,"Hotbar - N/A")
	end
end

Events.OnPlayerUpdate.Add(updateGlow);
Events.OnFillInventoryObjectContextMenu.Add(LightsaberContext.doMenu)

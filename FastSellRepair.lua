-- FastSellRepair: Auto-Sell Junk & Auto-Repair
-- Verkauft automatisch graue Items und repariert beim Händler

local addonName = "FastSellRepair"
local frame = CreateFrame("Frame")

-- Defaults
local defaults = {
    autoRepair = true,
    useGuildRepair = false,
    autoSellJunk = true,
    showMessages = true,
}

-- Init saved variables
local function InitDB()
    if not FastSellRepairDB then
        FastSellRepairDB = {}
    end
    for k, v in pairs(defaults) do
        if FastSellRepairDB[k] == nil then
            FastSellRepairDB[k] = v
        end
    end
end

-- Print helper
local function Print(msg)
    if FastSellRepairDB.showMessages then
        print("|cff00cc66[FastSellRepair]|r " .. msg)
    end
end

-- Sell all grey (junk) items
local function SellJunk()
    if not FastSellRepairDB.autoSellJunk then return end

    local totalEarned = 0

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue then
                C_Container.UseContainerItem(bag, slot)
                totalEarned = totalEarned + (info.stackCount * (info.itemID and select(11, C_Item.GetItemInfo(info.itemID)) or 0))
            end
        end
    end

    if totalEarned > 0 then
        Print("Junk verkauft: " .. GetCoinTextureString(totalEarned))
    end
end

-- Repair all items
local function RepairGear()
    if not FastSellRepairDB.autoRepair then return end
    if not CanMerchantRepair() then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost == 0 then return end

    -- Try guild repair first if enabled
    if FastSellRepairDB.useGuildRepair and IsInGuild() then
        local guildOk = RepairAllItems(true)
        if guildOk ~= false then
            Print("Repariert (Gildenbank): " .. GetCoinTextureString(repairCost))
            return
        end
    end

    -- Personal gold repair
    if GetMoney() >= repairCost then
        RepairAllItems(false)
        Print("Repariert: " .. GetCoinTextureString(repairCost))
    else
        Print("|cffff0000Nicht genug Gold zum Reparieren!|r")
    end
end

-- Event handler
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        Print("Geladen! Befehle: /fsr")
    elseif event == "MERCHANT_SHOW" then
        -- Small delay to let merchant window fully load
        C_Timer.After(0.3, function()
            SellJunk()
            RepairGear()
        end)
    end
end)

-- Slash commands
SLASH_FASTSELLREPAIR1 = "/fsr"
SLASH_FASTSELLREPAIR2 = "/fastsellrepair"

SlashCmdList["FASTSELLREPAIR"] = function(msg)
    msg = msg:lower():trim()

    if msg == "repair" or msg == "rep" then
        FastSellRepairDB.autoRepair = not FastSellRepairDB.autoRepair
        Print("Auto-Repair: " .. (FastSellRepairDB.autoRepair and "|cff00ff00AN|r" or "|cffff0000AUS|r"))

    elseif msg == "sell" or msg == "junk" then
        FastSellRepairDB.autoSellJunk = not FastSellRepairDB.autoSellJunk
        Print("Auto-Sell Junk: " .. (FastSellRepairDB.autoSellJunk and "|cff00ff00AN|r" or "|cffff0000AUS|r"))

    elseif msg == "guild" then
        FastSellRepairDB.useGuildRepair = not FastSellRepairDB.useGuildRepair
        Print("Gildenbank-Reparatur: " .. (FastSellRepairDB.useGuildRepair and "|cff00ff00AN|r" or "|cffff0000AUS|r"))

    elseif msg == "silent" then
        FastSellRepairDB.showMessages = not FastSellRepairDB.showMessages
        print("|cff00cc66[FastSellRepair]|r Nachrichten: " .. (FastSellRepairDB.showMessages and "|cff00ff00AN|r" or "|cffff0000AUS|r"))

    elseif msg == "status" then
        Print("--- Einstellungen ---")
        Print("Auto-Repair: " .. (FastSellRepairDB.autoRepair and "|cff00ff00AN|r" or "|cffff0000AUS|r"))
        Print("Auto-Sell Junk: " .. (FastSellRepairDB.autoSellJunk and "|cff00ff00AN|r" or "|cffff0000AUS|r"))
        Print("Gildenbank: " .. (FastSellRepairDB.useGuildRepair and "|cff00ff00AN|r" or "|cffff0000AUS|r"))
        Print("Nachrichten: " .. (FastSellRepairDB.showMessages and "|cff00ff00AN|r" or "|cffff0000AUS|r"))

    else
        Print("--- Befehle ---")
        Print("/fsr repair - Auto-Repair an/aus")
        Print("/fsr sell - Auto-Sell Junk an/aus")
        Print("/fsr guild - Gildenbank-Reparatur an/aus")
        Print("/fsr silent - Chat-Nachrichten an/aus")
        Print("/fsr status - Aktuelle Einstellungen")
    end
end

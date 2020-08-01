BiggerBuffs = BiggerBuffs or {}

-- blizz ui
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local SlashCmdList = SlashCmdList
local InCombatLockdown = InCombatLockdown
local DefaultCompactUnitFrameSetupOptions = DefaultCompactUnitFrameSetupOptions

-- import local
local Utl = BiggerBuffs_Utils
local Saved = BiggerBuffs.Saved

-- locals
local started = false

-- [ slash commands ] --

SLASH_BIGGERBUFFS1 = "/bigger"
function SlashCmdList.BIGGERBUFFS(msg)
  local splitted = Utl.strsplit(msg)
  local command = splitted[0]
  local option = splitted[1]

  if command == "scale" and tonumber(option) ~= nil then
    Saved.setOption("scalefactor", tonumber(option))
    print("Updated.")
    print("In order to get a display update, switch between raid profiles.")
  elseif command == "maxbuffs" and tonumber(option) ~= nil then
    Saved.setOption("maxbuffs", tonumber(option))
    print("Updated.")
    print("In order to get a display update, switch between raid profiles.")
  elseif command == "hidenames" and tonumber(option) ~= nil then
    Saved.setOption("hidenames", tonumber(option))
  elseif command == "rowsize" and tonumber(option) ~= nil and tonumber(option) >= 3 then
    Saved.setOption("rowsize", tonumber(option))
    print("Rowsize updated.")
    print("In order to get a display update, switch between raid profiles.")
  else
    BiggerBuffs.ShowUI()
  end
end

-- [ startup ] --

local function createBuffFrames(frame)
  if InCombatLockdown() == true then
    return
  end

  -- insert and reposition missing frames (for >3 buffs)
  local maxbuffs = biggerbuffsSaved.Options.maxbuffs
  local rowsize = biggerbuffsSaved.Options.rowsize or 3
  local fname = frame:GetName()
  if not fname then
    return
  end
  local frameName = frame:GetName() .. "Buff"
  for i = 4, maxbuffs do
    local child = _G[frameName .. i] or CreateFrame("Button", frameName .. i, frame, "CompactBuffTemplate")
    child:ClearAllPoints()
    if math.fmod(i - 1, rowsize) == 0 then -- (i-1) % 3 == 0
      child:SetPoint("BOTTOMRIGHT", _G[frameName .. i - rowsize], "TOPRIGHT")
    else
      child:SetPoint("BOTTOMRIGHT", _G[frameName .. i - 1], "BOTTOMLEFT")
    end
  end
  frame.maxBuffs = maxbuffs

  -- update size
  local options = DefaultCompactUnitFrameSetupOptions
  local scale = min(options.height / 36, options.width / 72)
  local buffSize = Saved.getOption("scalefactor") * scale
  for i = 1, maxbuffs do
    local child = _G[frameName .. i]
    if child then
      child:SetSize(buffSize, buffSize)
    end
  end
end

local function activateMe()
  if started == true then
    return
  end
  started = true

  hooksecurefunc("CompactUnitFrame_UpdateAll", createBuffFrames)

  local prevhook = _G.CompactUnitFrame_UtilShouldDisplayBuff
  _G.CompactUnitFrame_UtilShouldDisplayBuff = function(...)
    local bannedBuffs = Saved.root().bannedBuffs
    local additionalBuffsIdx = Saved.root().additionalBuffsIdx

    local buffName, _, _, _, _, _, source = ...
    if source == "player" then
      if bannedBuffs[buffName] ~= nil then
        return false
      end
      if additionalBuffsIdx[buffName] ~= nil then
        return true
      end
    end
    return prevhook(...)
  end
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript(
  "OnEvent",
  function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MyBiggerBuffs" then
      Saved.init()
      activateMe()
    elseif event == "PLAYER_REGEN_ENABLED" and Saved.setOption("hidenames", 1) and started == true then
      Utl.loopAllMembers(
        function(frameName)
          _G[frameName .. "Name"]:Show()
        end
      )
    elseif event == "PLAYER_REGEN_DISABLED" and Saved.setOption("hidenames", 1) and started == true then
      Utl.loopAllMembers(
        function(frameName)
          _G[frameName .. "Name"]:Hide()
        end
      )
    end
  end
)

local _G = _G
local C_PetBattles_GetActivePet = C_PetBattles.GetActivePet
local C_PetBattles_GetIcon = C_PetBattles.GetIcon
local C_PetBattles_GetName = C_PetBattles.GetName
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter
local format = format
local ipairs = ipairs
local math_abs = math.abs
local next = next
local pairs = pairs
local string_gmatch = string.gmatch
local string_match = string.match
local table_concat = table.concat
local table_insert = table.insert
local table_wipe = table.wipe
local tonumber = tonumber
local type = type
local unpack = unpack

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("EXTRA_PETBATTLE", "PET_BATTLES")
local petBattle

local FLAG_CSW = 1
local FLAG_LEVEL = 2
local FLAG_NAME = 3
local FLAG_NUMBER = 4
local FLAG_PET = 5
local FLAG_ROUND = 6
local FLAG_SOURCE = 7
local FLAG_SPELL = 8
local FLAG_TARGET = 9
local FLAG_TEAM = 10
local FLAG_TEXTURE = 11

local ABILITY_CRIT = 1
local ABILITY_NORMAL = 2
local ABILITY_STRONG = 3
local ABILITY_WEAK = 4
local AURA_APPLIED = 1
local AURA_FADED = 2
local AVOID_DEFLECT = 1
local AVOID_DODGE = 2
local AVOID_MISS = 3
local AVOID_REFLECT = 4
local HEAL_SINGLE = 1
local TRAP_HIT = 1
local TRAP_MISS = 2

local TYPE_AURA = 1
local TYPE_AVOID = 2
local TYPE_DAMAGE = 3
local TYPE_DEATH = 4
local TYPE_HEAL = 5
local TYPE_LEVEL = 6
local TYPE_SWITCH = 7
local TYPE_TRAP = 8
local TYPE_XP = 9

local MINE = 1
local ENEMY = 2

local AVOID_DEFLECT = 1
local AVOID_DODGE = 2
local AVOID_MISS = 3
local AVOID_REFLECT = 4

local AVOID_SUFFIXES = {
  [AVOID_DEFLECT] = addonData:GetNumLetters(ACTION_SPELL_MISSED_DEFLECT, 2),
  [AVOID_DODGE] = addonData:GetNumLetters(ACTION_SPELL_MISSED_DODGE, 2),
  [AVOID_MISS] = addonData:GetNumLetters(ACTION_SPELL_MISSED_MISS, 2),
  [AVOID_REFLECT] = addonData:GetNumLetters(ACTION_SPELL_MISSED_REFLECT, 2),
}

local function StripNonWord(str)
  local temp = ""
  for uchar in string_gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
    if string_match(uchar, "[^%W]") then
      temp = temp .. uchar
    end
  end
  return temp
end

local DAMAGE_SUFFIXES = {
  [ABILITY_CRIT] = addonData:GetNumLetters(StripNonWord(PET_BATTLE_COMBAT_LOG_DAMAGE_CRIT), 2),
  [ABILITY_NORMAL] = "",
  [ABILITY_STRONG] = addonData:GetNumLetters(StripNonWord(PET_BATTLE_COMBAT_LOG_DAMAGE_STRONG), 2),
  [ABILITY_WEAK] = addonData:GetNumLetters(StripNonWord(PET_BATTLE_COMBAT_LOG_DAMAGE_WEAK), 2),
}

local function PetBattle_AuraApplied(self, flags, spell, effect, team, target)
  self:Aura(spell, effect, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, AURA_APPLIED)
end

local function PetBattle_AuraFades(self, flags, effect, team, target)
  self:Aura(effect, nil, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, AURA_FADED)
end

local function PetBattle_Damage(self, flags, spell, damage, team, target, csw)
  if target:find(PET_BATTLE_COMBAT_LOG_DAMAGE_CRIT, nil, 1) then
    target = target:gsub(addonData:FormatMatcher(PET_BATTLE_COMBAT_LOG_DAMAGE_CRIT), "", 1)
    csw = ABILITY_CRIT
  elseif target:find(PET_BATTLE_COMBAT_LOG_DAMAGE_STRONG, nil, 1) then
    target = target:gsub(addonData:FormatMatcher(PET_BATTLE_COMBAT_LOG_DAMAGE_STRONG), "", 1)
    csw = ABILITY_STRONG
  elseif target:find(PET_BATTLE_COMBAT_LOG_DAMAGE_WEAK, nil, 1) then
    target = target:gsub(addonData:FormatMatcher(PET_BATTLE_COMBAT_LOG_DAMAGE_WEAK), "", 1)
    csw = ABILITY_WEAK
  else
    csw = ABILITY_NORMAL
  end
  --_G.print("'" .. table.concat({tostring(spell), tostring(damage), team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER and "isMine" or "isEnemy", tostring(target), tostring(csw)}, "', '") .. "'") -- DEBUG
  self:Damage(spell, tonumber(damage) or 0, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, csw)
end

local function PetBattle_Deflect(self, flags, spell, team, target)
  self:Avoid(spell, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, AVOID_DEFLECT)
end

local function PetBattle_Died(self, flags, team, target)
  local teamId
  if team == PET_BATTLE_COMBAT_LOG_YOUR then
    teamId = LE_BATTLE_PET_ALLY
  elseif team == PET_BATTLE_COMBAT_LOG_ENEMY then
    teamId = LE_BATTLE_PET_ENEMY
  end
  if teamId then
    local petIndex = C_PetBattles_GetActivePet(teamId)
    local petIcon = "|T"..C_PetBattles_GetIcon(teamId, petIndex)..":0:0|t"
    local petName = C_PetBattles_GetName(teamId, petIndex)
    self:Died(petIcon .. petName, target)
  end
end

local function PetBattle_Dodge(self, flags, spell, team, target)
  self:Avoid(spell, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, AVOID_DODGE)
end

local function PetBattle_Healing(self, flags, spell, healing, team, target)
  self:Heal(spell, tonumber(healing) or 0, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, HEAL_SINGLE)
end

local function PetBattle_Level(self, flags, team, target, number)
  self:Level(team == PET_BATTLE_COMBAT_LOG_YOUR, target, number)
end

local function PetBattle_Miss(self, flags, spell, team, target)
  self:Avoid(spell, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, AVOID_MISS)
end

local function PetBattle_Reflected(self, flags, spell, team, target)
  self:Avoid(spell, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER, target, AVOID_REFLECT)
end

local function PetBattle_Round(self, flags, round)
  if not self.round or self.round == 0 then
    self.round = tonumber(round) or 0
  end
end

local function PetBattle_Switch(self, flags, pet, team)
  self:Switch(pet, team == PET_BATTLE_COMBAT_LOG_YOUR_LOWER)
end

local function PetBattle_Trap(self, flags, trap, team, target)
  self:Trap(trap, target, TRAP_HIT)
end

local function PetBattle_TrapFail(self, flags, trap, team, target)
  self:Trap(trap, target, TRAP_MISS)
end

local function PetBattle_XP(self, flags, team, target, number)
  self:XP(team == PET_BATTLE_COMBAT_LOG_YOUR, target, number)
end

local function ChatFilter(chatFrame, event, ...)
  if chatFrame == addonData:GetChatFrame() then
    return true
  end
end

function module:OnLoad()
  petBattle = {
    matches = {
      [1] = {
        PET_BATTLE_COMBAT_LOG_AURA_APPLIED, -- "%s applied %s to %s %s."
        {
          FLAG_SOURCE,
          FLAG_SPELL,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_AuraApplied,
      },
      [2] = {
        PET_BATTLE_COMBAT_LOG_AURA_FADES, -- "%s fades from %s %s."
        {
          FLAG_SPELL,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_AuraFades,
      },
      [3] = {
        PET_BATTLE_COMBAT_LOG_DAMAGE, -- "%s dealt %d damage to %s %s%s."
        {
          FLAG_SOURCE,
          FLAG_NUMBER,
          FLAG_TEAM,
          FLAG_TARGET,
          FLAG_CSW,
        },
        PetBattle_Damage,
      },
      [4] = {
        PET_BATTLE_COMBAT_LOG_HEALING, -- "%s healed %d damage from %s %s."
        {
          FLAG_SPELL,
          FLAG_NUMBER,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Healing,
      },
      [5] = {
        PET_BATTLE_COMBAT_LOG_PET_SWITCHED, -- "%s is now %s active pet."
        {
          FLAG_PET,
          FLAG_TEAM,
        },
        PetBattle_Switch,
      },
      [6] = {
        PET_BATTLE_COMBAT_LOG_MISS, -- "%s missed %s %s."
        {
          FLAG_SPELL,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Miss,
      },
      [7] = {
        PET_BATTLE_COMBAT_LOG_REFLECT, -- "%s was reflected by %s %s."
        {
          FLAG_SPELL,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Reflected,
      },
      [8] = {
        PET_BATTLE_COMBAT_LOG_DODGE, -- "%s was dodged by %s %s."
        {
          FLAG_SPELL,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Dodge,
      },
      [9] = {
        PET_BATTLE_COMBAT_LOG_DEFLECT, -- "%s was deflected by %s %s."
        {
          FLAG_SPELL,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Deflect,
      },
      [10] = {
        PET_BATTLE_COMBAT_LOG_DEATH, -- "%s %s died."
        {
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Died,
      },
      [11] = {
        PET_BATTLE_COMBAT_LOG_NEW_ROUND, -- "Round %d"
        {
          FLAG_ROUND,
        },
        PetBattle_Round,
      },
      [12] = {
        PET_BATTLE_COMBAT_LOG_XP, -- "%s %s gains %d XP."
        {
          FLAG_TEAM,
          FLAG_TARGET,
          FLAG_NUMBER,
        },
        PetBattle_XP,
      },
      [13] = {
        BATTLE_PET_COMBAT_LOG_LEVEL_UP, -- "%s %s has reached Level %d!"
        {
          FLAG_TEAM,
          FLAG_TARGET,
          FLAG_NUMBER,
        },
        PetBattle_Level,
      },
      [14] = {
        PET_BATTLE_COMBAT_LOG_TRAP_HIT, -- "%s trapped %s %s."
        {
          FLAG_SOURCE,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_Trap,
      },
      [15] = {
        PET_BATTLE_COMBAT_LOG_TRAP_MISS, -- "%s failed to trap %s %s."
        {
          FLAG_SOURCE,
          FLAG_TEAM,
          FLAG_TARGET,
        },
        PetBattle_TrapFail,
      },
    },

    PrepStruct = function(self, a, b, c)
      if a then
        if not self.combat[a] then
          self.combat[a] = {}
        end
        if b then
          if not self.combat[a][b] then
            self.combat[a][b] = {}
          end
          if c then
            if not self.combat[a][b][c] then
              self.combat[a][b][c] = {}
            end
            return self.combat[a][b][c]
          end
          return self.combat[a][b]
        end
        return self.combat[a]
      end
    end,

    Aura = function(self, spell, effect, isMine, target, flag)
      local struct = self:PrepStruct(TYPE_AURA, target, spell)
      struct.mine = isMine
      struct.effect = effect
      struct.flag = flag
    end,

    Damage = function(self, spell, damage, isMine, target, flag)
      local struct = self:PrepStruct(TYPE_DAMAGE, target, spell)
      struct.mine = isMine
      struct.damage = (struct.damage or 0) + damage
      struct.flag = flag
      --_G.print(struct.mine, struct.damage, struct.flag, "") -- DEBUG
    end,

    Died = function(self, attacker, victim)
      local struct = self:PrepStruct(TYPE_DEATH, victim)
      struct.mine = false -- TODO: mine or enemy?
      struct.attacker = attacker
    end,

    Heal = function(self, spell, healing, isMine, target, flag)
      local struct = self:PrepStruct(TYPE_HEAL, target, spell)
      struct.mine = isMine
      struct.healing = (struct.healing or 0) + healing
      struct.flag = ABILITY_NORMAL -- TODO: heals can't crit, or am I wrong?
    end,

    Level = function(self, isMine, target, level)
      local struct = self:PrepStruct(TYPE_LEVEL, target)
      struct.mine = true
      struct.level = level
    end,

    Avoid = function(self, spell, isMine, target, flag)
      local struct = self:PrepStruct(TYPE_AVOID, target, spell)
      struct.mine = isMine
      struct.count = (struct.count or 0) + 1
      struct.flag = flag
    end,

    Switch = function(self, target, isMine)
      local struct = self:PrepStruct(TYPE_SWITCH, target)
      struct.mine = isMine
    end,

    Trap = function(self, trap, target, flag)
      local struct = self:PrepStruct(TYPE_TRAP, target)
      struct.mine = true
      struct.trap = trap
      struct.flag = flag
    end,

    XP = function(self, isMine, target, xp)
      local struct = self:PrepStruct(TYPE_XP, target)
      struct.mine = true
      struct.xp = (struct.xp or 0) + xp
    end,

    round = 0,
    combat = {},

    NewRound = function(self, isFirst)
      if isFirst then
        self.round = 0
      else
        self.round = self.round + 1
      end
      table_wipe(self.combat)
    end,

    EndCombat = function(self)
      local temp1, temp2

      if self.combat[TYPE_TRAP] then
        temp1, temp2 = "", ""
        for target, data in pairs(self.combat[TYPE_TRAP]) do
          if data.flag == TRAP_HIT then
            temp1 = temp1 .. target .. " "
          else
            temp2 = temp2 .. target .. " "
          end
        end
        if temp1 ~= "" then
          print("|cff55FF55You have caught " .. temp1:sub(1, temp1:len() - 1) .. "!|r")
        end
        if temp2 ~= "" then
          print("|cff55FF55You failed  to catch " .. temp2:sub(1, temp2:len() - 1) .. "!|r")
        end
      end

      temp1 = {}
      if self.combat[TYPE_LEVEL] then
        for target, data in pairs(self.combat[TYPE_LEVEL]) do
          temp1[target] = data.level
        end
      end

      if self.combat[TYPE_XP] then
        for target, data in pairs(self.combat[TYPE_XP]) do
          if temp1[target] then
            print("|cff55FF55" .. target .. " gained " .. data.xp .. " XP and dinged level " .. temp1[target] .. "!|r")
            temp1[target] = nil
          else
            print("|cff55FF55" .. target .. " gained " .. data.xp .. " XP!|r")
          end
        end
      end

      if self.finalRound then
        local won = self.finalRound == 1
        self.finalRound = nil
        print("You have " .. (won and "won" or "lost/forfeit") .. " the battle!")
      end

      self.round = 0
      table_wipe(self.combat)
    end,

    CombatLog = function(self, message)
      local temp
      for _, matcher in ipairs(self.matches) do
        temp = {message:match(matcher[1])}
        if temp[1] then
          --_G.print(message) _G.print(matcher[1]) UIParentLoadAddOn("Blizzard_DebugTools") DevTools_Dump(temp) _G.print("") -- DEBUG
          return matcher[3](self, matcher[2], unpack(temp))
        end
      end
    end,

    GenerateCombatSummary = function(self)
      local temp, team = {}
      for eventType, eventData in pairs(self.combat) do
        for target, data in pairs(eventData) do
          if eventType == TYPE_AURA then
            for spell, info in pairs(data) do
              team = info.mine and MINE or ENEMY
              if not temp[team] then
                temp[team] = {}
              end
              if not temp[team][target] then
                temp[team][target] = {}
              end
              if not temp[team][target].aura then
                temp[team][target].aura = {}
              end
              if info.flag == AURA_APPLIED then
                temp[team][target].aura[spell] = 1
              elseif info.flag == AURA_FADED then
                temp[team][target].aura[spell] = nil
              end
              if not next(temp[team][target].aura) then
                temp[team][target].aura = nil
              end
            end

          elseif eventType == TYPE_AVOID then
            for spell, info in pairs(data) do
              team = info.mine and MINE or ENEMY
              if not temp[team] then
                temp[team] = {}
              end
              if not temp[team][target] then
                temp[team][target] = {}
              end
              if not temp[team][target].avoid then
                temp[team][target].avoid = {}
              end
              if not temp[team][target].avoid[info.flag] then
                temp[team][target].avoid[info.flag] = 0
              end
              temp[team][target].avoid[info.flag] = temp[team][target].avoid[info.flag] + (info.count or 1)
            end

          elseif eventType == TYPE_DAMAGE then
            for spell, info in pairs(data) do
              team = info.mine and MINE or ENEMY
              if not temp[team] then
                temp[team] = {}
              end
              if not temp[team][target] then
                temp[team][target] = {}
              end
              if not temp[team][target].damage then
                temp[team][target].damage = 0
              end
              temp[team][target].damage = temp[team][target].damage + (tonumber(info.damage) or 0)
              if info.flag == ABILITY_CRIT then
                temp[team][target].isCrit = true
              elseif info.flag == ABILITY_NORMAL then
                temp[team][target].isNormal = true
              elseif info.flag == ABILITY_STRONG then
                temp[team][target].isStrong = true
              elseif info.flag == ABILITY_WEAK then
                temp[team][target].isWeak = true
              end
            end

          elseif eventType == TYPE_DEATH then
            team = data.mine and MINE or ENEMY
            if not temp[team] then
              temp[team] = {}
            end
            if not temp[team][target] then
              temp[team][target] = {}
            end
            temp[team][target].death = data.attacker

          elseif eventType == TYPE_HEAL then
            for spell, info in pairs(data) do
              team = info.mine and MINE or ENEMY
              if not temp[team] then
                temp[team] = {}
              end
              if not temp[team][target] then
                temp[team][target] = {}
              end
              if not temp[team][target].damage then
                temp[team][target].damage = 0
              end
              temp[team][target].damage = temp[team][target].damage - (tonumber(info.healing) or 0)
              if info.flag == ABILITY_CRIT then
                temp[team][target].isCrit = true
              elseif info.flag == ABILITY_NORMAL then
                temp[team][target].isNormal = true
              elseif info.flag == ABILITY_STRONG then
                temp[team][target].isStrong = true
              elseif info.flag == ABILITY_WEAK then
                temp[team][target].isWeak = true
              end
            end

          elseif eventType == TYPE_LEVEL then
            team = data.mine and MINE or ENEMY
            if not temp[team] then
              temp[team] = {}
            end
            if not temp[team][target] then
              temp[team][target] = {}
            end
            temp[team][target].level = data.level

          elseif eventType == TYPE_SWITCH then
            team = data.mine and MINE or ENEMY
            if not temp[team] then
              temp[team] = {}
            end
            if not temp[team][target] then
              temp[team][target] = {}
            end
            temp[team][target].switch = 1

          elseif eventType == TYPE_TRAP then
            team = data.mine and MINE or ENEMY
            if not temp[team] then
              temp[team] = {}
            end
            if not temp[team][target] then
              temp[team][target] = {}
            end
            temp[team][target].trap = data.flag

          elseif eventType == TYPE_XP then
            team = data.mine and MINE or ENEMY
            if not temp[team] then
              temp[team] = {}
            end
            if not temp[team][target] then
              temp[team][target] = {}
            end
            if not temp[team][target].xp then
              temp[team][target].xp = 0
            end
            temp[team][target].xp = temp[team][target].xp + (tonumber(data.xp) or 0)
          end
        end
      end
      return temp
    end,

    PrintRoundSummary = function(self, isOpening)
      if isOpening then
        local teamId = LE_BATTLE_PET_ENEMY
        local mainPet = C_PetBattles_GetActivePet(teamId)
        local temp = {"|T"..C_PetBattles_GetIcon(teamId, mainPet)..":0:0|t" .. C_PetBattles_GetName(teamId, mainPet)}
        local numPets = 1
        local petTexture, petName
        for petIndex = 1, NUM_BATTLE_PETS_IN_BATTLE do
          if petIndex ~= mainPet then
            petTexture = C_PetBattles_GetIcon(teamId, petIndex)
            petName = C_PetBattles_GetName(teamId, petIndex)
            if petTexture and petName then
              table_insert(temp, "|T" .. petTexture .. ":0:0|t" .. petName)
              numPets = numPets + 1
            end
          end
        end
        temp = table_concat(temp, ", ")
        temp = temp:gsub("(.+), ", "%1 and ", 1)
        if numPets > 1 then
          return print("Enemies " .. temp .. " appear!")
        else
          return print("Enemy " .. temp .. " appears!")
        end
      end

      local combat = self:GenerateCombatSummary()

      local temp, diff, flag
      local lines, trap, death, switch = {}, {}, {}, {}

      for team = MINE, ENEMY do
        if combat[team] then
          for target, info in pairs(combat[team]) do
            local hasName

            -- TODO: .aura[spell] = 1

            if info.trap then
              trap[team] = {target, info.trap} -- info.trap
            end

            if info.death then
              death[team] = target -- info.death
            end

            if info.switch then
              switch[team] = target -- info.switch
            end

            temp = ""

            if info.damage then
              if not hasName then
                temp = temp .. target .. " "
                hasName = 1
              end
              if info.damage > 0 or info.damage < 0 then
                if info.isCrit then
                  flag = DAMAGE_SUFFIXES[ABILITY_CRIT]
                elseif info.isNormal then
                  flag = DAMAGE_SUFFIXES[ABILITY_NORMAL]
                elseif info.isStrong then
                  flag = DAMAGE_SUFFIXES[ABILITY_STRONG]
                elseif info.isWeak then
                  flag = DAMAGE_SUFFIXES[ABILITY_WEAK]
                else
                  flag = ""
                end
                if flag ~= "" then
                  flag = "|cffCCCCCC" .. "-" .. flag .. "|r"
                end
                if info.damage > 0 then
                  temp = temp .. "|cffFF5555" .. info.damage .. HP .. "|r" .. flag .. " "
                else
                  temp = temp .. "|cff55FF55" .. math_abs(info.damage) .. HP .. "|r" .. flag .. " "
                end
              else
                temp = temp .. "|cffFFFF00" .. "~" .. HP .. "|r " -- TODO: should these be shown? (no change in health, like 0 damage, or 0 heal effects)
              end
            end

            if info.avoid then
              if not hasName then
                temp = temp .. target .. " "
                hasName = 1
              end
              for avoidType, count in pairs(info.avoid) do
                temp = temp .. "|cffCCCCCC" .. count .. AVOID_SUFFIXES[avoidType] .. "|r "
              end
            end

            temp = temp:trim()
            if temp ~= "" then
              table_insert(lines, "|cff999999R" .. self.round .. "|r " .. temp)
            end
          end
        end
      end
      table_wipe(combat)

      temp = ""
      local a, b = switch[1], switch[2]
      if a and b then
        temp = "|cff55FF55" .. a .. "|r vs |cffFF5555" .. b .. "|r"
      elseif a then
        temp = "|cff55FF55" .. a .. " joins the battle!|r"
      elseif b then
        temp = "|cffFF5555" .. b .. " joins the battle!|r"
      end
      if temp ~= "" then
        print("|cff999999R" .. self.round .. "|r " .. temp)
      end

      for _, line in ipairs(lines) do
        print(line)
      end

      for i, data in ipairs({trap, death}) do
        for team, value in pairs(data) do
          if i == 1 then
            if value[2] == TRAP_HIT then -- team == MINE and "55FF55" or "FF5555"
              print("|cff999999R" .. self.round .. "|r " .. value[1] .. " was trapped!")
            elseif value[2] == TRAP_MISS then
              print("|cff999999R" .. self.round .. "|r " .. value[1] .. " avoided the trap!")
            end
          elseif i == 2 then
            print("|cff999999R" .. self.round .. "|r |cff" .. (team == MINE and "55FF55" or "FF5555") .. value .. " has died.|r")
          end
        end
      end
    end,
  }

  for i, matcher in ipairs(petBattle.matches) do
    matcher[1] = addonData:FormatMatcher(matcher[1], "(.+)")
    for j, flag in ipairs(matcher[2]) do
      if flag == FLAG_LEVEL or flag == FLAG_NUMBER or flag == FLAG_ROUND then
        matcher[2][j] = "number"
      elseif flag == FLAG_TEAM then
        matcher[2][j] = "team"
      elseif flag == FLAG_CSW then
        matcher[2][j] = "csw"
      else
        matcher[2][j] = ""
      end
    end
    matcher[1] = "^" .. addonData:PatternFlags(matcher[1], "(.+)", matcher[2]) .. "$"
    petBattle.matches[i] = matcher
  end
end

function module:Enable()
  if not module.IsEnabled then
    module.IsEnabled = 1
  else
    return
  end

  ChatFrame_AddMessageEventFilter("CHAT_MSG_PET_BATTLE_COMBAT_LOG", ChatFilter)
  ChatFrame_AddMessageEventFilter("CHAT_MSG_PET_BATTLE_INFO", ChatFilter)

  module:RegisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
  module:RegisterEvent("CHAT_MSG_PET_BATTLE_INFO")
  module:RegisterEvent("PET_BATTLE_CLOSE")
  module:RegisterEvent("PET_BATTLE_FINAL_ROUND")
  module:RegisterEvent("PET_BATTLE_OPENING_START")
  module:RegisterEvent("PET_BATTLE_OVER")
  module:RegisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
end

function module:Disable()
  if module.IsEnabled then
    module.IsEnabled = nil
  else
    return
  end

  ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PET_BATTLE_COMBAT_LOG", ChatFilter)
  ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PET_BATTLE_INFO", ChatFilter)

  module:UnregisterEvent("CHAT_MSG_PET_BATTLE_COMBAT_LOG")
  module:UnregisterEvent("CHAT_MSG_PET_BATTLE_INFO")
  module:UnregisterEvent("PET_BATTLE_CLOSE")
  module:UnregisterEvent("PET_BATTLE_FINAL_ROUND")
  module:UnregisterEvent("PET_BATTLE_OPENING_START")
  module:UnregisterEvent("PET_BATTLE_OVER")
  module:UnregisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
end

function module:CHAT_MSG_PET_BATTLE_COMBAT_LOG(_, message)
  petBattle:CombatLog(message)
end

function module:CHAT_MSG_PET_BATTLE_INFO(_, message)
  petBattle:CombatLog(message)
end

function module:PET_BATTLE_CLOSE()
  petBattle.round = petBattle.round - 1 -- fix a issue if printing now (new round fires once too many)
  petBattle:PrintRoundSummary() -- any leftovers are printed now
  petBattle:EndCombat() -- fires twice due to double events, use close for the real ending, over is fired right after the last round ends
end

function module:PET_BATTLE_FINAL_ROUND(_, result)
  petBattle.finalRound = result
end

module.PET_BATTLE_OVER = module.PET_BATTLE_CLOSE

function module:PET_BATTLE_OPENING_START()
  petBattle:NewRound(true)
end

function module:PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE(_, message)
  petBattle:PrintRoundSummary(tonumber(message) == 0)
  petBattle:NewRound()
end

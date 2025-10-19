-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--             Boss Award Functions
--
--      Function to detect, qualify and award boss kills
--
-- API Documentation:
-- QDKP2_BossKilled(boss): This should be called whenever a boss mob is killed. It's bulletproof aganist double calls.
-- QDKP2_GetBossAward(boss,[zone]): returns the award for killing <boss> in the instance <zone>. <zone> is set to GetRealZoneText() if not provided.
-- QDKP2_BossBonusSet(todo) -- Activate/deactivate the boss award. todo can be 'on', 'off' or 'toggle'
-- QDKP2_IsInBossTable(boss) -- retruns true if boss is in the boss award table

----------- Boss Kill ----------------------

local boss_translator = {}
boss_translator["Archavon the Stone Watcher"] = "Archavon"
boss_translator["Emalon the Storm Watcher"] = "Emalon"
boss_translator["Koralon the Flame Watcher"] = "Koralon"
boss_translator["Toravon the Ice Watcher"] = "Toravon"
boss_translator["Halion the Twilight Destroyer"] = "Halion"
boss_translator["Халион Сумеречный Разрушитель"] = "Halion"
boss_translator["Halion, the Twilight Destroyer"] = "Halion"
boss_translator["Халион, Сумеречный Разрушитель"] = "Halion"
boss_translator["Халион"] = "Halion"
boss_translator["Боевой корабль"] = "Icecrown Gunship Battle"
boss_translator["Бой на кораблях"] = "Icecrown Gunship Battle"
boss_translator["Gunship Battle"] = "Icecrown Gunship Battle"
boss_translator["The Skybreaker"] = "Icecrown Gunship Battle"
boss_translator["Усмиритель небес"] = "Icecrown Gunship Battle"
boss_translator["Orgrim's Hammer"] = "Icecrown Gunship Battle"
boss_translator["Молот Оргрима"] = "Icecrown Gunship Battle"
boss_translator["Валь'киры-близнецы"] = "Val'kyr Twins"
boss_translator["Чудовища Нордскола"] = "Northrend Beasts"
boss_translator["Королева Лана'тель"] = "Blood-Queen Lana'thel"
boss_translator["Кровавая королева Лана'тель"] = "Blood-Queen Lana'thel"
boss_translator["Кровавый Совет"] = "Blood Prince Council"
boss_translator["Совет Принцев Крови"] = "Blood Prince Council"

-- Добавьте в начало файла (после boss_translator)
local specialBossHandlers = {
    -- Ульдуар
    ["Ходир"] = function()
        return not UnitExists("boss1") or UnitHealth("boss1") == 0
    end,
    ["Торим"] = function()
        return not UnitExists("boss1") and not UnitExists("boss2")
    end,
    ["Фрейя"] = function()
        local isFriendly = UnitIsFriend("player", "boss1")
        return isFriendly or not UnitExists("boss1")
    end,
    ["Мимирон"] = function()
        return not UnitExists("boss1")
    end,
    
    -- ЦЛК
    ["Icecrown Gunship Battle"] = function()
        -- АДАПТИРУЙТЕ: Проверьте как определяется завершение на вашем сервере
        return not UnitExists("boss1") or QDKP2_ShipBattleCompleted
    end,
    ["Валитрия Сноходица"] = function()
        -- АДАПТИРУЙТЕ: Проверьте механику исцеления
        return QDKP2_ValithriaHealed or not UnitExists("boss1")
    end
}

QDKP2_ShipBattleCompleted = false
QDKP2_ValithriaHealed = false

function QDKP2_BossKilled(boss)
    -- Добавьте проверку на особых боссов
    if specialBossHandlers[boss] then
        QDKP2_Debug(3, "Core", "Обнаружен особый босс: " .. boss)
        -- Для особых боссов используем специальную проверку
        if not QDKP2_CheckSpecialBoss(boss) then
            QDKP2_Debug(2, "Core", "Особый босс " .. boss .. " еще не побежден")
            return
        end
    end
    -- called mainly by event, triggers a boss award if <boss> is in QDKP2_Bosses table.
    -- uses libBabble-Bosses for locales.
    QDKP2_Debug(3, "Core", boss .. " has died")
    if not QDKP2_ManagementMode() then
        QDKP2_Debug(3, "Core", "Quitting Boss award because you aren't in management mode")
        return
    end
    if not boss or type(boss) ~= 'string' then
        QDKP2_Debug(1, "Core", "Calling QDKP2_BossKilled with invalid boss: " .. tostring(boss))
        return
    end

    boss = boss_translator[boss] or boss

    if QDKP2_BossKilledTime and time() - QDKP2_BossKilledTime < 60 then
        --this sets a 1 minute "cooldown" between boss awards to avoid multiple awards
        --coming for various sources (DBM, BigWigs or simple slain detector)
        QDKP2_Debug(2, "Core", "Got " .. boss .. " kill trigger, but BossKill is in cooldown.")
        return
    else
        QDKP2_BossKilledTime = time()
    end

    local award = QDKP2_GetBossAward(boss)
	QDKP2_Debug(2, "Core", boss .. " award is "..tostring(award).." DKP")

    if award then
        QDKP2log_Entry("RAID", boss, QDKP2LOG_BOSS)
        if QDKP2_AutoBossEarn then
            --if the Boss Award is on
            local mess = string.gsub(QDKP2_LOC_BossKill, '$BOSS', boss)
            QDKP2_Msg(QDKP2_COLOR_BLUE .. mess)
            local reason = string.gsub(QDKP2_LOC_Kill, '$BOSS', boss)
            QDKP2_RaidAward(award, reason) --give DKP to the raid
        end
        if QDKP2_PROMPT_AWDS and not QDKP2_DetectBids then
            QDKP2_AskUser(QDKP2_LOC_WinDetect_Q, QDKP2_DetectBidSet, 'on')
        end
    end
    QDKP2_Events:Fire("DATA_UPDATED", "log")
end

function QDKP2_GetBossAward(boss, zone)
    if not boss or type(boss) ~= 'string' then
        QDKP2_Debug(1, "Core", "Calling QDKP2_BossKilled with invalid boss: " .. tostring(boss))
        return
    end

    local award
    local DKPType = "DKP_" .. QDKP2_GetInstanceDifficulty()
    zone = zone or GetRealZoneText()
    local zoneEng = QDKP2zoneEnglish[zone] or zone
    zone = string.lower(zone)
    zoneEng = string.lower(zoneEng)

    --searching for specific boss award
    award = QDKP2_IsInBossTable(boss, DKPType)
    if award then
        QDKP2_Debug(2, "Core", "Specific DKP award for " .. boss .. "(" .. DKPType .. ") is " .. tostring(award))
        return award
    end

    --searching for default award for instance
    for i, InstanceDKP in ipairs(QDKP2_Instances) do
        local DKPzone = string.lower(InstanceDKP.name or '-')
        if DKPzone == zone or DKPzone == zoneEng then
            award = InstanceDKP[DKPType]
            QDKP2_Debug(2, "Core", "Instance default DKP award for " .. boss .. "(" .. DKPType .. ") is " .. tostring(award))
            return award
        end
    end
end

function QDKP2_IsInBossTable(boss, DKPType)
    local DKPType = DKPType or "DKP_" .. QDKP2_GetInstanceDifficulty()
    boss = boss_translator[boss] or boss
    local bossEng = QDKP2bossEnglish[boss] or boss
    boss = string.lower(boss)
    bossEng = string.lower(boss_translator[bossEng] or bossEng)
    for i, BossDKP in ipairs(QDKP2_Bosses) do
        local DKPboss = string.lower(BossDKP.name or '-')
        if DKPboss == boss or DKPboss == bossEng then
            return BossDKP[DKPType]
        end
    end
	QDKP2_Debug(2, "Core", tostring(boss) .. " (" .. tostring(bossEng) .. ") not found in QDKP2_Bosses")
end

function QDKP2_BossBonusSet(todo)
    if todo == "toggle" then
        if QDKP2_AutoBossEarn then
            QDKP2_BossBonusSet("off")
        else
            QDKP2_BossBonusSet("on")
        end
    elseif todo == "on" then
        QDKP2_AutoBossEarn = true
        QDKP2_Events:Fire("BOSSBONUS_ON")
        QDKP2_Msg(QDKP2_COLOR_YELLOW .. QDKP2_LOC_GUIBOSSAWARDON)
    elseif todo == "off" then
        QDKP2_AutoBossEarn = false
        QDKP2_Events:Fire("BOSSBONUS_OFF")
        QDKP2_Msg(QDKP2_COLOR_YELLOW .. QDKP2_LOC_GUIBOSSAWARDOFF)
    end
end

function QDKP2_ForceBossKill(bossName)
    QDKP2_Debug(2, "Core", "Принудительный вызов награды для босса: " .. bossName)
    QDKP2_BossKilled(bossName)
end

-- Добавьте в конец файла обработчик событий
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
eventFrame:RegisterEvent("ENCOUNTER_END")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_MONSTER_YELL" then
        local msg, sender = ...
        
        -- Бой на кораблях в ЦЛК
        if string.find(msg, "Наш корабль уничтожен") or 
           string.find(msg, "Корабль Орды") or
           string.find(msg, "Корабль Альянса") or
           string.find(msg, "Победа за") then
            QDKP2_ShipBattleCompleted = true
            QDKP2_Debug(2, "Core", "Бой на кораблях завершен! Вызываем награду.")
            QDKP2_BossKilled("Icecrown Gunship Battle")
        end
        
        -- Валитрия Сноходица - ОБНОВЛЕННЫЙ ТЕКСТ
        if string.find(msg, "Я ИЗЛЕЧИЛАСЬ!") and 
           (sender == "Валитрия Сноходица" or sender == "Valithria Dreamwalker") then
            QDKP2_ValithriaHealed = true
            QDKP2_Debug(2, "Core", "Валитрия исцелена! Вызываем награду.")
            QDKP2_BossKilled("Валитрия Сноходица")
        end
        
        -- Ходир (Ульдуар)
        if string.find(msg, "Спасибо") and sender == "Ходир" then
            QDKP2_Debug(2, "Core", "Ходир завершен! Вызываем награду.")
            QDKP2_BossKilled("Ходир")
        end
        
        -- Фрейя (Ульдуар)
        if string.find(msg, "Я свободна") and sender == "Фрейя" then
            QDKP2_Debug(2, "Core", "Фрейя завершена! Вызываем награду.")
            QDKP2_BossKilled("Фрейя")
        end
        
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        if success then
            QDKP2_Debug(2, "Core", "Энкаунтер завершен: " .. encounterName)
            -- Для некоторых боссов можно использовать событие завершения энкаунтера
            if specialBossHandlers[encounterName] then
                QDKP2_BossKilled(encounterName)
            end
        end
    end
end)

-- Функция сброса состояний
function QDKP2_ResetSpecialBosses()
    QDKP2_ShipBattleCompleted = false
    QDKP2_ValithriaHealed = false
    QDKP2_Debug(2, "Core", "Состояния особых боссов сброшены")
end


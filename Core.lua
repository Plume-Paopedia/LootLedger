-- LootLedger Core.lua
-- Initialisation principale et utilitaires de l'addon
-- Créé par Plume

LootLedger = LibStub and LibStub("AceAddon-3.0"):NewAddon("LootLedger") or {}

-- Structure de base de données par défaut
local defaultDB = {
    loots = {},
    currency = {},
    stats = {
        totalGained = 0,
        totalLost = 0,
        currentGold = 0
    },
    funStats = {
        spellsCast = 0,
        damageDealt = 0,
        damageTaken = 0,
        healingDone = 0,
        mobsKilled = 0,
        deaths = 0,
        manaSpent = 0,
        sessionStart = 0,
        -- Nouvelles stats pour le DPS
        combatTime = 0,
        combatSessions = 0,
        firstCombatAction = 0,
        lastCombatAction = 0,
        longestCombat = 0,
        totalCombats = 0
    }
}

-- Initialiser l'addon
function LootLedger:OnInitialize()
    -- Initialiser les variables sauvegardées
    if not LootLedgerDB then
        LootLedgerDB = {}
    end
    
    -- Obtenir la clé spécifique au personnage
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local characterKey = playerName .. "-" .. realmName
    
    -- Initialiser les données spécifiques au personnage
    if not LootLedgerDB[characterKey] then
        LootLedgerDB[characterKey] = {}
    end
    
    -- Fusionner avec les valeurs par défaut pour ce personnage
    for key, value in pairs(defaultDB) do
        if not LootLedgerDB[characterKey][key] then
            LootLedgerDB[characterKey][key] = {}
            for subKey, subValue in pairs(value) do
                LootLedgerDB[characterKey][key][subKey] = subValue
            end
        else
            -- S'assurer que tous les champs funStats existent (pour les personnages existants)
            if key == "funStats" and type(value) == "table" then
                for subKey, subValue in pairs(value) do
                    if LootLedgerDB[characterKey][key][subKey] == nil then
                        LootLedgerDB[characterKey][key][subKey] = subValue
                    end
                end
            end
        end
    end
    
    self.db = LootLedgerDB[characterKey]
    self.characterKey = characterKey
    
    -- Initialiser l'or actuel
    if not self.db.stats.currentGold or self.db.stats.currentGold == 0 then
        self.db.stats.currentGold = GetMoney()
    end
    
    -- Initialiser l'heure de début de session
    if not self.db.funStats.sessionStart or self.db.funStats.sessionStart == 0 then
        self.db.funStats.sessionStart = time()
    end
    
    -- Enregistrer les commandes slash
    self:RegisterSlashCommands()
    
    print("|cff00ff00LootLedger|r v1.0 chargé par |cffFFD700Plume|r. Utilisez /ll pour ouvrir l'interface.")
end

-- Enregistrer les commandes slash
function LootLedger:RegisterSlashCommands()
    SLASH_LOOTLEDGER1 = "/ll"
    SLASH_LOOTLEDGER2 = "/lootledger"
    
    SlashCmdList["LOOTLEDGER"] = function(msg)
        msg = string.lower(string.trim(msg or ""))
        
        if msg == "clear" or msg == "effacer" then
            self:ClearData()
        elseif msg == "stats" or msg == "statistiques" then
            self:ShowStats()
        elseif msg == "allchars" or msg == "touspersos" then
            self:ShowAllCharacterStats()
        elseif msg == "testkill" or msg == "testtuer" then
            self:TestKillCounter()
        elseif msg == "testdps" then
            self:TestDPSCalculation()
        elseif msg == "debug" then
            self:ShowDebugInfo()
        else
            self:ToggleUI()
        end
    end
end

-- Effacer toutes les données
function LootLedger:ClearData()
    StaticPopupDialogs["LOOTLEDGER_CLEAR_CONFIRM"] = {
        text = "Êtes-vous sûr de vouloir effacer toutes les données LootLedger pour ce personnage ?",
        button1 = "Oui",
        button2 = "Non",
        OnAccept = function()
            -- Effacer toutes les données pour le personnage actuel
            LootLedgerDB[LootLedger.characterKey].loots = {}
            LootLedgerDB[LootLedger.characterKey].currency = {}
            LootLedgerDB[LootLedger.characterKey].stats = {
                totalGained = 0,
                totalLost = 0,
                currentGold = GetMoney()
            }
            LootLedgerDB[LootLedger.characterKey].funStats = {
                spellsCast = 0,
                damageDealt = 0,
                damageTaken = 0,
                healingDone = 0,
                mobsKilled = 0,
                deaths = 0,
                manaSpent = 0,
                sessionStart = time(),
                combatTime = 0,
                combatSessions = 0,
                firstCombatAction = 0,
                lastCombatAction = 0,
                longestCombat = 0,
                totalCombats = 0
            }
            
            -- Mettre à jour la référence locale
            LootLedger.db = LootLedgerDB[LootLedger.characterKey]
            
            print("|cff00ff00LootLedger:|r Toutes les données effacées pour ce personnage.")
            if LootLedger.UpdateUI then
                LootLedger:UpdateUI()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("LOOTLEDGER_CLEAR_CONFIRM")
end

-- Afficher les statistiques dans le chat
function LootLedger:ShowStats()
    local current = self.db.stats.currentGold
    local gained = self.db.stats.totalGained
    local lost = self.db.stats.totalLost
    local playerName = UnitName("player")
    
    print("|cff00ff00Statistiques LootLedger pour " .. playerName .. ":|r")
    print(string.format("Or actuel : |cffffff00%s|r", self:FormatMoney(current)))
    print(string.format("Total gagné : |cff00ff00+%s|r", self:FormatMoney(gained)))
    print(string.format("Total perdu : |cffff0000-%s|r", self:FormatMoney(lost)))
    print(string.format("Changement net : %s", gained > lost and "|cff00ff00+" or "|cffff0000") .. self:FormatMoney(math.abs(gained - lost)) .. "|r")
    print(string.format("Loots enregistrés : |cff00ddff%d|r", #self.db.loots))
    print(string.format("Transactions de devises : |cff00ddff%d|r", #self.db.currency))
end

-- Afficher les statistiques pour tous les personnages
function LootLedger:ShowAllCharacterStats()
    print("|cff00ff00LootLedger - Tous les personnages :|r")
    
    local totalGold = 0
    local totalGained = 0
    local totalLost = 0
    local characterCount = 0
    
    for characterKey, data in pairs(LootLedgerDB) do
        if type(data) == "table" and data.stats then
            characterCount = characterCount + 1
            local characterName = characterKey:match("^([^%-]+)")
            local current = data.stats.currentGold or 0
            local gained = data.stats.totalGained or 0
            local lost = data.stats.totalLost or 0
            
            totalGold = totalGold + current
            totalGained = totalGained + gained
            totalLost = totalLost + lost
            
            print(string.format("|cffFFD700%s:|r %s (Gagné : +%s, Perdu : -%s)", 
                characterName, 
                self:FormatMoney(current),
                self:FormatMoney(gained),
                self:FormatMoney(lost)
            ))
        end
    end
    
    if characterCount > 1 then
        print("|cff00ff00Total pour tous les personnages :|r")
        print(string.format("Or total : |cffffff00%s|r", self:FormatMoney(totalGold)))
        print(string.format("Total gagné : |cff00ff00+%s|r", self:FormatMoney(totalGained)))
        print(string.format("Total perdu : |cffff0000-%s|r", self:FormatMoney(totalLost)))
    elseif characterCount == 0 then
        print("|cffff0000Aucune donnée de personnage trouvée.|r")
    end
end

-- Test du compteur de tués (pour le débogage)
function LootLedger:TestKillCounter()
    if self.db and self.db.funStats then
        self.db.funStats.mobsKilled = self.db.funStats.mobsKilled + 1
        print("|cff00ff00LootLedger:|r Test de kill ajouté. Total des tués : " .. self.db.funStats.mobsKilled)
    else
        print("|cffff0000LootLedger:|r Erreur - aucune donnée funStats trouvée !")
    end
end

-- Afficher les informations de débogage
function LootLedger:ShowDebugInfo()
    print("|cff00ff00Informations de débogage LootLedger :|r")
    print("Base de données initialisée : " .. (self.db and "Oui" or "Non"))
    print("FunStats initialisées : " .. (self.db and self.db.funStats and "Oui" or "Non"))
    print("Nombre de cibles récentes : " .. (self.recentTargets and self:CountTable(self.recentTargets) or "0"))
    print("Événements du journal de combat enregistrés : Oui")
    print("Clé du personnage : " .. (self.characterKey or "Inconnue"))
    
    if self.db and self.db.funStats then
        print("Tués actuels : " .. (self.db.funStats.mobsKilled or 0))
        print("Dégâts infligés actuels : " .. (self.db.funStats.damageDealt or 0))
        print("Sorts lancés actuels : " .. (self.db.funStats.spellsCast or 0))
    end
end

-- Fonction utilitaire pour compter les entrées de table
function LootLedger:CountTable(t)
    local count = 0
    if t then
        for _ in pairs(t) do
            count = count + 1
        end
    end
    return count
end

-- Calculer les statistiques DPS améliorées
function LootLedger:CalculateDPSStats()
    if not self.db or not self.db.funStats then 
        return {
            overallDPS = 0,
            combatDPS = 0,
            avgCombatLength = 0,
            combatEfficiency = 0,
            totalCombatTime = 0,
            longestCombat = 0,
            totalCombats = 0
        }
    end
    
    local funStats = self.db.funStats
    local currentTime = time()
    
    -- Initialiser les champs manquants avec des valeurs par défaut
    local combatTime = funStats.combatTime or 0
    local combatSessions = funStats.combatSessions or 0
    local firstCombatAction = funStats.firstCombatAction or 0
    local damageDealt = funStats.damageDealt or 0
    local longestCombat = funStats.longestCombat or 0
    local totalCombats = funStats.totalCombats or 0
    
    -- Calculer différents types de DPS
    local overallDPS = 0
    local combatDPS = 0
    local avgCombatLength = 0
    local combatEfficiency = 0
    
    -- DPS global (dégâts par seconde depuis la première action de combat)
    if firstCombatAction > 0 then
        local totalTime = currentTime - firstCombatAction
        if totalTime > 0 then
            overallDPS = damageDealt / totalTime
        end
    end
    
    -- DPS de combat (dégâts par seconde pendant le combat réel)
    local totalCombatTime = combatTime
    
    -- Ajouter le temps de combat actuel si en combat
    if self.inCombat and self.combatStartTime then
        totalCombatTime = totalCombatTime + (currentTime - self.combatStartTime)
    end
    
    if totalCombatTime > 0 then
        combatDPS = damageDealt / totalCombatTime
    end
    
    -- Durée moyenne de combat
    if combatSessions > 0 then
        avgCombatLength = totalCombatTime / combatSessions
    end
    
    -- Efficacité de combat (pourcentage de temps passé en combat depuis la première action)
    if firstCombatAction > 0 then
        local totalActiveTime = currentTime - firstCombatAction
        if totalActiveTime > 0 then
            combatEfficiency = (totalCombatTime / totalActiveTime) * 100
        end
    end
    
    return {
        overallDPS = math.floor(overallDPS),
        combatDPS = math.floor(combatDPS),
        avgCombatLength = avgCombatLength,
        combatEfficiency = combatEfficiency,
        totalCombatTime = totalCombatTime,
        longestCombat = longestCombat,
        totalCombats = totalCombats
    }
end

-- Basculer la visibilité de l'interface
function LootLedger:ToggleUI()
    if self.mainFrame then
        if self.mainFrame:IsShown() then
            self.mainFrame:Hide()
        else
            self.mainFrame:Show()
        end
    else
        self:CreateUI()
        self.mainFrame:Show()
    end
end

-- Formater l'affichage de l'argent
function LootLedger:FormatMoney(amount)
    if not amount or amount == 0 then
        return "0c"
    end
    
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100
    
    local result = ""
    if gold > 0 then
        result = result .. gold .. "g"
    end
    if silver > 0 then
        result = result .. " " .. silver .. "s"
    end
    if copper > 0 or result == "" then
        result = result .. " " .. copper .. "c"
    end
    
    return string.trim(result)
end

-- Obtenir la couleur de qualité d'objet
function LootLedger:GetQualityColor(quality)
    local colors = {
        [0] = "|cff9d9d9d", -- Médiocre (Gris)
        [1] = "|cffffffff", -- Commun (Blanc)
        [2] = "|cff1eff00", -- Inhabituel (Vert)
        [3] = "|cff0070dd", -- Rare (Bleu)
        [4] = "|cffa335ee", -- Épique (Violet)
        [5] = "|cffff8000", -- Légendaire (Orange)
        [6] = "|cffe6cc80", -- Artefact (Orange clair)
    }
    return colors[quality] or "|cffffffff"
end

-- Obtenir le nom de la zone actuelle
function LootLedger:GetCurrentZone()
    return GetZoneText() or GetMinimapZoneText() or "Inconnue"
end

-- Formater l'horodatage
function LootLedger:FormatTimestamp(timestamp)
    return date("%m/%d %H:%M", timestamp)
end

-- Test du calcul DPS avec sortie de débogage
function LootLedger:TestDPSCalculation()
    print("|cff00ff00Test DPS LootLedger :|r")
    
    local stats = self:CalculateDPSStats()
    print("DPS global : " .. stats.overallDPS)
    print("DPS de combat : " .. stats.combatDPS)
    print("Temps de combat total : " .. stats.totalCombatTime .. "s")
    print("Durée moyenne de combat : " .. string.format("%.1f", stats.avgCombatLength) .. "s")
    print("Efficacité de combat : " .. string.format("%.1f", stats.combatEfficiency) .. "%")
    
    if self.db and self.db.funStats then
        print("Dégâts bruts infligés : " .. (self.db.funStats.damageDealt or 0))
        print("Sessions de combat : " .. (self.db.funStats.combatSessions or 0))
        print("Temps de combat : " .. (self.db.funStats.combatTime or 0))
        print("Début de session : " .. (self.db.funStats.sessionStartTime or 0))
    end
end

-- Initialiser au chargement de l'addon
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "LootLedger" then
        LootLedger:OnInitialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
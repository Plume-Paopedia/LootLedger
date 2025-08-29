-- LootLedger Events.lua
-- Gestion des événements pour le suivi des loots et devises
-- Créé par Plume

local LootLedger = LootLedger

-- Cadre d'événement
local eventFrame = CreateFrame("Frame")

-- Suivre le montant d'argent précédent pour la détection des changements
local previousMoney = 0

-- Initialiser les événements
function LootLedger:InitializeEvents()
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("LOOT_CLOSED")
    eventFrame:RegisterEvent("PLAYER_MONEY")
    eventFrame:RegisterEvent("MERCHANT_SHOW")
    eventFrame:RegisterEvent("BAG_UPDATE")
    
    -- Événements de statistiques amusantes
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_DEAD")
    eventFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN") -- Détection alternative des tués
    
    -- Événements de suivi de combat
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entrer en combat
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Sortir du combat
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        LootLedger:HandleEvent(event, ...)
    end)
    
    -- Initialiser le suivi d'argent
    previousMoney = GetMoney()
    
    -- Initialiser le suivi des cibles récentes
    self.recentTargets = {}
    
    -- Initialiser le suivi de combat
    self.combatStartTime = nil
    self.inCombat = false
    
    -- Créer un minuteur de nettoyage pour les anciennes cibles (nettoyage toutes les 30 secondes)
    local cleanupTimer = C_Timer.NewTicker(30, function()
        LootLedger:CleanupOldTargets()
    end)
end

-- Gestionnaire principal d'événements
function LootLedger:HandleEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:OnPlayerEnteringWorld()
    elseif event == "CHAT_MSG_LOOT" then
        self:OnChatMsgLoot(...)
    elseif event == "LOOT_OPENED" then
        self:OnLootOpened()
    elseif event == "LOOT_CLOSED" then
        self:OnLootClosed()
    elseif event == "PLAYER_MONEY" then
        self:OnPlayerMoney()
    elseif event == "MERCHANT_SHOW" then
        self:OnMerchantShow()
    elseif event == "BAG_UPDATE" then
        self:OnBagUpdate(...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:OnSpellCast(...)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:OnCombatLog()
    elseif event == "PLAYER_DEAD" then
        self:OnPlayerDead()
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        self:OnXPGain(...)
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:OnEnterCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:OnLeaveCombat()
    end
end

-- Joueur entrant dans le monde
function LootLedger:OnPlayerEnteringWorld()
    -- Mettre à jour l'argent actuel
    local currentMoney = GetMoney()
    if self.db and self.db.stats then
        self.db.stats.currentGold = currentMoney
    end
    previousMoney = currentMoney
end

-- Gestionnaire de message de loot du chat
function LootLedger:OnChatMsgLoot(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid)
    -- Analyser les messages de loot
    local itemLink, quantity = self:ParseLootMessage(text)
    if itemLink then
        self:RecordLoot(itemLink, quantity or 1, "Chat")
    end
end

-- Analyser le message de loot du chat
function LootLedger:ParseLootMessage(text)
    if not text then return nil, nil end
    
    -- Motif pour "Vous recevez le butin : [Objet] x2"
    local itemLink, quantityStr = text:match("You receive loot: (|c%x+|Hitem:[^|]+|h%[.-%]|h|r)%.?%s*x?(%d*)")
    if itemLink then
        local quantity = tonumber(quantityStr) or 1
        return itemLink, quantity
    end
    
    -- Motif pour "Vous recevez l'objet : [Objet]"
    itemLink = text:match("You receive item: (|c%x+|Hitem:[^|]+|h%[.-%]|h|r)")
    if itemLink then
        return itemLink, 1
    end
    
    -- Motif pour "[Joueur] reçoit le butin : [Objet]"
    itemLink, quantityStr = text:match("receives loot: (|c%x+|Hitem:[^|]+|h%[.-%]|h|r)%.?%s*x?(%d*)")
    if itemLink and UnitName("player") then
        local playerName = text:match("^([^%s]+)")
        if playerName == UnitName("player") then
            local quantity = tonumber(quantityStr) or 1
            return itemLink, quantity
        end
    end
    
    return nil, nil
end

-- Fenêtre de loot ouverte
function LootLedger:OnLootOpened()
    -- Suivre les objets de la fenêtre de loot
    local numItems = GetNumLootItems()
    for i = 1, numItems do
        local itemLink = GetLootSlotLink(i)
        if itemLink then
            local _, _, quantity = GetLootSlotInfo(i)
            self:RecordLoot(itemLink, quantity or 1, "Direct")
        end
    end
end

-- Fenêtre de loot fermée
function LootLedger:OnLootClosed()
    -- Rien de spécifique à faire quand le loot se ferme
end

-- Argent du joueur changé
function LootLedger:OnPlayerMoney()
    local currentMoney = GetMoney()
    local difference = currentMoney - previousMoney
    
    if difference ~= 0 then
        self:RecordCurrencyChange(previousMoney, currentMoney, difference)
    end
    
    previousMoney = currentMoney
end

-- Fenêtre marchand affichée
function LootLedger:OnMerchantShow()
    -- Mettre à jour l'argent précédent quand le marchand s'ouvre
    previousMoney = GetMoney()
end

-- Gestionnaire de mise à jour de sac
function LootLedger:OnBagUpdate(bagID)
    -- Nous pourrions suivre les changements de sac ici, mais les messages de chat sont plus fiables
    -- Ceci est conservé pour d'éventuelles améliorations futures
end

-- Enregistrer un objet de loot
function LootLedger:RecordLoot(itemLink, quantity, source)
    if not itemLink or not self.db then return end
    
    -- Extraire les informations de l'objet
    local itemName, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
          itemEquipLoc, itemTexture = GetItemInfo(itemLink)
    
    -- Obtenir l'ID de l'objet depuis le lien
    local itemID = itemLink:match("item:(%d+)")
    
    local lootEntry = {
        itemLink = itemLink,
        itemName = itemName or "Objet Inconnu",
        itemID = itemID,
        quality = itemRarity or 1,
        quantity = quantity,
        zone = self:GetCurrentZone(),
        timestamp = time(),
        source = source or "Inconnu"
    }
    
    table.insert(self.db.loots, lootEntry)
    
    -- Limiter l'historique aux 1000 dernières entrées
    if #self.db.loots > 1000 then
        table.remove(self.db.loots, 1)
    end
    
    -- Mettre à jour l'interface si visible
    if self.UpdateUI then
        self:UpdateUI()
    end
end

-- Enregistrer un changement de devise
function LootLedger:RecordCurrencyChange(oldAmount, newAmount, difference)
    if not self.db then return end
    
    local currencyEntry = {
        oldAmount = oldAmount,
        newAmount = newAmount,
        difference = difference,
        timestamp = time(),
        zone = self:GetCurrentZone()
    }
    
    table.insert(self.db.currency, currencyEntry)
    
    -- Mettre à jour les statistiques
    if difference > 0 then
        self.db.stats.totalGained = self.db.stats.totalGained + difference
    else
        self.db.stats.totalLost = self.db.stats.totalLost + math.abs(difference)
    end
    
    self.db.stats.currentGold = newAmount
    
    -- Limiter l'historique aux 1000 dernières entrées
    if #self.db.currency > 1000 then
        table.remove(self.db.currency, 1)
    end
    
    -- Mettre à jour l'interface si visible
    if self.UpdateUI then
        self:UpdateUI()
    end
end

-- Gestionnaire de lancement de sort
function LootLedger:OnSpellCast(unitTarget, castGUID, spellID)
    if unitTarget == "player" and self.db and self.db.funStats then
        self.db.funStats.spellsCast = self.db.funStats.spellsCast + 1
    end
end

-- Gestionnaire de journal de combat pour le suivi des dégâts/soins
function LootLedger:OnCombatLog()
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    if not self.db or not self.db.funStats then return end
    
    local playerGUID = UnitGUID("player")
    
    -- Dégâts infligés par le joueur (dégâts de sort)
    if sourceGUID == playerGUID and subevent == "SPELL_DAMAGE" then
        local spellId, spellName, spellSchool, amount = select(12, CombatLogGetCurrentEventInfo())
        if amount then
            self.db.funStats.damageDealt = self.db.funStats.damageDealt + amount
        end
    end
    
    -- Dégâts infligés par le joueur (dégâts de mêlée)
    if sourceGUID == playerGUID and subevent == "SWING_DAMAGE" then
        local amount = select(12, CombatLogGetCurrentEventInfo())
        if amount then
            self.db.funStats.damageDealt = self.db.funStats.damageDealt + amount
        end
    end
    
    -- Dégâts subis par le joueur (dégâts de sort)
    if destGUID == playerGUID and subevent == "SPELL_DAMAGE" then
        local spellId, spellName, spellSchool, amount = select(12, CombatLogGetCurrentEventInfo())
        if amount then
            self.db.funStats.damageTaken = self.db.funStats.damageTaken + amount
        end
    end
    
    -- Dégâts subis par le joueur (dégâts de mêlée)
    if destGUID == playerGUID and subevent == "SWING_DAMAGE" then
        local amount = select(12, CombatLogGetCurrentEventInfo())
        if amount then
            self.db.funStats.damageTaken = self.db.funStats.damageTaken + amount
        end
    end
    
    -- Soins effectués par le joueur
    if sourceGUID == playerGUID and subevent == "SPELL_HEAL" then
        local spellId, spellName, spellSchool, amount = select(12, CombatLogGetCurrentEventInfo())
        if amount then
            self.db.funStats.healingDone = self.db.funStats.healingDone + amount
        end
    end
    
    -- Créature tuée par le joueur - Nous devons suivre quand les unités meurent et si le joueur était en combat avec elles
    if subevent == "UNIT_DIED" and destGUID and destName then
        -- Vérifier si cette unité a été récemment endommagée par le joueur
        if self.recentTargets and self.recentTargets[destGUID] then
            self.db.funStats.mobsKilled = self.db.funStats.mobsKilled + 1
            -- Retirer des cibles récentes car elle est maintenant morte
            self.recentTargets[destGUID] = nil
        end
    end
    
    -- Suivre les unités que le joueur a récemment endommagées (pour le crédit de kill)
    if sourceGUID == playerGUID and (subevent == "SPELL_DAMAGE" or subevent == "SWING_DAMAGE") and destGUID then
        if not self.recentTargets then
            self.recentTargets = {}
        end
        -- Marquer cette unité comme récemment endommagée par le joueur (avec horodatage)
        self.recentTargets[destGUID] = time()
    end
    
    -- Suivre l'utilisation de mana lors du lancement de sorts
    if sourceGUID == playerGUID and (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_HEAL") then
        local spellId = select(12, CombatLogGetCurrentEventInfo())
        if spellId then
            -- Estimer le coût de mana (approche simplifiée)
            local manaCost = self:GetSpellManaCost(spellId)
            if manaCost and manaCost > 0 then
                self.db.funStats.manaSpent = (self.db.funStats.manaSpent or 0) + manaCost
            end
        end
    end
end

-- Obtenir le coût de mana d'un sort (estimation simplifiée)
function LootLedger:GetSpellManaCost(spellId)
    -- Ceci est une estimation simplifiée car obtenir les coûts de mana exactes est complexe
    local spellName = GetSpellInfo(spellId)
    if not spellName then return 0 end
    
    -- Estimation de base basée sur le niveau du joueur et le type de sort
    local playerLevel = UnitLevel("player")
    local baseCost = math.max(1, playerLevel * 2)
    
    -- Différents types de sorts ont différents coûts
    if spellName:find("Heal") or spellName:find("Cure") or spellName:find("Soin") or spellName:find("Guérir") then
        return baseCost * 2 -- Les sorts de soin coûtent plus
    elseif spellName:find("Shield") or spellName:find("Armor") or spellName:find("Bouclier") or spellName:find("Armure") then
        return baseCost * 1.5 -- Sorts de buff
    else
        return baseCost -- Sorts de dégâts
    end
end

-- Gestionnaire de mort du joueur
function LootLedger:OnPlayerDead()
    if self.db and self.db.funStats then
        self.db.funStats.deaths = self.db.funStats.deaths + 1
    end
end

-- Gestionnaire de gain d'XP (méthode alternative de détection des tués)
function LootLedger:OnXPGain(text, ...)
    if not self.db or not self.db.funStats then return end
    
    -- Motif pour détecter le gain d'XP en tuant des créatures
    -- Exemples : "Vous gagnez 100 points d'expérience.", "You gain 100 experience."
    if text and (text:find("experience") or text:find("expérience")) and text:find("gain") then
        -- Compter seulement si c'est en tuant (pas pour compléter une quête)
        if not text:find("quest") and not text:find("quête") then
            self.db.funStats.mobsKilled = self.db.funStats.mobsKilled + 1
        end
    end
end

-- Gestionnaire d'entrée en combat
function LootLedger:OnEnterCombat()
    if not self.db or not self.db.funStats then return end
    
    -- Initialiser les nouveaux champs de combat s'ils n'existent pas
    if not self.db.funStats.combatTime then self.db.funStats.combatTime = 0 end
    if not self.db.funStats.combatSessions then self.db.funStats.combatSessions = 0 end
    if not self.db.funStats.firstCombatAction then self.db.funStats.firstCombatAction = 0 end
    if not self.db.funStats.lastCombatAction then self.db.funStats.lastCombatAction = 0 end
    if not self.db.funStats.longestCombat then self.db.funStats.longestCombat = 0 end
    if not self.db.funStats.totalCombats then self.db.funStats.totalCombats = 0 end
    
    self.inCombat = true
    self.combatStartTime = time()
    
    -- Suivre la première action de combat si pas définie
    if self.db.funStats.firstCombatAction == 0 then
        self.db.funStats.firstCombatAction = time()
    end
    
    self.db.funStats.totalCombats = self.db.funStats.totalCombats + 1
end

-- Gestionnaire de sortie de combat
function LootLedger:OnLeaveCombat()
    if not self.db or not self.db.funStats then return end
    
    -- Initialiser les nouveaux champs de combat s'ils n'existent pas
    if not self.db.funStats.combatTime then self.db.funStats.combatTime = 0 end
    if not self.db.funStats.combatSessions then self.db.funStats.combatSessions = 0 end
    if not self.db.funStats.longestCombat then self.db.funStats.longestCombat = 0 end
    if not self.db.funStats.lastCombatAction then self.db.funStats.lastCombatAction = 0 end
    
    if self.inCombat and self.combatStartTime then
        local combatDuration = time() - self.combatStartTime
        
        -- Ajouter au temps de combat total
        self.db.funStats.combatTime = self.db.funStats.combatTime + combatDuration
        self.db.funStats.combatSessions = self.db.funStats.combatSessions + 1
        
        -- Suivre le combat le plus long
        if combatDuration > self.db.funStats.longestCombat then
            self.db.funStats.longestCombat = combatDuration
        end
        
        -- Mettre à jour la dernière action de combat
        self.db.funStats.lastCombatAction = time()
    end
    
    self.inCombat = false
    self.combatStartTime = nil
end

-- Nettoyer les anciennes cibles (retirer les cibles non endommagées dans les 60 dernières secondes)
function LootLedger:CleanupOldTargets()
    if not self.recentTargets then return end
    
    local currentTime = time()
    local maxAge = 60 -- secondes
    
    for guid, timestamp in pairs(self.recentTargets) do
        if currentTime - timestamp > maxAge then
            self.recentTargets[guid] = nil
        end
    end
end

-- Initialiser les événements au chargement de l'addon
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "LootLedger" then
        LootLedger:InitializeEvents()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
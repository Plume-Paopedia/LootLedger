-- LootLedger UI.lua
-- Interface utilisateur pour l'addon LootLedger
-- Créé par Plume

local LootLedger = LootLedger

-- Constantes d'interface
local UI_WIDTH = 650
local UI_HEIGHT = 500
local TAB_HEIGHT = 25
local SCROLL_HEIGHT = 400
local BUTTON_HEIGHT = 20

-- Onglet actif actuel
local activeTab = "loots"

-- Créer le cadre d'interface principal
function LootLedger:CreateUI()
    if self.mainFrame then
        return
    end
    
    -- Cadre principal
    local frame = CreateFrame("Frame", "LootLedgerMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(UI_WIDTH, UI_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    
    self.mainFrame = frame
    
    -- Titre
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("LootLedger v1.0 par Plume")
    
    -- Bouton de fermeture
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    
    -- Créer les onglets
    self:CreateTabs()
    
    -- Créer la zone de contenu
    self:CreateContentArea()
    
    -- Créer les boutons
    self:CreateButtons()
    
    -- Mise à jour initiale de l'interface
    self:UpdateUI()
end

-- Créer les boutons d'onglets
function LootLedger:CreateTabs()
    local frame = self.mainFrame
    self.tabs = {}
    
    local tabs = {
        { key = "loots", text = "Butins" },
        { key = "currency", text = "Monnaie" },
        { key = "stats", text = "Statistiques" },
        { key = "funstats", text = "Stats Amusantes" }
    }
    
    for i, tab in ipairs(tabs) do
        local tabBtn = CreateFrame("Button", nil, frame)
        tabBtn:SetSize(90, TAB_HEIGHT)
        tabBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i-1) * 95, -45)
        
        -- Tab background
        tabBtn:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab-BGLeft")
        tabBtn:SetHighlightTexture("Interface\\ChatFrame\\ChatFrameTab-BGLeft")
        
        -- Texte d'onglet
        local tabText = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tabBtn, "CENTER")
        tabText:SetText(tab.text)
        
        tabBtn:SetScript("OnClick", function()
            self:SetActiveTab(tab.key)
        end)
        
        tabBtn.key = tab.key
        tabBtn.text = tabText
        self.tabs[tab.key] = tabBtn
    end
    
    -- Définir l'onglet actif initial
    self:SetActiveTab("loots")
end

-- Définir l'onglet actif
function LootLedger:SetActiveTab(tabKey)
    activeTab = tabKey
    
    -- Mettre à jour l'apparence des onglets
    for key, tab in pairs(self.tabs) do
        if key == tabKey then
            tab.text:SetTextColor(1, 1, 1)
            tab:SetAlpha(1)
        else
            tab.text:SetTextColor(0.7, 0.7, 0.7)
            tab:SetAlpha(0.7)
        end
    end
    
    -- Mettre à jour le contenu
    self:UpdateContent()
end

-- Créer la zone de contenu avec cadre de défilement
function LootLedger:CreateContentArea()
    local frame = self.mainFrame
    
    -- Cadre de contenu
    local contentFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -75)
    contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 40)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentFrame:SetBackdropColor(0, 0, 0, 0.5)
    
    -- Cadre de défilement
    local scrollFrame = CreateFrame("ScrollFrame", "LootLedgerScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -26, 8)
    
    -- Contenu du défilement
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(UI_WIDTH - 60, SCROLL_HEIGHT)
    scrollFrame:SetScrollChild(scrollContent)
    
    self.contentFrame = contentFrame
    self.scrollFrame = scrollFrame
    self.scrollContent = scrollContent
end

-- Créer les boutons du bas
function LootLedger:CreateButtons()
    local frame = self.mainFrame
    
    -- Bouton effacer
    local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clearBtn:SetSize(80, BUTTON_HEIGHT)
    clearBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 10)
    clearBtn:SetText("Effacer")
    clearBtn:SetScript("OnClick", function()
        self:ClearData()
    end)
    
    -- Bouton exporter
    local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    exportBtn:SetSize(80, BUTTON_HEIGHT)
    exportBtn:SetPoint("BOTTOMLEFT", clearBtn, "BOTTOMRIGHT", 10, 0)
    exportBtn:SetText("Exporter")
    exportBtn:SetScript("OnClick", function()
        self:ExportData()
    end)
    
    -- Bouton statistiques
    local statsBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    statsBtn:SetSize(80, BUTTON_HEIGHT)
    statsBtn:SetPoint("BOTTOMLEFT", exportBtn, "BOTTOMRIGHT", 10, 0)
    statsBtn:SetText("Stats")
    statsBtn:SetScript("OnClick", function()
        self:ShowStats()
    end)
    
    -- Bouton fermer
    local closeBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    closeBtn:SetSize(80, BUTTON_HEIGHT)
    closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 10)
    closeBtn:SetText("Fermer")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
end

-- Mettre à jour le contenu de l'interface
function LootLedger:UpdateUI()
    if not self.mainFrame or not self.mainFrame:IsShown() then
        return
    end
    
    self:UpdateContent()
end

-- Mettre à jour le contenu basé sur l'onglet actif
function LootLedger:UpdateContent()
    if not self.scrollContent then return end
    
    -- Effacer complètement le contenu existant
    self:ClearScrollContent()
    
    if activeTab == "loots" then
        self:CreateLootsContent()
    elseif activeTab == "currency" then
        self:CreateCurrencyContent()
    elseif activeTab == "stats" then
        self:CreateStatsContent()
    elseif activeTab == "funstats" then
        self:CreateFunStatsContent()
    end
end

-- Fonction utilitaire pour effacer complètement le contenu du défilement
function LootLedger:ClearScrollContent()
    if not self.scrollContent then return end
    
    -- Masquer et supprimer tous les cadres enfants
    local children = {self.scrollContent:GetChildren()}
    for i = 1, #children do
        children[i]:Hide()
        children[i]:ClearAllPoints()
        children[i]:SetParent(nil)
    end
    
    -- Masquer et supprimer toutes les chaînes de police
    local regions = {self.scrollContent:GetRegions()}
    for i = 1, #regions do
        if regions[i]:GetObjectType() == "FontString" then
            regions[i]:Hide()
            regions[i]:ClearAllPoints()
            regions[i]:SetParent(nil)
        end
    end
end

-- Create loots tab content avec design ultra-moderne et pagination
function LootLedger:CreateLootsContent()
    if not self.db.loots or #self.db.loots == 0 then
        self:CreateEmptyLootsState()
        return
    end
    
    -- Initialize pagination if not exists
    if not self.lootPagination then
        self.lootPagination = {
            currentPage = 1,
            itemsPerPage = 8,
            totalItems = 0
        }
    end
    
    local yOffset = -15
    
    -- Header ultra-moderne avec glassmorphism
    local headerFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    headerFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    headerFrame:SetSize(UI_WIDTH - 80, 70)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    headerFrame:SetBackdropColor(0.08, 0.12, 0.20, 0.85)
    headerFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.9)
    
    -- Icône trésor avec effet lumineux
    local treasureIcon = headerFrame:CreateTexture(nil, "ARTWORK")
    treasureIcon:SetSize(45, 45)
    treasureIcon:SetPoint("LEFT", headerFrame, "LEFT", 15, 0)
    treasureIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    
    -- Effet de lueur bleutée autour de l'icône
    local iconGlow = headerFrame:CreateTexture(nil, "BACKGROUND")
    iconGlow:SetSize(55, 55)
    iconGlow:SetPoint("CENTER", treasureIcon, "CENTER")
    iconGlow:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1")
    iconGlow:SetVertexColor(0.3, 0.5, 0.9, 0.6)
    
    -- Titre principal avec style moderne
    local title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", treasureIcon, "RIGHT", 15, 10)
    title:SetFont("Fonts\\MORPHEUS.TTF", 22, "OUTLINE")
    title:SetText("🎒 |cff4A9FFFHISTORIQUE DES LOOTS|r")
    
    -- Sous-titre avec informations en temps réel
    local subtitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("LEFT", treasureIcon, "RIGHT", 15, -12)
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
    local totalLoots = #self.db.loots
    subtitle:SetText("|cff888888Gestion avancée • " .. totalLoots .. " objets • Filtrage intelligent|r")
    
    yOffset = yOffset - 85
    
    -- Contrôles de filtrage ultra-modernes
    self:CreateModernLootFilters(yOffset)
    yOffset = yOffset - 70
    
    -- Zone de contenu principal avec pagination
    self:CreatePaginatedLootEntries(yOffset)
end

-- Créer l'état vide avec design moderne
function LootLedger:CreateEmptyLootsState()
    local emptyFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    emptyFrame:SetPoint("CENTER", self.scrollContent, "CENTER", 0, -50)
    emptyFrame:SetSize(400, 200)
    emptyFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    emptyFrame:SetBackdropColor(0.05, 0.08, 0.15, 0.9)
    emptyFrame:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.8)
    
    -- Icône vide élégante
    local emptyIcon = emptyFrame:CreateTexture(nil, "ARTWORK")
    emptyIcon:SetSize(64, 64)
    emptyIcon:SetPoint("TOP", emptyFrame, "TOP", 0, -30)
    emptyIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    emptyIcon:SetVertexColor(0.5, 0.6, 0.8, 0.7)
    
    -- Texte principal
    local emptyTitle = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    emptyTitle:SetPoint("TOP", emptyIcon, "BOTTOM", 0, -15)
    emptyTitle:SetFont("Fonts\\MORPHEUS.TTF", 16, "OUTLINE")
    emptyTitle:SetText("|cff6A9BFFAUCUN LOOT ENREGISTRÉ|r")
    
    -- Texte descriptif
    local emptyDesc = emptyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyDesc:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -10)
    emptyDesc:SetFont("Fonts\\FRIZQT__.TTF", 11)
    emptyDesc:SetText("|cff888888Commencez à farmer pour voir vos loots apparaître ici|r")
    
    self.scrollContent:SetHeight(300)
end

-- Créer les filtres modernes avec glassmorphism
function LootLedger:CreateModernLootFilters(yOffset)
    local filterFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    filterFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    filterFrame:SetSize(UI_WIDTH - 80, 60)
    filterFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    filterFrame:SetBackdropColor(0.06, 0.10, 0.18, 0.8)
    filterFrame:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.7)
    
    -- Label Filtres avec icône
    local filterLabel = filterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 12, -8)
    filterLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    filterLabel:SetText("🔍 |cff4A9BFFFilteres Avancés|r")
    
    -- Filtre qualité moderne
    local qualityBtn = CreateFrame("Button", nil, filterFrame, "UIPanelButtonTemplate")
    qualityBtn:SetSize(100, 25)
    qualityBtn:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 15, -25)
    qualityBtn:SetText("Toute Qualité")
    qualityBtn:SetScript("OnClick", function() self:ShowQualityFilterMenu(qualityBtn) end)
    
    -- Filtre zone moderne
    local zoneBtn = CreateFrame("Button", nil, filterFrame, "UIPanelButtonTemplate")
    zoneBtn:SetSize(100, 25)
    zoneBtn:SetPoint("LEFT", qualityBtn, "RIGHT", 10, 0)
    zoneBtn:SetText("Toute Zone")
    zoneBtn:SetScript("OnClick", function() self:ShowZoneFilterMenu(zoneBtn) end)
    
    -- Recherche moderne
    local searchBox = CreateFrame("EditBox", nil, filterFrame, "InputBoxTemplate")
    searchBox:SetSize(120, 25)
    searchBox:SetPoint("LEFT", zoneBtn, "RIGHT", 15, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("Rechercher...")
    searchBox:SetTextColor(0.5, 0.5, 0.5, 1)
    searchBox:SetScript("OnEditFocusGained", function()
        if searchBox:GetText() == "Rechercher..." then
            searchBox:SetText("")
            searchBox:SetTextColor(1, 1, 1, 1)
        end
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        if searchBox:GetText() == "" then
            searchBox:SetText("Rechercher...")
            searchBox:SetTextColor(0.5, 0.5, 0.5, 1)
        end
    end)
    searchBox:SetScript("OnTextChanged", function()
        if searchBox:GetText() ~= "Rechercher..." then
            self:FilterLootsBySearch(searchBox:GetText())
        end
    end)
    
    -- Bouton reset moderne
    local resetBtn = CreateFrame("Button", nil, filterFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(80, 25)
    resetBtn:SetPoint("RIGHT", filterFrame, "RIGHT", -15, -25)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        qualityBtn:SetText("Toute Qualité")
        zoneBtn:SetText("Toute Zone")
        searchBox:SetText("Rechercher...")
        searchBox:SetTextColor(0.5, 0.5, 0.5, 1)
        self.selectedQualityFilter = nil
        self.selectedZoneFilter = nil
        self.searchFilter = ""
        self:UpdateContent()
    end)
    
    -- Stocker les références
    self.modernLootFilters = {
        frame = filterFrame,
        qualityBtn = qualityBtn,
        zoneBtn = zoneBtn,
        searchBox = searchBox,
        resetBtn = resetBtn
    }
end

-- Créer les entrées de loot avec pagination moderne
function LootLedger:CreatePaginatedLootEntries(yOffset)
    local filteredLoots = self:GetFilteredLoots()
    local pagination = self.lootPagination
    pagination.totalItems = #filteredLoots
    
    -- Calculer les pages
    local totalPages = math.max(1, math.ceil(pagination.totalItems / pagination.itemsPerPage))
    pagination.currentPage = math.min(pagination.currentPage, totalPages)
    
    -- Contrôles de pagination en haut
    local paginationFrame = self:CreatePaginationControls(yOffset, pagination, totalPages)
    yOffset = yOffset - 45
    
    -- Zone de contenu des loots
    local contentFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    contentFrame:SetSize(UI_WIDTH - 80, 420)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    contentFrame:SetBackdropColor(0.02, 0.04, 0.08, 0.9)
    contentFrame:SetBackdropBorderColor(0.15, 0.25, 0.45, 0.8)
    
    -- Créer les entrées de la page actuelle
    local startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage + 1
    local endIndex = math.min(startIndex + pagination.itemsPerPage - 1, pagination.totalItems)
    
    local entryYOffset = -10
    for i = startIndex, endIndex do
        local loot = filteredLoots[i]
        if loot then
            self:CreateModernLootEntry(contentFrame, loot, entryYOffset, i)
            entryYOffset = entryYOffset - 50
        end
    end
    
    -- Message si aucun résultat
    if pagination.totalItems == 0 then
        local noResultsText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noResultsText:SetPoint("CENTER", contentFrame, "CENTER")
        noResultsText:SetFont("Fonts\\FRIZQT__.TTF", 14)
        noResultsText:SetText("|cff666666Aucun loot ne correspond aux filtres|r")
    end
    
    self.scrollContent:SetHeight(math.abs(yOffset) + 430)
end

-- Créer les contrôles de pagination ultra-modernes
function LootLedger:CreatePaginationControls(yOffset, pagination, totalPages)
    local paginationFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    paginationFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    paginationFrame:SetSize(UI_WIDTH - 80, 35)
    paginationFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    paginationFrame:SetBackdropColor(0.08, 0.12, 0.20, 0.9)
    paginationFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)
    
    -- Bouton première page
    local firstBtn = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
    firstBtn:SetSize(40, 25)
    firstBtn:SetPoint("LEFT", paginationFrame, "LEFT", 10, 0)
    firstBtn:SetText("≪")
    firstBtn:SetEnabled(pagination.currentPage > 1)
    firstBtn:SetScript("OnClick", function()
        pagination.currentPage = 1
        self:UpdateContent()
    end)
    
    -- Bouton page précédente
    local prevBtn = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
    prevBtn:SetSize(40, 25)
    prevBtn:SetPoint("LEFT", firstBtn, "RIGHT", 5, 0)
    prevBtn:SetText("‹")
    prevBtn:SetEnabled(pagination.currentPage > 1)
    prevBtn:SetScript("OnClick", function()
        pagination.currentPage = pagination.currentPage - 1
        self:UpdateContent()
    end)
    
    -- Informations de page
    local pageInfo = paginationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageInfo:SetPoint("CENTER", paginationFrame, "CENTER")
    pageInfo:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    pageInfo:SetText(string.format("|cff4A9BFFPage %d sur %d|r |cff888888(%d objets)|r", 
        pagination.currentPage, totalPages, pagination.totalItems))
    
    -- Bouton page suivante
    local nextBtn = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
    nextBtn:SetSize(40, 25)
    nextBtn:SetPoint("RIGHT", paginationFrame, "RIGHT", -55, 0)
    nextBtn:SetText("›")
    nextBtn:SetEnabled(pagination.currentPage < totalPages)
    nextBtn:SetScript("OnClick", function()
        pagination.currentPage = pagination.currentPage + 1
        self:UpdateContent()
    end)
    
    -- Bouton dernière page
    local lastBtn = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
    lastBtn:SetSize(40, 25)
    lastBtn:SetPoint("RIGHT", paginationFrame, "RIGHT", -10, 0)
    lastBtn:SetText("≫")
    lastBtn:SetEnabled(pagination.currentPage < totalPages)
    lastBtn:SetScript("OnClick", function()
        pagination.currentPage = totalPages
        self:UpdateContent()
    end)
    
    return paginationFrame
end

-- Créer une entrée de loot moderne avec glassmorphism
function LootLedger:CreateModernLootEntry(parent, loot, yOffset, index)
    local entryFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entryFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)
    entryFrame:SetSize(UI_WIDTH - 100, 45)
    entryFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    
    -- Couleurs de qualité modernes avec transparence
    local qualityColors = {
        [0] = {0.4, 0.4, 0.4, 0.6}, -- Poor (Gris)
        [1] = {0.8, 0.8, 0.8, 0.5}, -- Common (Blanc)
        [2] = {0.2, 0.8, 0.2, 0.6}, -- Uncommon (Vert)
        [3] = {0.2, 0.6, 1.0, 0.6}, -- Rare (Bleu)
        [4] = {0.7, 0.3, 1.0, 0.7}, -- Epic (Violet)
        [5] = {1.0, 0.5, 0.0, 0.8}  -- Legendary (Orange)
    }
    
    local quality = tonumber(loot.quality) or 1
    quality = math.max(0, math.min(5, quality))
    local color = qualityColors[quality]
    
    entryFrame:SetBackdropColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, color[4])
    entryFrame:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
    
    -- Numéro d'index stylé
    local indexText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    indexText:SetPoint("LEFT", entryFrame, "LEFT", 5, 0)
    indexText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    indexText:SetText("|cff666666#" .. index .. "|r")
    
    -- Icône d'objet avec bordure de qualité
    local iconTexture = entryFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetPoint("LEFT", entryFrame, "LEFT", 25, 0)
    iconTexture:SetSize(36, 36)
    
    if loot.itemLink then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(loot.itemLink)
        iconTexture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    else
        iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Bordure d'icône avec couleur de qualité
    local iconBorder = entryFrame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetPoint("CENTER", iconTexture, "CENTER")
    iconBorder:SetSize(40, 40)
    iconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    iconBorder:SetVertexColor(color[1], color[2], color[3], 0.9)
    
    -- Nom d'objet cliquable avec couleur de qualité
    local itemName = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemName:SetPoint("LEFT", iconTexture, "RIGHT", 8, 8)
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    local qualityPrefix = ""
    if quality >= 4 then qualityPrefix = "✦ " elseif quality >= 3 then qualityPrefix = "★ " end
    itemName:SetText(qualityPrefix .. (loot.itemName or "Objet Inconnu"))
    itemName:SetTextColor(color[1], color[2], color[3], 1)
    
    -- Quantité avec style moderne
    if (loot.quantity or 1) > 1 then
        local qtyText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        qtyText:SetPoint("LEFT", itemName, "RIGHT", 5, 0)
        qtyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        qtyText:SetText("|cff4A9BFFx" .. (loot.quantity or 1) .. "|r")
    end
    
    -- Informations de zone et temps avec style moderne
    local infoText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("LEFT", iconTexture, "RIGHT", 8, -8)
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    local timeStr = self:FormatTimestamp(loot.timestamp)
    local zoneStr = loot.zone or "Zone inconnue"
    if string.len(zoneStr) > 20 then zoneStr = string.sub(zoneStr, 1, 17) .. "..." end
    infoText:SetText("|cff888888📍 " .. zoneStr .. " • ⏰ " .. timeStr .. "|r")
    
    -- Source avec icône moderne
    local sourceText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("RIGHT", entryFrame, "RIGHT", -8, 0)
    sourceText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    local sourceIcon = (loot.source == "Direct") and "🎯" or "💬"
    local sourceColor = (loot.source == "Direct") and "|cff4CAF50" or "|cff2196F3"
    sourceText:SetText(sourceIcon .. " " .. sourceColor .. (loot.source or "Inconnu") .. "|r")
    
    -- Effets de survol modernes
    entryFrame:EnableMouse(true)
    entryFrame:SetScript("OnEnter", function()
        entryFrame:SetBackdropColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, color[4] + 0.2)
        entryFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1.0)
    end)
    entryFrame:SetScript("OnLeave", function()
        entryFrame:SetBackdropColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, color[4])
        entryFrame:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
    end)
    
    return entryFrame
end

-- Create filter controls for loots
function LootLedger:CreateLootFilters()
    local yOffset = -10
    
    -- Filter background
    local filterBG = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    filterBG:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 5, yOffset)
    filterBG:SetSize(UI_WIDTH - 80, 80)
    filterBG:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    filterBG:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
    filterBG:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)
    
    -- Title for filters
    local filterTitle = filterBG:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    filterTitle:SetPoint("TOPLEFT", filterBG, "TOPLEFT", 10, -8)
    filterTitle:SetText("|cff00ff00Filtres de Butin|r")
    
    -- Quality filter dropdown
    local qualityLabel = filterBG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    qualityLabel:SetPoint("TOPLEFT", filterBG, "TOPLEFT", 10, -30)
    qualityLabel:SetText("Qualité:")
    qualityLabel:SetTextColor(1, 1, 0)
    
    local qualityDropdown = CreateFrame("Button", nil, filterBG, "UIDropDownMenuTemplate")
    qualityDropdown:SetPoint("LEFT", qualityLabel, "RIGHT", 10, 0)
    qualityDropdown:SetSize(120, 32)
    
    -- Zone filter dropdown
    local zoneLabel = filterBG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneLabel:SetPoint("LEFT", qualityDropdown, "RIGHT", 20, 0)
    zoneLabel:SetText("Zone:")
    zoneLabel:SetTextColor(1, 1, 0)
    
    local zoneDropdown = CreateFrame("Button", nil, filterBG, "UIDropDownMenuTemplate")
    zoneDropdown:SetPoint("LEFT", zoneLabel, "RIGHT", 10, 0)
    zoneDropdown:SetSize(120, 32)
    
    -- Search box
    local searchLabel = filterBG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", filterBG, "TOPLEFT", 10, -55)
    searchLabel:SetText("Rechercher:")
    searchLabel:SetTextColor(1, 1, 0)
    
    local searchBox = CreateFrame("EditBox", nil, filterBG, "InputBoxTemplate")
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchBox:SetSize(150, 25)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        if LootLedger.UpdateLootDisplay then
            LootLedger:UpdateLootDisplay()
        end
    end)
    
    -- Store references for later use
    self.lootFilters = {
        qualityDropdown = qualityDropdown,
        zoneDropdown = zoneDropdown,
        searchBox = searchBox,
        selectedQuality = nil,
        selectedZone = nil
    }
    
    -- Initialize dropdowns
    self:InitializeLootDropdowns()
end

-- Initialize dropdown menus for loot filters
function LootLedger:InitializeLootDropdowns()
    -- Quality dropdown
    UIDropDownMenu_SetWidth(self.lootFilters.qualityDropdown, 100)
    UIDropDownMenu_SetText(self.lootFilters.qualityDropdown, "Toutes")
    UIDropDownMenu_Initialize(self.lootFilters.qualityDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- All qualities option
        info.text = "Toutes les qualités"
        info.value = nil
        info.func = function()
            LootLedger.lootFilters.selectedQuality = nil
            UIDropDownMenu_SetText(LootLedger.lootFilters.qualityDropdown, "Toutes")
            LootLedger:UpdateLootDisplay()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Quality options
        local qualities = {
            {text = "|cff9d9d9dMédiocre", value = 0},
            {text = "|cffffffffCommun", value = 1},
            {text = "|cff1eff00Inhabituel", value = 2},
            {text = "|cff0070ddRare", value = 3},
            {text = "|cffa335eeÉpique", value = 4},
            {text = "|cffff8000Légendaire", value = 5}
        }
        
        for _, quality in ipairs(qualities) do
            info.text = quality.text
            info.value = quality.value
            info.func = function()
                LootLedger.lootFilters.selectedQuality = quality.value
                UIDropDownMenu_SetText(LootLedger.lootFilters.qualityDropdown, quality.text)
                LootLedger:UpdateLootDisplay()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Zone dropdown
    UIDropDownMenu_SetWidth(self.lootFilters.zoneDropdown, 100)
    UIDropDownMenu_SetText(self.lootFilters.zoneDropdown, "Toutes")
    UIDropDownMenu_Initialize(self.lootFilters.zoneDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- All zones option
        info.text = "Toutes les zones"
        info.value = nil
        info.func = function()
            LootLedger.lootFilters.selectedZone = nil
            UIDropDownMenu_SetText(LootLedger.lootFilters.zoneDropdown, "Toutes")
            LootLedger:UpdateLootDisplay()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Get unique zones from loot data
        local zones = {}
        for _, loot in ipairs(LootLedger.db.loots) do
            if loot.zone and not zones[loot.zone] then
                zones[loot.zone] = true
            end
        end
        
        for zone, _ in pairs(zones) do
            info.text = zone
            info.value = zone
            info.func = function()
                LootLedger.lootFilters.selectedZone = zone
                UIDropDownMenu_SetText(LootLedger.lootFilters.zoneDropdown, zone)
                LootLedger:UpdateLootDisplay()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
end

-- Create enhanced loot entries with visuals
function LootLedger:CreateLootEntries()
    local yOffset = -100 -- Start below filters
    local entryHeight = 50
    local maxEntries = 10
    
    -- Get filtered loot data
    local filteredLoots = self:GetFilteredLoots()
    
    -- Display entries
    local displayCount = math.min(#filteredLoots, maxEntries)
    for i = 1, displayCount do
        local loot = filteredLoots[i]
        if loot then
            self:CreateLootEntry(loot, yOffset, entryHeight)
            yOffset = yOffset - entryHeight - 5
        end
    end
    
    -- Summary stats at the bottom
    yOffset = yOffset - 20
    local summaryText = self.scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryText:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    summaryText:SetText(string.format("|cff00ff00Affichage de %d sur %d objets trouvés|r", displayCount, #filteredLoots))
    
    -- Update scroll content height
    self.scrollContent:SetHeight(math.abs(yOffset) + 50)
end

-- Create individual loot entry with enhanced visuals
function LootLedger:CreateLootEntry(loot, yOffset, height)
    -- Entry background
    local entryFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    entryFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    entryFrame:SetSize(UI_WIDTH - 100, height)
    entryFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Quality-based background color
    local qualityColors = {
        [0] = {0.5, 0.5, 0.5, 0.3}, -- Poor
        [1] = {1, 1, 1, 0.2},       -- Common
        [2] = {0, 1, 0, 0.2},       -- Uncommon
        [3] = {0, 0.5, 1, 0.2},     -- Rare
        [4] = {0.7, 0.3, 1, 0.3},   -- Epic
        [5] = {1, 0.5, 0, 0.3}      -- Legendary
    }
    
    -- Ensure quality is a valid number
    local quality = tonumber(loot.quality) or 1
    if quality < 0 or quality > 5 then
        quality = 1
    end
    
    local color = qualityColors[quality]
    if not color then
        color = qualityColors[1] -- Default to common if somehow still nil
    end
    
    entryFrame:SetBackdropColor(color[1], color[2], color[3], color[4])
    entryFrame:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
    
    -- Item icon
    local iconTexture = entryFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetPoint("LEFT", entryFrame, "LEFT", 8, 0)
    iconTexture:SetSize(32, 32)
    
    -- Get item texture
    if loot.itemLink then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(loot.itemLink)
        if texture then
            iconTexture:SetTexture(texture)
        else
            iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    end
    
    -- Icon border
    local iconBorder = entryFrame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetPoint("CENTER", iconTexture, "CENTER")
    iconBorder:SetSize(38, 38)
    iconBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    iconBorder:SetVertexColor(color[1], color[2], color[3], 1)
    
    -- Item name (clickable)
    local itemNameText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemNameText:SetPoint("LEFT", iconTexture, "RIGHT", 10, 8)
    itemNameText:SetText((loot.itemLink or loot.itemName or "Objet inconnu"))
    
    -- Quantity
    if (loot.quantity or 1) > 1 then
        local qtyText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        qtyText:SetPoint("TOPRIGHT", iconTexture, "TOPRIGHT", 2, 2)
        qtyText:SetText("|cffffffff" .. (loot.quantity or 1) .. "|r")
        qtyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    -- Location and time info
    local infoText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("LEFT", iconTexture, "RIGHT", 10, -8)
    local timeStr = self:FormatTimestamp(loot.timestamp)
    local zoneStr = loot.zone or "Zone inconnue"
    infoText:SetText("|cff888888" .. zoneStr .. " • " .. timeStr .. "|r")
    
    -- Source indicator
    local sourceText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("RIGHT", entryFrame, "RIGHT", -10, 0)
    local sourceStr = loot.source or "Inconnu"
    local sourceColor = sourceStr == "Direct" and "|cff00ff00" or "|cff0080ff"
    sourceText:SetText(sourceColor .. sourceStr .. "|r")
    
    -- Mouse interactions
    entryFrame:EnableMouse(true)
    entryFrame:SetScript("OnEnter", function(self)
        if loot.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(loot.itemLink)
            GameTooltip:Show()
        end
        entryFrame:SetBackdropColor(color[1] * 1.5, color[2] * 1.5, color[3] * 1.5, 0.6)
    end)
    
    entryFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        entryFrame:SetBackdropColor(color[1], color[2], color[3], color[4])
    end)
    
    entryFrame:SetScript("OnMouseDown", function(self)
        if loot.itemLink and IsShiftKeyDown() then
            ChatEdit_InsertLink(loot.itemLink)
        end
    end)
end

-- Get filtered loot data based on current filters
function LootLedger:GetFilteredLoots()
    if not self.db.loots then return {} end
    
    local filtered = {}
    local searchFilter = self.searchFilter or ""
    local qualityFilter = self.selectedQualityFilter
    local zoneFilter = self.selectedZoneFilter
    
    -- Reverse order (newest first)
    for i = #self.db.loots, 1, -1 do
        local loot = self.db.loots[i]
        if loot then
            -- Clean up corrupted quality data
            if loot.quality and type(loot.quality) ~= "number" then
                loot.quality = 1 -- Default to common quality
            end
            
            local include = true
            
            -- Quality filter
            if qualityFilter and (tonumber(loot.quality) or 1) ~= qualityFilter then
                include = false
            end
            
            -- Zone filter
            if zoneFilter and loot.zone ~= zoneFilter then
                include = false
            end
            
            -- Search filter
            if searchFilter ~= "" and searchFilter ~= "Rechercher..." then
                local itemName = (loot.itemName or ""):lower()
                local zone = (loot.zone or ""):lower()
                if not (itemName:find(searchFilter:lower()) or zone:find(searchFilter:lower())) then
                    include = false
                end
            end
            
            if include then
                table.insert(filtered, loot)
            end
        end
    end
    
    return filtered
end

-- Update loot display (called when filters change)
function LootLedger:UpdateLootDisplay()
    if activeTab == "loots" then
        self:ClearScrollContent()
        self:CreateLootsContent()
    end
end

-- Create currency tab content
function LootLedger:CreateCurrencyContent()
    local yOffset = -10
    local lineHeight = 40
    
    if not self.db.currency or #self.db.currency == 0 then
        local noData = self.scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noData:SetPoint("CENTER", self.scrollContent, "CENTER", 0, 0)
        noData:SetText("Aucune transaction enregistrée")
        noData:SetTextColor(0.7, 0.7, 0.7)
        return
    end
    
    -- Title
    local title = self.scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", self.scrollContent, "TOP", 0, yOffset)
    title:SetText("|cffffff00Historique des Transactions|r")
    yOffset = yOffset - 40
    
    -- Display last 20 transactions
    local maxEntries = 20
    local displayCount = math.min(#self.db.currency, maxEntries)
    
    for i = #self.db.currency, math.max(1, #self.db.currency - displayCount + 1), -1 do
        local currency = self.db.currency[i]
        if currency then
            -- Transaction background
            local entryFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
            entryFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
            entryFrame:SetSize(UI_WIDTH - 100, lineHeight - 5)
            entryFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            
            -- Color based on gain/loss
            if currency.difference >= 0 then
                entryFrame:SetBackdropColor(0, 0.3, 0, 0.3) -- Green for gains
                entryFrame:SetBackdropBorderColor(0, 0.8, 0, 0.8)
            else
                entryFrame:SetBackdropColor(0.3, 0, 0, 0.3) -- Red for losses
                entryFrame:SetBackdropBorderColor(0.8, 0, 0, 0.8)
            end
            
            -- Change amount (large, prominent)
            local changeText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            changeText:SetPoint("LEFT", entryFrame, "LEFT", 10, 8)
            local changeColor = currency.difference >= 0 and "|cff00ff00+" or "|cffff0000"
            changeText:SetText(changeColor .. self:FormatMoney(math.abs(currency.difference)) .. "|r")
            
            -- Total amount
            local totalText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            totalText:SetPoint("LEFT", entryFrame, "LEFT", 10, -8)
            totalText:SetText("|cff888888Total: " .. self:FormatMoney(currency.newAmount) .. "|r")
            
            -- Zone and time
            local infoText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            infoText:SetPoint("RIGHT", entryFrame, "RIGHT", -10, 0)
            local zoneText = currency.zone or "Inconnu"
            if string.len(zoneText) > 15 then
                zoneText = string.sub(zoneText, 1, 12) .. "..."
            end
            infoText:SetText("|cffcccccc" .. zoneText .. " • " .. self:FormatTimestamp(currency.timestamp) .. "|r")
            
            yOffset = yOffset - lineHeight
        end
    end
    
    -- Summary at bottom
    yOffset = yOffset - 20
    local summaryText = self.scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryText:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    summaryText:SetText(string.format("|cff00ff00Affichage des %d dernières transactions|r", displayCount))
    
    -- Update scroll content height
    self.scrollContent:SetHeight(math.abs(yOffset) + 50)
end

-- Create stats tab content avec design ultra-moderne
function LootLedger:CreateStatsContent()
    local yOffset = -15
    
    -- Header élégant avec icône d'or
    local headerFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    headerFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    headerFrame:SetSize(UI_WIDTH - 80, 60)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    headerFrame:SetBackdropColor(0.15, 0.1, 0.05, 0.9)
    headerFrame:SetBackdropBorderColor(1.0, 0.8, 0.2, 0.8)
    
    -- Icône d'or avec effet brillant
    local goldIcon = headerFrame:CreateTexture(nil, "ARTWORK")
    goldIcon:SetSize(40, 40)
    goldIcon:SetPoint("LEFT", headerFrame, "LEFT", 15, 0)
    goldIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    
    -- Effet de lueur dorée autour de l'icône
    local iconGlow = headerFrame:CreateTexture(nil, "BACKGROUND")
    iconGlow:SetSize(50, 50)
    iconGlow:SetPoint("CENTER", goldIcon, "CENTER")
    iconGlow:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1")
    iconGlow:SetVertexColor(1.0, 0.8, 0.2, 0.4)
    
    -- Titre principal avec style doré
    local title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", goldIcon, "RIGHT", 15, 8)
    title:SetFont("Fonts\\MORPHEUS.TTF", 20, "OUTLINE")
    title:SetText("💰 |cffffcc00Statistiques Financières|r")
    
    -- Sous-titre descriptif
    local subtitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("LEFT", goldIcon, "RIGHT", 15, -10)
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
    subtitle:SetText("|cff888888Analyse complète de vos revenus et dépenses|r")
    
    yOffset = yOffset - 80
    
    -- === SECTION FINANCES PRINCIPALES ===
    local financeFrame = self:CreateStatsSection("💳 Situation Financière Actuelle", yOffset, 100)
    yOffset = yOffset - 10
    
    local currentGold = self.db.stats.currentGold or 0
    local totalGained = self.db.stats.totalGained or 0
    local totalLost = self.db.stats.totalLost or 0
    local netChange = totalGained - totalLost
    
    -- Cartes financières principales avec design premium
    local currentCard = self:CreateGoldStatCard(financeFrame, "💰 Or Actuel", self:FormatMoney(currentGold), "|cffFFD700", 0, -25, 185, 40)
    local gainedCard = self:CreateGoldStatCard(financeFrame, "📈 Total Gagné", "+" .. self:FormatMoney(totalGained), "|cff4CAF50", 190, -25, 185, 40)
    local lostCard = self:CreateGoldStatCard(financeFrame, "📉 Total Perdu", "-" .. self:FormatMoney(totalLost), "|cffF44336", 380, -25, 185, 40)
    
    -- Bilan net avec couleur dynamique
    local netColor = netChange >= 0 and "|cff4CAF50" or "|cffF44336"
    local netPrefix = netChange >= 0 and "+" or ""
    local netCard = self:CreateGoldStatCard(financeFrame, "💼 Bilan Net", netPrefix .. self:FormatMoney(math.abs(netChange)), netColor, 95, -70, 375, 40)
    
    yOffset = yOffset - 120
    
    -- === SECTION ANALYSE DÉTAILLÉE ===
    local analysisFrame = self:CreateStatsSection("📊 Analyse Détaillée", yOffset, 140)
    yOffset = yOffset - 10
    
    -- Calculs d'analyse avancée
    local lootCount = self.db.loots and #self.db.loots or 0
    local currencyCount = self.db.currency and #self.db.currency or 0
    local avgGain = lootCount > 0 and (totalGained / lootCount) or 0
    local avgLoss = currencyCount > 0 and (totalLost / math.max(1, currencyCount)) or 0
    
    -- Première ligne d'analyse
    local lootCountCard = self:CreateAnalysisCard(analysisFrame, "🎒 Objets Récupérés", self:FormatNumber(lootCount), "|cff9C27B0", 0, -25, 140, 35)
    local transactionCard = self:CreateAnalysisCard(analysisFrame, "💳 Transactions", self:FormatNumber(currencyCount), "|cff2196F3", 145, -25, 140, 35)
    local avgGainCard = self:CreateAnalysisCard(analysisFrame, "📈 Gain Moyen", self:FormatMoney(avgGain), "|cff4CAF50", 290, -25, 140, 35)
    local avgLossCard = self:CreateAnalysisCard(analysisFrame, "📉 Perte Moyenne", self:FormatMoney(avgLoss), "|cffFF5722", 435, -25, 140, 35)
    
    -- Deuxième ligne avec ratios
    local gainLossRatio = totalLost > 0 and (totalGained / totalLost) or (totalGained > 0 and 999 or 1)
    local efficiency = totalGained > 0 and ((totalGained - totalLost) / totalGained * 100) or 0
    
    local ratioCard = self:CreateAnalysisCard(analysisFrame, "⚖️ Ratio Gain/Perte", string.format("%.2f", gainLossRatio), "|cffFF9800", 0, -65, 190, 35)
    local efficiencyCard = self:CreateAnalysisCard(analysisFrame, "⚡ Efficacité", string.format("%.1f%%", efficiency), "|cff673AB7", 195, -65, 190, 35)
    local profitabilityCard = self:CreateAnalysisCard(analysisFrame, "💎 Rentabilité", efficiency > 0 and "Profitable" or "En perte", efficiency > 0 and "|cff4CAF50" or "|cffF44336", 390, -65, 185, 35)
    
    yOffset = yOffset - 160
    
    -- === SECTION HISTORIQUE RÉCENT ===
    local historyFrame = self:CreateStatsSection("📋 Historique Récent", yOffset, 180)
    yOffset = yOffset - 10
    
    -- Affichage des 5 dernières transactions les plus importantes
    local recentTransactions = {}
    if self.db.currency then
        for i = math.max(1, #self.db.currency - 4), #self.db.currency do
            if self.db.currency[i] then
                table.insert(recentTransactions, self.db.currency[i])
            end
        end
    end
    
    if #recentTransactions > 0 then
        for i, transaction in ipairs(recentTransactions) do
            local transactionFrame = self:CreateTransactionEntry(historyFrame, transaction, -25 - (i-1) * 30)
        end
    else
        -- Message si pas d'historique
        local noHistoryText = historyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noHistoryText:SetPoint("CENTER", historyFrame, "CENTER", 0, -20)
        noHistoryText:SetFont("Fonts\\FRIZQT__.TTF", 12)
        noHistoryText:SetText("|cff888888Aucune transaction récente|r")
    end
    
    yOffset = yOffset - 200
    
    -- === FOOTER AVEC CONSEILS ===
    local footerFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    footerFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    footerFrame:SetSize(UI_WIDTH - 80, 50)
    footerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    footerFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.8)
    footerFrame:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.6)
    
    -- Conseil basé sur les performances
    local adviceText = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    adviceText:SetPoint("CENTER", footerFrame, "CENTER", 0, 5)
    adviceText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    
    local advice = ""
    if efficiency > 50 then
        advice = "💡 |cff4CAF50Excellente gestion financière ! Continuez sur cette voie.|r"
    elseif efficiency > 0 then
        advice = "💡 |cffFF9800Rentabilité modérée. Cherchez des sources de revenus plus lucratives.|r"
    else
        advice = "💡 |cffF44336Attention aux dépenses ! Privilégiez le farming et les ventes.|r"
    end
    adviceText:SetText(advice)
    
    -- Timestamp de dernière mise à jour
    local timestampText = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timestampText:SetPoint("CENTER", footerFrame, "CENTER", 0, -10)
    timestampText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    timestampText:SetText("|cff666666Dernière mise à jour: " .. date("%H:%M:%S") .. "|r")
    
    -- Mise à jour de la hauteur du contenu défilable
    self.scrollContent:SetHeight(math.abs(yOffset) + 70)
end

-- Fonction pour créer une carte de statistique d'or avec style premium
function LootLedger:CreateGoldStatCard(parent, label, value, color, x, y, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    card:SetSize(width, height)
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    card:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
    card:SetBackdropBorderColor(1.0, 0.8, 0.2, 0.7)
    
    -- Label avec icône
    local labelText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -6)
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    labelText:SetText(label)
    labelText:SetTextColor(0.9, 0.8, 0.6)
    
    -- Valeur en grand avec effet doré
    local valueText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    valueText:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -20)
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    valueText:SetText(color .. value .. "|r")
    
    -- Effet de survol doré
    card:EnableMouse(true)
    card:SetScript("OnEnter", function()
        card:SetBackdropColor(0.2, 0.15, 0.1, 1.0)
        card:SetBackdropBorderColor(1.0, 0.9, 0.3, 1.0)
    end)
    card:SetScript("OnLeave", function()
        card:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
        card:SetBackdropBorderColor(1.0, 0.8, 0.2, 0.7)
    end)
    
    return card
end

-- Fonction pour créer une carte d'analyse avec style moderne
function LootLedger:CreateAnalysisCard(parent, label, value, color, x, y, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    card:SetSize(width, height)
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    card:SetBackdropColor(0.08, 0.12, 0.18, 0.85)
    card:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.9)
    
    -- Label compact
    local labelText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -4)
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 8)
    labelText:SetText(label)
    labelText:SetTextColor(0.8, 0.8, 0.9)
    
    -- Valeur principale
    local valueText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -16)
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    valueText:SetText(color .. value .. "|r")
    
    -- Effet de survol subtil
    card:EnableMouse(true)
    card:SetScript("OnEnter", function()
        card:SetBackdropColor(0.12, 0.16, 0.24, 0.95)
        card:SetBackdropBorderColor(0.35, 0.45, 0.65, 1.0)
    end)
    card:SetScript("OnLeave", function()
        card:SetBackdropColor(0.08, 0.12, 0.18, 0.85)
        card:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.9)
    end)
    
    return card
end

-- Fonction pour créer une entrée de transaction dans l'historique
function LootLedger:CreateTransactionEntry(parent, transaction, yOffset)
    local entryFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entryFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    entryFrame:SetSize(UI_WIDTH - 120, 25)
    entryFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    
    -- Couleur selon gain/perte
    if transaction.difference >= 0 then
        entryFrame:SetBackdropColor(0, 0.15, 0.05, 0.8)
        entryFrame:SetBackdropBorderColor(0.2, 0.6, 0.3, 0.8)
    else
        entryFrame:SetBackdropColor(0.15, 0.05, 0, 0.8)
        entryFrame:SetBackdropBorderColor(0.6, 0.3, 0.2, 0.8)
    end
    
    -- Icône de transaction
    local transactionIcon = entryFrame:CreateTexture(nil, "ARTWORK")
    transactionIcon:SetSize(16, 16)
    transactionIcon:SetPoint("LEFT", entryFrame, "LEFT", 8, 0)
    if transaction.difference >= 0 then
        transactionIcon:SetTexture("Interface\\Icons\\Spell_Misc_CoinFlip")
        transactionIcon:SetVertexColor(0.4, 1.0, 0.4)
    else
        transactionIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
        transactionIcon:SetVertexColor(1.0, 0.4, 0.4)
    end
    
    -- Montant de la transaction
    local amountText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    amountText:SetPoint("LEFT", transactionIcon, "RIGHT", 8, 0)
    amountText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    local amountColor = transaction.difference >= 0 and "|cff4CAF50+" or "|cffF44336"
    amountText:SetText(amountColor .. self:FormatMoney(math.abs(transaction.difference)) .. "|r")
    
    -- Zone et temps
    local infoText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("RIGHT", entryFrame, "RIGHT", -8, 0)
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    local timeStr = self:FormatTimestamp(transaction.timestamp)
    local zoneStr = transaction.zone or "Inconnu"
    if string.len(zoneStr) > 12 then
        zoneStr = string.sub(zoneStr, 1, 9) .. "..."
    end
    infoText:SetText("|cff888888" .. zoneStr .. " • " .. timeStr .. "|r")
    
    return entryFrame
end

-- Create fun stats tab content avec design ultra-moderne
function LootLedger:CreateFunStatsContent()
    local funStats = self.db.funStats or {}
    local yOffset = -15
    
    -- Header avec titre élégant et dégradé
    local headerFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    headerFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    headerFrame:SetSize(UI_WIDTH - 80, 60)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    headerFrame:SetBackdropColor(0.1, 0.05, 0.2, 0.9)
    headerFrame:SetBackdropBorderColor(0.8, 0.4, 1.0, 0.8)
    
    -- Icône de combat élégante
    local combatIcon = headerFrame:CreateTexture(nil, "ARTWORK")
    combatIcon:SetSize(40, 40)
    combatIcon:SetPoint("LEFT", headerFrame, "LEFT", 15, 0)
    combatIcon:SetTexture("Interface\\Icons\\Ability_Warrior_Sunder")
    
    -- Effet de lueur autour de l'icône
    local iconGlow = headerFrame:CreateTexture(nil, "BACKGROUND")
    iconGlow:SetSize(50, 50)
    iconGlow:SetPoint("CENTER", combatIcon, "CENTER")
    iconGlow:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1")
    iconGlow:SetVertexColor(0.8, 0.4, 1.0, 0.4)
    
    -- Titre principal avec style
    local title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", combatIcon, "RIGHT", 15, 8)
    title:SetFont("Fonts\\MORPHEUS.TTF", 20, "OUTLINE")
    title:SetText("⚔️ |cffaa44ffStatistiques de Combat|r")
    
    -- Sous-titre descriptif
    local subtitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("LEFT", combatIcon, "RIGHT", 15, -10)
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
    subtitle:SetText("|cff888888Performances et métriques de session|r")
    
    yOffset = yOffset - 80
    
    -- === SECTION SESSION ET CARACTÈRE ===
    local sessionFrame = self:CreateStatsSection("📊 Informations de Session", yOffset, 120)
    yOffset = yOffset - 10
    
    -- Temps de session avec barre de progression visuelle
    local sessionTime = time() - (funStats.sessionStart or time())
    local timeCard = self:CreateStatCard(sessionFrame, "⏱️ Temps de Session", self:FormatTime(sessionTime), "|cffFFD700", 0, -25, 280, 35)
    
    -- Niveau et XP avec barre de progression
    local level = UnitLevel("player")
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local xpPercent = maxXP > 0 and (currentXP / maxXP * 100) or 0
    local levelCard = self:CreateStatCard(sessionFrame, "🎯 Niveau", string.format("%d (XP: %d/%d)", level, currentXP, maxXP), "|cff00BFFF", 290, -25, 280, 35)
    
    -- Barres de santé et mana actuelles avec style moderne
    local maxHealth = UnitHealthMax("player")
    local currentHealth = UnitHealth("player")
    local healthPercent = maxHealth > 0 and (currentHealth / maxHealth * 100) or 0
    local healthCard = self:CreateStatCard(sessionFrame, "❤️ Santé", string.format("%d/%d (%.0f%%)", currentHealth, maxHealth, healthPercent), "|cffFF6B6B", 0, -65, 280, 35)
    
    local maxMana = UnitPowerMax("player", 0) or 0
    local currentMana = UnitPower("player", 0) or 0
    local manaPercent = maxMana > 0 and (currentMana / maxMana * 100) or 0
    local manaCard = self:CreateStatCard(sessionFrame, "💙 Mana", string.format("%d/%d (%.0f%%)", currentMana, maxMana, manaPercent), "|cff74C7FF", 290, -65, 280, 35)
    
    yOffset = yOffset - 140
    
    -- === SECTION COMBAT ===
    local combatFrame = self:CreateStatsSection("⚔️ Statistiques de Combat", yOffset, 140)
    yOffset = yOffset - 10
    
    -- Première ligne de stats de combat
    local spellsCard = self:CreateStatCard(combatFrame, "✨ Sorts Lancés", self:FormatNumber(funStats.spellsCast or 0), "|cffFFD700", 0, -25, 140, 35)
    local damageCard = self:CreateStatCard(combatFrame, "💥 Dégâts Infligés", self:FormatNumber(funStats.damageDealt or 0), "|cffFF6B47", 145, -25, 140, 35)
    local takenCard = self:CreateStatCard(combatFrame, "🛡️ Dégâts Subis", self:FormatNumber(funStats.damageTaken or 0), "|cffFF8E53", 290, -25, 140, 35)
    local healCard = self:CreateStatCard(combatFrame, "💚 Soins Prodigués", self:FormatNumber(funStats.healingDone or 0), "|cff4CAF50", 435, -25, 140, 35)
    
    -- Deuxième ligne de stats
    local mobsCard = self:CreateStatCard(combatFrame, "💀 Créatures Tuées", self:FormatNumber(funStats.mobsKilled or 0), "|cffFFA726", 0, -65, 140, 35)
    local deathsCard = self:CreateStatCard(combatFrame, "☠️ Morts", self:FormatNumber(funStats.deaths or 0), "|cffF44336", 145, -65, 140, 35)
    local manaSpentCard = self:CreateStatCard(combatFrame, "🔮 Mana Dépensé", self:FormatNumber(funStats.manaSpent or 0), "|cff9C27B0", 290, -65, 140, 35)
    
    -- Statistiques de performance améliorées
    local dpsStats = LootLedger:CalculateDPSStats()
    local combatDPS = dpsStats.combatDPS
    local dpsCard = self:CreateStatCard(combatFrame, "⚡ DPS Combat", self:FormatNumber(combatDPS), "|cffFF5722", 435, -65, 140, 35)
    
    yOffset = yOffset - 160
    
    -- === SECTION DPS AVANCÉ ===
    local dpsAdvFrame = self:CreateStatsSection("⚔️ Analyse Combat Avancée", yOffset, 100)
    yOffset = yOffset - 10
    
    -- Statistiques DPS détaillées
    local dpsStats = LootLedger:CalculateDPSStats()
    local overallDPSCard = self:CreateStatCard(dpsAdvFrame, "📊 DPS Global", self:FormatNumber(dpsStats.overallDPS), "|cffFF9800", 0, -25, 140, 35)
    local combatTimeCard = self:CreateStatCard(dpsAdvFrame, "⏱️ Temps Combat", self:FormatTime(dpsStats.totalCombatTime), "|cff607D8B", 145, -25, 140, 35)
    local avgCombatCard = self:CreateStatCard(dpsAdvFrame, "⚔️ Combat Moyen", self:FormatTime(dpsStats.avgCombatLength), "|cff795548", 290, -25, 140, 35)
    local combatEffCard = self:CreateStatCard(dpsAdvFrame, "🎯 Efficacité", string.format("%.1f%%", dpsStats.combatEfficiency), "|cff4CAF50", 435, -25, 140, 35)
    
    yOffset = yOffset - 120
    
    -- === SECTION RATIOS ET EFFICACITÉ ===
    local ratioFrame = self:CreateStatsSection("📈 Ratios d'Efficacité", yOffset, 100)
    yOffset = yOffset - 10
    
    -- Calculs de ratios
    local healDamageRatio = (funStats.damageDealt or 0) > 0 and (funStats.healingDone or 0) / (funStats.damageDealt or 1) or 0
    local survivalRate = (funStats.mobsKilled or 0) > 0 and (1 - (funStats.deaths or 0) / math.max(1, funStats.mobsKilled or 1)) * 100 or 100
    local manaEfficiency = (funStats.manaSpent or 0) > 0 and (funStats.damageDealt or 0) / (funStats.manaSpent or 1) or 0
    
    local healRatioCard = self:CreateStatCard(ratioFrame, "💚/💥 Ratio Soin/Dégât", string.format("%.2f", healDamageRatio), "|cff4CAF50", 0, -25, 190, 35)
    local survivalCard = self:CreateStatCard(ratioFrame, "🛡️ Taux de Survie", string.format("%.1f%%", survivalRate), "|cff2196F3", 195, -25, 190, 35)
    local efficiencyCard = self:CreateStatCard(ratioFrame, "⚡ Efficacité Mana", string.format("%.1f", manaEfficiency), "|cff9C27B0", 390, -25, 185, 35)
    
    yOffset = yOffset - 120
    
    -- Footer avec informations additionnelles
    local footerFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    footerFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    footerFrame:SetSize(UI_WIDTH - 80, 40)
    footerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    footerFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.8)
    footerFrame:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.6)
    
    local footerText = footerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetPoint("CENTER", footerFrame, "CENTER")
    footerText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    footerText:SetText("|cff888888Statistiques mises à jour en temps réel • Session démarrée: " .. date("%H:%M", funStats.sessionStart or time()) .. "|r")
    
    -- Mise à jour de la hauteur du contenu défilable
    self.scrollContent:SetHeight(math.abs(yOffset) + 60)
end

-- Fonction utilitaire pour créer une section de statistiques avec style
function LootLedger:CreateStatsSection(title, yOffset, height)
    local sectionFrame = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    sectionFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 10, yOffset)
    sectionFrame:SetSize(UI_WIDTH - 80, height)
    sectionFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    sectionFrame:SetBackdropColor(0.08, 0.12, 0.18, 0.85)
    sectionFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)
    
    -- Titre de section avec style
    local sectionTitle = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sectionTitle:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 15, -8)
    sectionTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    sectionTitle:SetText(title)
    sectionTitle:SetTextColor(0.9, 0.9, 1.0)
    
    return sectionFrame
end

-- Fonction utilitaire pour créer une carte de statistique moderne
function LootLedger:CreateStatCard(parent, label, value, color, x, y, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    card:SetSize(width, height)
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    card:SetBackdropColor(0.12, 0.16, 0.24, 0.8)
    card:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.9)
    
    -- Label de la statistique
    local labelText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -5)
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    labelText:SetText(label)
    labelText:SetTextColor(0.8, 0.8, 0.9)
    
    -- Valeur de la statistique avec couleur
    local valueText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -18)
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    valueText:SetText(color .. value .. "|r")
    
    -- Effet de survol
    card:EnableMouse(true)
    card:SetScript("OnEnter", function()
        card:SetBackdropColor(0.15, 0.2, 0.3, 0.9)
        card:SetBackdropBorderColor(0.4, 0.5, 0.7, 1.0)
    end)
    card:SetScript("OnLeave", function()
        card:SetBackdropColor(0.12, 0.16, 0.24, 0.8)
        card:SetBackdropBorderColor(0.25, 0.35, 0.55, 0.9)
    end)
    
    return card
end

-- Fonction utilitaire pour formater les grands nombres
function LootLedger:FormatNumber(num)
    if not num or num == 0 then return "0" end
    
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Format time duration
function LootLedger:FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

-- Exporter les données vers le chat
function LootLedger:ExportData()
    print("|cff00ff00Export LootLedger:|r")
    print("=== STATISTIQUES ===")
    print("Actuel : " .. self:FormatMoney(self.db.stats.currentGold))
    print("Gagné : +" .. self:FormatMoney(self.db.stats.totalGained))
    print("Perdu : -" .. self:FormatMoney(self.db.stats.totalLost))
    
    if self.db.loots and #self.db.loots > 0 then
        print("=== BUTINS RÉCENTS ===")
        for i = math.max(1, #self.db.loots - 9), #self.db.loots do
            local loot = self.db.loots[i]
            if loot then
                print(string.format("%s x%d (%s)", loot.itemName or "Inconnu", loot.quantity or 1, loot.zone or "Inconnue"))
            end
        end
    end
    
    print("Export terminé.")
end

-- Fonctions utilitaires pour les filtres modernes
function LootLedger:ShowQualityFilterMenu(button)
    if not self.qualityFilterMenu then
        self.qualityFilterMenu = CreateFrame("Frame", "LootLedgerQualityMenu", button, "UIDropDownMenuTemplate")
    end
    
    local function qualityDropDown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Toute Qualité"
        info.value = nil
        info.func = function() 
            button:SetText("Toute Qualité")
            LootLedger.selectedQualityFilter = nil
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Médiocre"
        info.value = 0
        info.func = function() 
            button:SetText("Médiocre")
            LootLedger.selectedQualityFilter = 0
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Commune"
        info.value = 1
        info.func = function() 
            button:SetText("Commune")
            LootLedger.selectedQualityFilter = 1
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Inhabituelle"
        info.value = 2
        info.func = function() 
            button:SetText("Inhabituelle")
            LootLedger.selectedQualityFilter = 2
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Rare"
        info.value = 3
        info.func = function() 
            button:SetText("Rare")
            LootLedger.selectedQualityFilter = 3
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Épique"
        info.value = 4
        info.func = function() 
            button:SetText("Épique")
            LootLedger.selectedQualityFilter = 4
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
        
        info.text = "Légendaire"
        info.value = 5
        info.func = function() 
            button:SetText("Légendaire")
            LootLedger.selectedQualityFilter = 5
            LootLedger:UpdateContent()
        end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(self.qualityFilterMenu, qualityDropDown_Initialize)
    ToggleDropDownMenu(1, nil, self.qualityFilterMenu, button, 0, 0)
end

function LootLedger:ShowZoneFilterMenu(button)
    if not self.zoneFilterMenu then
        self.zoneFilterMenu = CreateFrame("Frame", "LootLedgerZoneMenu", button, "UIDropDownMenuTemplate")
    end
    
    -- Collecter toutes les zones uniques
    local zones = {"Toute Zone"}
    local uniqueZones = {}
    
    if self.db.loots then
        for _, loot in ipairs(self.db.loots) do
            local zone = loot.zone or "Zone Inconnue"
            if not uniqueZones[zone] then
                uniqueZones[zone] = true
                table.insert(zones, zone)
            end
        end
    end
    
    local function zoneDropDown_Initialize(self, level)
        for _, zone in ipairs(zones) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = zone
            info.value = zone
            info.func = function()
                button:SetText(zone)
                LootLedger.selectedZoneFilter = (zone == "Toute Zone") and nil or zone
                LootLedger:UpdateContent()
            end
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(self.zoneFilterMenu, zoneDropDown_Initialize)
    ToggleDropDownMenu(1, nil, self.zoneFilterMenu, button, 0, 0)
end

function LootLedger:FilterLootsBySearch(searchText)
    self.searchFilter = searchText and string.lower(searchText) or ""
    self:UpdateContent()
end

function LootLedger:ResetLootFilters()
    self.selectedQualityFilter = nil
    self.selectedZoneFilter = nil
    self.searchFilter = ""
    self:UpdateContent()
end

function LootLedger:FilterLootsBySearch(searchText)
    self.searchFilter = searchText
    self:UpdateContent()
end

function LootLedger:ResetLootFilters()
    self.selectedQualityFilter = nil
    self.selectedZoneFilter = nil
    self.searchFilter = ""
    self:UpdateContent()
end

function LootLedger:PassesLootFilters(loot)
    -- Filtre de qualité
    if self.selectedQualityFilter and tonumber(loot.quality) ~= self.selectedQualityFilter then
        return false
    end
    
    -- Filtre de zone
    if self.selectedZoneFilter and loot.zone ~= self.selectedZoneFilter then
        return false
    end
    
    -- Filtre de recherche
    if self.searchFilter and self.searchFilter ~= "" and self.searchFilter ~= "Rechercher..." then
        local itemName = string.lower(loot.itemName or "")
        local zone = string.lower(loot.zone or "")
        local searchLower = string.lower(self.searchFilter)
        
        if not (string.find(itemName, searchLower) or string.find(zone, searchLower)) then
            return false
        end
    end
    
    return true
end

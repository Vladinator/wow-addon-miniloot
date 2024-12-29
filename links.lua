local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

---@alias SetItemRefAddOnLink "addon"

---@alias MiniLootCustomLinkType "link"

local LINK_TYPE_ADDON = "addon" ---@type SetItemRefAddOnLink
local LINK_PATTERN = "|H(.-)|h(.-)|h"
local CUSTOM_PREFIX = format("%s:%s:", LINK_TYPE_ADDON, addOnName)
local CUSTOM_TYPE_LINK = "link" ---@type MiniLootCustomLinkType
local CUSTOM_PATTERN = format("%s(.-):(.-)$", CUSTOM_PREFIX)

---@param link string
---@return string
local function CreateCustomLinkData(link)
    local escapedLink = link:gsub("%|", "\17"):gsub("%[", "\18"):gsub("%]", "\19")
    return format("%s%s:%s", CUSTOM_PREFIX, CUSTOM_TYPE_LINK, escapedLink)
end

---@param linkData string
---@return MiniLootCustomLinkType linkType, string data
local function ExtractCustomLinkData(linkData)
    ---@type MiniLootCustomLinkType, string
    local customType, data = linkData:match(CUSTOM_PATTERN)
    if customType == "link" then
        data = data:gsub("\17", "|"):gsub("\18", "["):gsub("\19", "]")
    end
    return customType, data
end

---@param link string
---@return boolean
local function IsWrapped(link)
    return link:find(CUSTOM_PREFIX, nil, true) and true or false
end

---@param link string
---@param originalHyperlink string
---@return string customLink
local function Wrap(link, originalHyperlink)
    if IsWrapped(link) then
        return link
    end
    local data, text = link:match(LINK_PATTERN)
    if not data or not text then
        return link
    end
    local fromIndex, toIndex = link:find(data, nil, true)
    if not fromIndex or not toIndex then
        return link
    end
    local prefix = link:sub(1, fromIndex - 1)
    local suffix = link:sub(toIndex + 1)
    local customData = CreateCustomLinkData(originalHyperlink)
    return format("%s%s%s", prefix, customData, suffix)
end

---@generic T
---@param link string
---@param linkData T|nil
---@return string hyperlink, T linkData
local function Unwrap(link, linkData)
    if not IsWrapped(link) then
        return link, linkData
    end
    local data, text = link:match(LINK_PATTERN)
    if not data or not text then
        return link, linkData
    end
    local linkType, payload = ExtractCustomLinkData(data)
    if linkType ~= "link" then
        return link, linkData
    end
    local payloadData, payloadText = payload:match(LINK_PATTERN)
    if not payloadData or not payloadText then
        return link, linkData
    end
    return payload, payloadData
end

local isInitialized = false

local function Init()
    if isInitialized then
        return
    end
    isInitialized = true
    EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button, chatFrame)
        if not IsWrapped(link) then
            return
        end
        local fixedLink = Unwrap(text)
        local fixedLinkData = fixedLink:match(LINK_PATTERN)
        SetItemRef(fixedLinkData, fixedLink, button, chatFrame)
    end)
end

---@class MiniLootNSLinks
ns.Links = {
    Init = Init,
    IsWrapped = IsWrapped,
    Wrap = Wrap,
    Unwrap = Unwrap,
}

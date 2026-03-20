local _, ns = ...

local locale = GetLocale()

if locale == "esES" or locale == "esMX" then
    ns.L = ns.Les or {}
elseif locale == "deDE" then
    ns.L = ns.Lde or {}
elseif locale == "frFR" then
    ns.L = ns.Lfr or {}
elseif locale == "ruRU" then
    ns.L = ns.Lru or {}
else
    ns.L = ns.Len or {}
end

-- fallback: devuelve la clave si falta traducción
setmetatable(ns.L, {
    __index = function(t, k) return k end
})

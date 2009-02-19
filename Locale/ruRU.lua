﻿-- Please make sure to save the file as UTF-8; ¶
--ruRU by Swix (wow.playhard.ru)
local L = LibStub("AceLocale-3.0"):NewLocale("Mapster", "ruRU")
if not L then return end

-- Mapster Config
L["intro_desc"] = "С помощью Mapster'а вы сможете управлять различными параметрами карты мира. Вы можете изменить стиль карты, добавить новую функциональность с помощью плагинов, а также сконфигурировать различные профили для каждого вашего персонажа."
L["Style"] = "Стиль"
L["alpha_desc"] = "Вы можете изменить прозрачность карты, что позволит вам видеть окружающую обстановку в то время, как карта будет открыта."
L["Alpha"] = "Прозрачность"
L["scale_desc"] = "Изменените масштаб карты, если не хотите видеть её развёрнутой на весь экран."
L["Scale"] = "Масштаб"
-- L["Hide Map Button"] = true
-- L["PlayerArrow Scale"] = true
-- L["arrow_desc"] = "Adjust the size of the Player Arrow on the Map for better visibility."

-- Coords
L["Coordinates"] = "Координаты" -- name of the module
L["coords_desc"] = "Модуль координат добавляет строку с отображением вашего текущего местоположения, а также с положением курсора на карте."
L["Enable Coordinates"] = "Включить координаты"
L["Accuracy"] = "Точность"
L["coords_accuracy_desc"] = "\nВы можете управлять точностью координат, например, если вам нужные очень точные координаты - вы можете установить это значение как 2."

L["Cursor"] = "Курсор"
L["Player"] = "Игрок"

-- Group Icons
L["Group Icons"] = "Иконки группы" -- name of the module
L["groupicons_desc"] = "Модуль иконок группы преобразует обычные значки игроков на мировой карте и картах зоны/полей битв в более понятные иконки, с указанием класса персонажа и (в рейдах) его подгруппы."
L["Enable Group Icons"] = "Включить иконки группы"

-- BattleMap
-- L["BattleMap"] = true -- name of the module
-- L["battlemap_desc"] = "The BattleMap module allows you to change the style of the BattlefieldMinimap, removing unnecessary textures or PvP Objectives."
-- L["Enable BattleMap"] = true
-- L["battlemap_textures_desc"] = "\nHide the surrounding textures around the BattleMap, only leaving you with the pure map overlays."
-- L["Hide Textures"] = true

-- FogClear
L["FogClear"] = "Туман войны" -- name of the module
L["fogclear_desc"] = "Модуль очистки тумана войны делает скрытые (неисследованные) зоны видимыми, подсвечивая их особым цветом."
L["Enable FogClear"] = "Очищать туман"
L["Overlay Color"] = "Цвет подсветки"
L["Reset FogClear Data"] = "Сбросить данные модуля очистки"
L["reset_desc"] = "Модуль очистки тумана войны сохраняет новые данные в SavedVariables. Сброс этих данных может понадобится в том случае, если они оказались повреждены (или просто устарели) при выходе нового патча."
L["Note: You need to reload your UI after reseting the data!"] = "Замечание: после выполнения этой операции необходимо перезагрузить ваш интерфейс!"
L["Debug"] = "Отладка"
L["debug_desc"] = "Включить режим отладки для модуля очистки тумана войны."

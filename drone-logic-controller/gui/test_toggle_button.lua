-- gui/test_toggle_button.lua
local test = {}

function test.open(player)
    -- Закрываем старое окно
    if player.gui.center.test_toggle_frame then
        player.gui.center.test_toggle_frame.destroy()
    end

    -- Состояние: false = серая, true = синяя
    if not global.test_button_states then
        global.test_button_states = {}
    end
    if global.test_button_states[player.index] == nil then
        global.test_button_states[player.index] = false
    end
    local is_blue = global.test_button_states[player.index]

    -- Главное окно
    local frame = player.gui.center.add{
        type = "frame",
        name = "test_toggle_frame",
        caption = "Тестовая кнопка",
        direction = "vertical"
    }
    frame.style.width = 300
    frame.style.height = 200

    -- Серая кнопка (стандартный стиль)
    local gray_btn = frame.add{
        type = "button",
        name = "test_toggle_button_gray",
        caption = "Нажми меня",
        visible = not is_blue
    }
    gray_btn.style.width = 64
    gray_btn.style.height = 64

    -- Синяя кнопка (стиль панели быстрого доступа)
    local blue_btn = frame.add{
        type = "button",
        name = "test_toggle_button_blue",
        caption = "Нажми меня",
        visible = is_blue,
        style = "shortcut_bar_button_blue"   -- <-- Вот здесь основное изменение
    }
    blue_btn.style.width = 64
    blue_btn.style.height = 64

    frame.add{
        type = "label",
        caption = "Кликни по кнопке, чтобы изменить цвет.\nСерая ↔ Синяя"
    }
end

function test.on_click(event)
    local element = event.element
    if not element then return end
    if element.name ~= "test_toggle_button_gray" and element.name ~= "test_toggle_button_blue" then
        return
    end

    local player = game.players[event.player_index]
    if not player then return end

    -- Переключаем состояние
    local new_state = not global.test_button_states[player.index]
    global.test_button_states[player.index] = new_state

    -- Пересоздаём окно, чтобы показать другую кнопку
    test.open(player)
end

return test
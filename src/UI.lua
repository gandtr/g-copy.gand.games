local UI = {W = 720, H = 568}
UI.colors = {
    black = {0, 0, 0}, cyan = {0.32, 0.76, 0.80}, dark = {0.025, 0.11, 0.13},
    dim = {0.22, 0.37, 0.38}, white = {0.88, 0.96, 0.93}, green = {0.2, 1, 0.08},
    yellow = {1, 0.88, 0}, red = {1, 0.18, 0.12}, purple = {0.18, 0, 0.32},
}
function UI.init()
    UI.fonts = {}
    for _, size in ipairs({6, 7, 8, 10, 12, 16}) do
        UI.fonts[size] = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", size)
        UI.fonts[size]:setFilter("nearest", "nearest")
    end
end
function UI.color(color, alpha)
    local c = UI.colors[color] or color
    love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
end
function UI.rect(x, y, w, h, color)
    UI.color(color)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), math.floor(w), math.floor(h))
end
function UI.outline(x, y, w, h, color)
    UI.rect(x, y, w, 1, color); UI.rect(x, y + h - 1, w, 1, color)
    UI.rect(x, y, 1, h, color); UI.rect(x + w - 1, y, 1, h, color)
end
function UI.text(text, x, y, size, color, width, align)
    UI.color(color or "cyan")
    love.graphics.setFont(UI.fonts[size or 8])
    if width then love.graphics.printf(text, math.floor(x), math.floor(y), width, align or "left")
    else love.graphics.print(text, math.floor(x), math.floor(y)) end
end
function UI.panel(x, y, w, h)
    UI.rect(x + 4, y + 4, w, h, "black")
    UI.rect(x, y, w, h, "black")
    UI.outline(x, y, w, h, "cyan")
    UI.outline(x + 2, y + 2, w - 4, h - 4, "dim")
end
function UI.button(label, x, y, w, active)
    UI.rect(x, y, w, 19, active and "cyan" or "dark")
    UI.outline(x, y, w, 19, "cyan")
    UI.text(label, x, y + 6, 7, active and "black" or "yellow", w, "center")
end
function UI.contains(x, y, bx, by, bw, bh)
    return x >= bx and x < bx + bw and y >= by and y < by + bh
end
function UI.transform()
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / UI.W, h / UI.H)
    return scale, math.floor((w - UI.W * scale) / 2), math.floor((h - UI.H * scale) / 2)
end
function UI.mouse(x, y)
    local scale, ox, oy = UI.transform()
    return (x - ox) / scale, (y - oy) / scale
end
return UI

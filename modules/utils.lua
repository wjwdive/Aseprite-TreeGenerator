--[[
  Advanced Utility Module for Pixel Tree Generator (v2.0)
  Author: wjwdive
--]]

local Utils = {}

-- Table to Aseprite Color
function Utils.tableToColor(t)
  if not t then return Color(0, 0, 0) end
  return Color(t[1], t[2], t[3])
end

-- Draw a thick line with "Circle" brush for better joint segments
function Utils.drawTaperedSegment(image, x0, y0, x1, y1, w0, w1, color)
  local dx = x1 - x0
  local dy = y1 - y0
  local steps = math.max(math.abs(dx), math.abs(dy))
  if steps == 0 then return end
  
  for i = 0, steps do
    local t = i / steps
    local cx = x0 + dx * t
    local cy = y0 + dy * t
    local w = w0 + (w1 - w0) * t
    
    local r = w / 2
    for ry = -math.ceil(r), math.ceil(r) do
      for rx = -math.ceil(r), math.ceil(r) do
        if rx*rx + ry*ry <= r*r then
          local x = math.floor(cx + rx)
          local y = math.floor(cy + ry)
          if x >= 0 and x < image.width and y >= 0 and y < image.height then
            image:putPixel(x, y, color)
          end
        end
      end
    end
  end
end

-- Draw foliage cluster with multiple overlapping shapes for natural cluster effect
function Utils.drawFoliageCluster(image, cx, cy, baseRadius, colors, lightDir, shape)
  shape = shape or "圆形"
  
  -- 归一化光源向量
  local lightLen = math.sqrt(lightDir.x * lightDir.x + lightDir.y * lightDir.y)
  local lx, ly
  if lightLen > 0 then
    lx = lightDir.x / lightLen
    ly = lightDir.y / lightLen
  else
    lx, ly = 0, -1  -- 默认正上方
  end
  
  -- 限制团簇大小
  baseRadius = math.max(3, math.min(baseRadius, 20))
  
  -- 第一层：绘制多个随机大小的主色形状（基础层）
  local numBaseShapes = math.random(2, 4)
  for i = 1, numBaseShapes do
    local angle = math.random() * math.pi * 2
    local dist = math.random() * baseRadius * 0.4
    local bx = cx + math.cos(angle) * dist
    local by = cy + math.sin(angle) * dist
    local br = baseRadius * (0.5 + math.random() * 0.3)
    
    Utils.drawShape(image, bx, by, br, colors[3], shape)  -- 基础色
  end
  
  -- 第二层：绘制中等亮度的形状，位置和大小随机
  local numMidShapes = math.random(3, 6)
  for i = 1, numMidShapes do
    local angle = math.random() * math.pi * 2
    local dist = math.random() * baseRadius * 0.6
    local bx = cx + math.cos(angle) * dist
    local by = cy + math.sin(angle) * dist
    local br = baseRadius * (0.2 + math.random() * 0.4)
    
    -- 根据光照方向选择颜色
    local dot = math.cos(angle) * lx + math.sin(angle) * ly
    local colorIndex
    if dot > 0.3 then
      colorIndex = 4  -- 中等高光
    elseif dot > -0.3 then
      colorIndex = 3  -- 基础色
    else
      colorIndex = 2  -- 中等阴影
    end
    
    Utils.drawShape(image, bx, by, br, colors[colorIndex], shape)
  end
  
  -- 第三层：绘制高光形状（最亮），数量较少
  local numHighlightShapes = math.random(1, 3)
  for i = 1, numHighlightShapes do
    local angle = math.random() * math.pi * 2
    local dist = math.random() * baseRadius * 0.5
    local bx = cx + math.cos(angle) * dist
    local by = cy + math.sin(angle) * dist
    local br = baseRadius * (0.1 + math.random() * 0.2)
    
    -- 只在光照方向绘制高光
    local dot = math.cos(angle) * lx + math.sin(angle) * ly
    if dot > 0.2 then
      Utils.drawShape(image, bx, by, br, colors[5], shape)  -- 最亮高光
    end
  end
  
  -- 第四层：添加底部阴影
  local shadowOffset = baseRadius * 0.2
  local shadowRadius = baseRadius * 0.6
  for angle = 0, math.pi * 2, 0.4 do
    local sx = cx + math.cos(angle) * shadowOffset
    local sy = cy + math.sin(angle) * shadowOffset + shadowRadius * 0.4
    local sr = shadowRadius * 0.2 * (0.5 + math.random() * 0.5)
    Utils.drawShape(image, sx, sy, sr, colors[1], shape)  -- 最暗阴影
  end
end

-- Draw a shape based on type
function Utils.drawShape(image, cx, cy, radius, color, shape)
  if shape == "圆形" then
    Utils.drawCircle(image, cx, cy, radius, color)
  elseif shape == "方形" then
    Utils.drawSquare(image, cx, cy, radius, color)
  elseif shape == "矩形" then
    Utils.drawRectangle(image, cx, cy, radius, color)
  elseif shape == "三角形" then
    Utils.drawTriangle(image, cx, cy, radius, color)
  elseif shape == "椭圆" then
    Utils.drawEllipse(image, cx, cy, radius, color)
  elseif shape == "五角形" then
    Utils.drawPentagon(image, cx, cy, radius, color)
  else
    Utils.drawCircle(image, cx, cy, radius, color)
  end
end

-- Draw a square
function Utils.drawSquare(image, cx, cy, radius, color)
  local half = math.floor(radius)
  for dy = -half, half do
    for dx = -half, half do
      local x = math.floor(cx + dx)
      local y = math.floor(cy + dy)
      if x >= 0 and x < image.width and y >= 0 and y < image.height then
        image:putPixel(x, y, color)
      end
    end
  end
end

-- Draw a rectangle
function Utils.drawRectangle(image, cx, cy, radius, color)
  local halfW = math.floor(radius * 1.2)
  local halfH = math.floor(radius * 0.8)
  for dy = -halfH, halfH do
    for dx = -halfW, halfW do
      local x = math.floor(cx + dx)
      local y = math.floor(cy + dy)
      if x >= 0 and x < image.width and y >= 0 and y < image.height then
        image:putPixel(x, y, color)
      end
    end
  end
end

-- Draw a triangle
function Utils.drawTriangle(image, cx, cy, radius, color)
  local height = math.floor(radius * 1.5)
  local halfBase = math.floor(radius)
  for dy = -height, 0 do
    local progress = math.abs(dy) / height
    local currentHalfBase = math.floor(halfBase * (1 - progress))
    for dx = -currentHalfBase, currentHalfBase do
      local x = math.floor(cx + dx)
      local y = math.floor(cy + dy)
      if x >= 0 and x < image.width and y >= 0 and y < image.height then
        image:putPixel(x, y, color)
      end
    end
  end
end

-- Draw an ellipse
function Utils.drawEllipse(image, cx, cy, radius, color)
  local rx = math.floor(radius * 1.3)
  local ry = math.floor(radius * 0.7)
  for dy = -ry, ry do
    for dx = -rx, rx do
      if (dx*dx)/(rx*rx) + (dy*dy)/(ry*ry) <= 1 then
        local x = math.floor(cx + dx)
        local y = math.floor(cy + dy)
        if x >= 0 and x < image.width and y >= 0 and y < image.height then
          image:putPixel(x, y, color)
        end
      end
    end
  end
end

-- Draw a pentagon
function Utils.drawPentagon(image, cx, cy, radius, color)
  local vertices = {}
  for i = 0, 4 do
    local angle = math.rad(90 + i * 72)  -- 从顶部开始
    table.insert(vertices, {
      x = cx + math.cos(angle) * radius,
      y = cy - math.sin(angle) * radius
    })
  end
  
  -- 找到边界框
  local minX, maxX = math.huge, -math.huge
  local minY, maxY = math.huge, -math.huge
  for _, v in ipairs(vertices) do
    minX = math.min(minX, v.x)
    maxX = math.max(maxX, v.x)
    minY = math.min(minY, v.y)
    maxY = math.max(maxY, v.y)
  end
  
  -- 填充五边形
  for y = math.floor(minY), math.ceil(maxY) do
    for x = math.floor(minX), math.ceil(maxX) do
      if Utils.pointInPolygon(x, y, vertices) then
        if x >= 0 and x < image.width and y >= 0 and y < image.height then
          image:putPixel(x, y, color)
        end
      end
    end
  end
end

-- Check if point is inside polygon
function Utils.pointInPolygon(px, py, vertices)
  local inside = false
  local j = #vertices
  for i = 1, #vertices do
    local vi = vertices[i]
    local vj = vertices[j]
    if ((vi.y > py) ~= (vj.y > py)) and
       (px < (vj.x - vi.x) * (py - vi.y) / (vj.y - vi.y) + vi.x) then
      inside = not inside
    end
    j = i
  end
  return inside
end

-- Draw a simple circle
function Utils.drawCircle(image, cx, cy, radius, color)
  local radius2 = radius * radius
  for dy = -radius, radius do
      for dx = -radius, radius do
        if dx*dx + dy*dy <= radius2 then
          local x = math.floor(cx + dx)
          local y = math.floor(cy + dy)
          if x >= 0 and x < image.width and y >= 0 and y < image.height then
            image:putPixel(x, y, color)
          end
        end
      end
    end
end

-- Add bark texture (vertical noise)
function Utils.applyBarkTexture(image, trunkColor, shadowColor)
  local original = Image(image)
  for y = 0, image.height - 1 do
    for x = 0, image.width - 1 do
      if original:getPixel(x, y) == trunkColor.rgbaPixel then
        if math.random() < 0.15 then
          image:putPixel(x, y, shadowColor)
        end
      end
    end
  end
end

return Utils

--[[
  Core Generation Engine (v5.0) - L-system Based Tree Generation
  Author: wjwdive
--]]

local Core = {}

-- 全局缓存树干结构，用于增量更新
local cachedTrunkStructure = nil

-- L-system implementation
local function LSystem(axiom, rules, iterations, angle, length)
  local result = axiom
  for i = 1, iterations do
    local newResult = ""
    for j = 1, #result do
      local c = result:sub(j, j)
      newResult = newResult .. (rules[c] or c)
    end
    result = newResult
  end
  return result
end

-- Generate skeleton from L-system string
local function generateSkeleton(lsystemString, startX, startY, angle, length, initialWidth, widthReduction)
  local skeleton = {}
  local stack = {}
  local currentX, currentY = startX, startY
  local currentAngle = -90 -- Start facing up
  local currentWidth = initialWidth
  
  table.insert(skeleton, {x=currentX, y=currentY, width=currentWidth, isBranch=false})
  
  for i = 1, #lsystemString do
    local c = lsystemString:sub(i, i)
    if c == 'F' then
      -- Move forward and draw
      local rad = math.rad(currentAngle)
      local newX = currentX + math.cos(rad) * length
      local newY = currentY + math.sin(rad) * length
      currentWidth = currentWidth * widthReduction
      table.insert(skeleton, {x=newX, y=newY, width=currentWidth, isBranch=false})
      currentX, currentY = newX, newY
    elseif c == '+' then
      -- Turn right
      currentAngle = currentAngle + angle
    elseif c == '-' then
      -- Turn left
      currentAngle = currentAngle - angle
    elseif c == '[' then
      -- Save current state
      table.insert(stack, {x=currentX, y=currentY, angle=currentAngle, width=currentWidth})
    elseif c == ']' then
      -- Restore previous state
      local state = table.remove(stack)
      currentX, currentY = state.x, state.y
      currentAngle = state.angle
      currentWidth = state.width
      table.insert(skeleton, {x=currentX, y=currentY, width=currentWidth, isBranch=true})
    end
  end
  
  return skeleton
end

-- Poisson Disk Sampling for leaf distribution
local function poissonDiskSampling(width, height, radius, k)
  local grid = {}
  local points = {}
  local cellSize = radius / math.sqrt(2)
  local gridWidth = math.ceil(width / cellSize)
  local gridHeight = math.ceil(height / cellSize)
  
  -- Initialize grid
  for i = 1, gridWidth do
    grid[i] = {}
    for j = 1, gridHeight do
      grid[i][j] = nil
    end
  end
  
  -- Add first point
  local firstPoint = {x=math.random(width), y=math.random(height)}
  table.insert(points, firstPoint)
  local gridX = math.floor(firstPoint.x / cellSize) + 1
  local gridY = math.floor(firstPoint.y / cellSize) + 1
  grid[gridX][gridY] = firstPoint
  
  local activeList = {firstPoint}
  
  while #activeList > 0 do
    local randomIndex = math.random(#activeList)
    local currentPoint = activeList[randomIndex]
    local found = false
    
    for i = 1, k do
      local angle = math.random() * math.pi * 2
      local r = radius * (math.random() + 1)
      local newX = currentPoint.x + math.cos(angle) * r
      local newY = currentPoint.y + math.sin(angle) * r
      
      if newX >= 0 and newX < width and newY >= 0 and newY < height then
        local gridX = math.floor(newX / cellSize) + 1
        local gridY = math.floor(newY / cellSize) + 1
        local valid = true
        
        -- Check neighboring cells
        for dx = -1, 1 do
          for dy = -1, 1 do
            local checkX = gridX + dx
            local checkY = gridY + dy
            if checkX >= 1 and checkX <= gridWidth and checkY >= 1 and checkY <= gridHeight then
              local neighbor = grid[checkX][checkY]
              if neighbor then
                local distance = math.sqrt((newX - neighbor.x)^2 + (newY - neighbor.y)^2)
                if distance < radius then
                  valid = false
                  break
                end
              end
            end
          end
          if not valid then break end
        end
        
        if valid then
          local newPoint = {x=newX, y=newY}
          table.insert(points, newPoint)
          table.insert(activeList, newPoint)
          grid[gridX][gridY] = newPoint
          found = true
        end
      end
    end
    
    if not found then
      table.remove(activeList, randomIndex)
    end
  end
  
  return points
end

function Core.generate(data, Templates, Utils, updateType)
  local sprite = app.activeSprite
  if not sprite then return end

  local cel = app.activeCel
  if not cel then
    cel = sprite:newCel(app.activeLayer, app.activeFrame)
  end

  app.transaction(function()
    local canvasWidth = data.canvas_width or 64
    local canvasHeight = data.canvas_height or 64
    
    -- 随机生成时，随机化参数
    if updateType == "random" then
      data.trunk_height = math.random(30, 150)
      data.trunk_width = math.random(6, 20)
      data.trunk_points = math.random(3, 10)
      data.trunk_curve = math.random(2, 15)
      data.random_rotation = math.random(10, 50)
      data.random_scale = math.random(10, 40)
      data.random_offset = math.random(10, 40)
      data.light_dir = math.random(1, 3)
    end
    
    -- 处理更新类型
    local shouldRegenerateTrunk = (updateType == "full" or updateType == "trunk" or updateType == "random" or cachedTrunkStructure == nil or 
                                  cachedTrunkStructure.canvasWidth ~= canvasWidth or 
                                  cachedTrunkStructure.canvasHeight ~= canvasHeight)
    local shouldRegenerateFoliage = (updateType == "full" or updateType == "foliage" or updateType == "random")
    
    -- 如果当前sprite大小不匹配，调整sprite大小
    if sprite.width ~= canvasWidth or sprite.height ~= canvasHeight then
      sprite:resize(canvasWidth, canvasHeight)
      shouldRegenerateTrunk = true
      shouldRegenerateFoliage = true
    end
    
    local image
    local trunkPoints
    local branchStructure
    
    -- 1. 解析 UI 数据 (支持数字索引和字符串)
    local trunkColor = data.trunk_color or Color(135, 80, 50)
    local leafColor = data.leaf_color or Color(80, 150, 70)
    
    -- 从基础颜色派生多个阶梯颜色 (4-5种) 用于色块效果
    local function deriveSteppedColors(base)  
      local c = Color(base)
      -- 尝试获取RGB分量
      local r, g, b
      if c.red then
        r, g, b = c.red, c.green, c.blue
      elseif c.r then
        r, g, b = c.r, c.g, c.b
      else
        -- 默认值
        r, g, b = 80, 150, 70
      end
      
      -- 生成5种阶梯颜色 (暗到亮)，使用邻近色
      local colors = {}
      
      -- 最暗的阴影：降低亮度，稍微增加饱和度
      colors[1] = Color(
        math.max(0, r * 0.45),
        math.max(0, g * 0.45),
        math.max(0, b * 0.45)
      )
      
      -- 中等阴影：降低亮度
      colors[2] = Color(
        math.max(0, r * 0.65),
        math.max(0, g * 0.65),
        math.max(0, b * 0.65)
      )
      
      -- 基础色
      colors[3] = Color(r, g, b)
      
      -- 中等高光：增加亮度，稍微调整色相
      colors[4] = Color(
        math.min(255, r * 1.1),
        math.min(255, g * 1.1),
        math.min(255, b * 1.1)
      )
      
      -- 最亮的高光：增加亮度
      colors[5] = Color(
        math.min(255, r * 1.2),
        math.min(255, g * 1.2),
        math.min(255, b * 1.2)
      )
      
      return colors
    end
    
    local trunkColors = deriveSteppedColors(trunkColor)
    local leafColors = deriveSteppedColors(leafColor)

    -- 处理光照方向 (支持数字索引和字符串)
    local lightDir = { x = -1, y = -1 } -- 默认左上
    local lightDirVal = data.light_dir
    if type(lightDirVal) == "number" then
      -- 数字索引: 1=左上, 2=正上, 3=右上
      if lightDirVal == 2 then lightDir = { x = 0, y = -1 }
      elseif lightDirVal == 3 then lightDir = { x = 1, y = -1 } end
    else
      -- 字符串
      if lightDirVal == "正上方" then lightDir = { x = 0, y = -1 }
      elseif lightDirVal == "右上方" then lightDir = { x = 1, y = -1 } end
    end

    -- 处理叶簇形状 (支持数字索引和字符串)
    local foliageShape = "圆形"
    local foliageShapeVal = data.foliage_shape
    if type(foliageShapeVal) == "number" then
      local shapeOptions = { "圆形", "方形", "矩形", "三角形", "椭圆" }
      foliageShape = shapeOptions[foliageShapeVal] or "圆形"
    else
      foliageShape = foliageShapeVal or "圆形"
    end

    -- 2. 绘制树干和分支 (简化的2D像素树绘制)
    local trunkHeight = data.trunk_height or 80
    local baseWidth = data.trunk_width or 8
    local curveOffset = data.trunk_curve or 5
    local branchDensity = data.branch_density or 4
    
    -- 确保树干高度不超过画布高度（留出底部20像素空间）
    trunkHeight = math.min(trunkHeight, canvasHeight - 25)
    -- 确保树干高度不小于30像素
    trunkHeight = math.max(trunkHeight, 30)
    
    -- 树干宽度限制：根部宽度不超过画布宽度的1/6
    baseWidth = math.min(baseWidth, canvasWidth / 6)
    -- 确保根部宽度不小于4像素
    baseWidth = math.max(baseWidth, 4)
    
    local topWidth = math.max(2, baseWidth * 0.4)
    
    if shouldRegenerateTrunk then
      image = Image(canvasWidth, canvasHeight)
      trunkPoints = {}
      local startX = canvasWidth / 2
      local startY = canvasHeight - 20

      local currentX, currentY = startX, startY
      table.insert(trunkPoints, { x = currentX, y = currentY, w = baseWidth })
      
      local numSegments = 8
      local segHeight = trunkHeight / numSegments
      for i = 1, numSegments do
        local t = i / numSegments
        currentY = currentY - segHeight
        -- 增加随机弯曲，但保持整体向上的趋势
        local curve = (math.random() - 0.5) * curveOffset * (1 - t * 0.7)  -- 越往上弯曲越小
        currentX = currentX + curve
        -- 确保树干在画布范围内
        currentX = math.max(baseWidth, math.min(canvasWidth - baseWidth, currentX))
        
        -- 树干宽度从根部到顶部的线性渐变
        local w = baseWidth * (1 - t) + topWidth * t
        table.insert(trunkPoints, { x = currentX, y = currentY, w = w })
        
        -- 绘制当前段
        local segColor = trunkColors[3]  -- 基础色
        Utils.drawTaperedSegment(image, trunkPoints[i].x, trunkPoints[i].y, 
                                 trunkPoints[i+1].x, trunkPoints[i+1].y, 
                                 trunkPoints[i].w, trunkPoints[i+1].w, segColor)
      end
      
      -- 生成并缓存分支结构
      branchStructure = {}
      local startBranchIdx = math.ceil(#trunkPoints * 0.25)
      local endBranchIdx = math.floor(#trunkPoints * 0.9)
      local branchCount = 0
      
      -- 只有当分支密度大于2时才生成分支
      if branchDensity > 2 then
        -- 计算分支概率因子
        local densityFactor = (branchDensity - 2) / 8  -- 8是最大密度(10)减去2
        
        -- 根据分支密度计算最大分支数量
        local maxBranches = math.min(10, math.ceil(densityFactor * 8) + 2)
        
        for m = startBranchIdx, endBranchIdx do
          -- 越往上，分支概率越高
          local baseProbability = 0.2 + densityFactor * 0.6
          local heightFactor = (m - startBranchIdx) / (endBranchIdx - startBranchIdx)
          local branchProbability = baseProbability + heightFactor * 0.3
          
          if math.random() < branchProbability or m == endBranchIdx then
            local p = trunkPoints[m]
            local side = (math.random() > 0.5 and 1 or -1)
            local angle = -90 + side * math.random(15, 45)
            local length = trunkHeight * (0.2 + math.random() * 0.2)
            local branchWidth = math.max(2, p.w * 0.7)
            
            table.insert(branchStructure, {
              x = p.x,
              y = p.y,
              angle = angle,
              length = length,
              width = branchWidth
            })
            
            branchCount = branchCount + 1
            
            -- 限制总分支数量
            if branchCount >= maxBranches then
              break
            end
          end
        end
      end
      
      -- 绘制分支
      for _, branch in ipairs(branchStructure or {}) do
        drawBranch(branch.x, branch.y, branch.angle, branch.length, 1, branch.width)
      end
    else
      -- 使用缓存的树干结构
      trunkPoints = cachedTrunkStructure.points
      branchStructure = cachedTrunkStructure.branchStructure
      
      -- 对于 foliage 更新，只绘制树叶，不重绘树干和分支
      if updateType == "foliage" then
        -- 复制当前画布内容
        image = cel.image:clone()
        -- 清空树叶（使用透明色填充）
        local transparent = Color(0, 0, 0, 0)
        for x = 0, image.width - 1 do
          for y = 0, image.height - 1 do
            local pixel = image:getPixel(x, y)
            -- 检查是否是树叶颜色（简化处理，实际可能需要更精确的检测）
            if pixel.r >= 70 and pixel.g >= 140 and pixel.b >= 60 then
              image:putPixel(x, y, transparent)
            end
          end
        end
      else
        -- 其他更新类型，重新绘制树干
        image = Image(canvasWidth, canvasHeight)
        for i = 1, #trunkPoints - 1 do
          local segColor = trunkColors[3]  -- 基础色
          Utils.drawTaperedSegment(image, trunkPoints[i].x, trunkPoints[i].y, 
                                   trunkPoints[i+1].x, trunkPoints[i+1].y, 
                                   trunkPoints[i].w, trunkPoints[i+1].w, segColor)
        end
        
        -- 绘制分支
        for _, branch in ipairs(branchStructure or {}) do
          drawBranch(branch.x, branch.y, branch.angle, branch.length, 1, branch.width)
        end
      end
    end

    -- 3. 绘制分支和树叶
    -- 根据树木高度调整树叶团簇大小（树木越高，团簇越大）
    local heightFactor = trunkHeight / 80  -- 以80为基准高度
    local fSize = (data.foliage_size or 12) * heightFactor
    local fDensity = data.foliage_density or 6
    
    -- 限制树叶团簇大小
    fSize = math.min(fSize, canvasWidth / 6)
    fSize = math.max(fSize, 4)
    
    -- 获取树叶形状
    local foliageShape = data.foliage_shape or "圆形"
    
    -- 绘制分支（只绘制分支，不绘制树叶）
    local function drawBranch(x, y, angle, length, depth, branchWidth)
      local rad = math.rad(angle)
      local ex = x + math.cos(rad) * length
      local ey = y + math.sin(rad) * length
      
      -- 确保树枝在画布范围内
      ex = math.max(0, math.min(image.width - 1, ex))
      ey = math.max(0, math.min(image.height - 1, ey))
      
      -- 树枝宽度随深度递减
      local endWidth = math.max(1, branchWidth * 0.7)
      Utils.drawTaperedSegment(image, x, y, ex, ey, branchWidth, endWidth, trunkColors[3])
      
      -- 到达末端或深度限制，终止递归
      if depth > 2 or length < 15 then
        return
      end
      
      -- 产生分叉
      local numForks = math.random(1, 2)
      for k = 1, numForks do
        local nextAngle = angle + (math.random(15, 45) * (math.random() > 0.5 and 1 or -1))
        local nextLength = length * (0.6 + math.random() * 0.3)
        local nextWidth = math.max(1, branchWidth * 0.8)
        drawBranch(ex, ey, nextAngle, nextLength, depth + 1, nextWidth)
      end
    end
    
    -- 绘制树叶（在分支上）
    local function drawLeavesOnBranch(x, y, angle, length, depth, branchWidth)
      local rad = math.rad(angle)
      local ex = x + math.cos(rad) * length
      local ey = y + math.sin(rad) * length
      
      -- 确保树枝在画布范围内
      ex = math.max(0, math.min(image.width - 1, ex))
      ey = math.max(0, math.min(image.height - 1, ey))
      
      -- 到达末端或深度限制，终止递归
      if depth > 2 or length < 15 then
        -- 只有当密度大于2时才绘制树叶
        if fDensity > 2 then
          -- 计算基础密度因子（从0开始逐步增加）
          local densityFactor = (fDensity - 2) / 13  -- 13是最大密度(15)减去2
          
          -- 密度较低时，只在部分末端绘制树叶
          if fDensity <= 4 then
            -- 随机决定是否绘制树叶（密度越低，概率越小）
            local drawLeaves = math.random() < (densityFactor * 2.5)  -- 密度3时约38%概率，密度4时约58%概率
            if not drawLeaves then
              return
            end
          end
          
          -- 根据密度因子计算末端叶簇数量，确保逐步增加
          local baseCount = math.ceil(densityFactor * 3)
          local randomCount = math.random(0, math.ceil(densityFactor * 2))
          local endClusterCount = math.max(1, baseCount + randomCount)
          endClusterCount = math.min(endClusterCount, 5)  -- 限制最大数量
          
          -- 在末端绘制叶簇
          for j = 1, endClusterCount do
            local r = math.random(math.max(4, fSize - 1), fSize + 3)
            local angleOffset = math.random() * math.pi * 2
            local dist = math.random(r * 0.3, r * 0.8)
            local ox = math.cos(angleOffset) * dist
            local oy = math.sin(angleOffset) * dist
            
            local leafX = ex + ox
            local leafY = ey + oy
            local maxRadius = r * 1.5
            if leafX >= maxRadius and leafX <= image.width - maxRadius and leafY >= maxRadius and leafY <= image.height - maxRadius then
              Utils.drawFoliageCluster(image, leafX, leafY, r, leafColors, lightDir, foliageShape)
            end
          end
        end
        return
      end
      
      -- 只有当密度大于2时才绘制树叶
      if fDensity > 2 then
        -- 计算基础密度因子（从0开始逐步增加）
        local densityFactor = (fDensity - 2) / 13  -- 13是最大密度(15)减去2
        
        -- 根据密度因子计算叶簇数量，确保逐步增加
        local baseClusters = math.ceil(length / (30 - fDensity * 0.8))
        local randomClusters = math.random(0, math.ceil(densityFactor * 3))  -- 随密度增加而增加
        local numClusters = math.min(baseClusters + randomClusters, 8)  -- 限制最大数量
        
        -- 密度较低时，只在部分树枝上绘制树叶
        if fDensity <= 4 then
          -- 随机决定是否绘制树叶（密度越低，概率越小）
          local drawLeaves = math.random() < (densityFactor * 2)  -- 密度3时约30%概率，密度4时约45%概率
          if not drawLeaves then
            return
          end
        end
        
        -- 在树枝上分散绘制多个叶簇（覆盖大部分枝干）
        for i = 1, numClusters do
          local t = i / (numClusters + 1)  -- 在树枝上均匀分布
          local bx = x + (ex - x) * t + (math.random() - 0.5) * 10  -- 添加随机偏移
          local by = y + (ey - y) * t + (math.random() - 0.5) * 10
          local r = math.random(math.max(3, fSize - 2), fSize + 2)
          
          local maxRadius = r * 1.5
          if bx >= maxRadius and bx <= image.width - maxRadius and by >= maxRadius and by <= image.height - maxRadius then
            Utils.drawFoliageCluster(image, bx, by, r, leafColors, lightDir, foliageShape)
          end
        end
      end
      
      -- 产生分叉
      local numForks = math.random(1, 2)
      for k = 1, numForks do
        local nextAngle = angle + (math.random(15, 45) * (math.random() > 0.5 and 1 or -1))
        local nextLength = length * (0.6 + math.random() * 0.3)
        local nextWidth = math.max(1, branchWidth * 0.8)
        drawLeavesOnBranch(ex, ey, nextAngle, nextLength, depth + 1, nextWidth)
      end
    end

    -- 绘制分支（使用缓存的分支结构）
    if shouldRegenerateTrunk then
      for _, branch in ipairs(branchStructure or {}) do
        drawBranch(branch.x, branch.y, branch.angle, branch.length, 1, branch.width)
      end
    end

    -- 绘制树叶（在分支上）
    for _, branch in ipairs(branchStructure or {}) do
      drawLeavesOnBranch(branch.x, branch.y, branch.angle, branch.length, 1, branch.width)
    end

    -- 在树干顶端添加树叶（根据密度）
    if fDensity > 2 then
      -- 计算基础密度因子（从0开始逐步增加）
      local densityFactor = (fDensity - 2) / 13  -- 13是最大密度(15)减去2
      
      -- 密度较低时，可能不在顶端绘制树叶
      if fDensity <= 4 then
        -- 随机决定是否绘制树叶（密度越低，概率越小）
        local drawLeaves = math.random() < (densityFactor * 3)  -- 密度3时约46%概率，密度4时约69%概率
        if not drawLeaves then
          return
        end
      end
      
      local topPoint = trunkPoints[#trunkPoints]
      if topPoint then
        -- 根据密度因子计算顶端叶簇数量，确保逐步增加
        local baseCount = math.ceil(densityFactor * 4)
        local randomCount = math.random(0, math.ceil(densityFactor * 2))
        local clusterCount = math.max(1, baseCount + randomCount)
        clusterCount = math.min(clusterCount, 8)  -- 限制最大数量
        
        for i = 1, clusterCount do
          local r = math.random(fSize - 1, fSize + 4)
          local angleOffset = math.random() * math.pi * 2
          local dist = math.random(r * 0.4, r * 1.0)
          local leafX = topPoint.x + math.cos(angleOffset) * dist
          local leafY = topPoint.y + math.sin(angleOffset) * dist
          local maxRadius = r * 1.5
          if leafX >= maxRadius and leafX <= image.width - maxRadius and leafY >= maxRadius and leafY <= image.height - maxRadius then
            Utils.drawFoliageCluster(image, leafX, leafY, r, leafColors, lightDir, foliageShape)
          end
        end
      end
    end

    -- 缓存树干结构用于增量更新
    if shouldRegenerateTrunk then
      cachedTrunkStructure = {
        points = trunkPoints,
        branchStructure = branchStructure,
        canvasWidth = canvasWidth,
        canvasHeight = canvasHeight
      }
    end

    -- 4. 树干纹理后处理 (添加更多细节)
    Utils.applyBarkTexture(image, trunkColors[3], trunkColors[1])

    cel.image = image
  end)
  app.refresh()
end

return Core

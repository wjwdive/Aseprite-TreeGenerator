--[[
  Advanced UI Module (v6.0) - Three Segment Tab Layout
  Author: wjwdive
--]]

local UI = {}

function UI.show(onGenerate, Templates)
  local dlg = Dialog("Pixel Tree Generator (v6.0)")

  -- Helper function to trigger redraw with specific update type
  local function triggerRedraw(updateType)
    if onGenerate then
      onGenerate(dlg.data, updateType)
    end
  end

  -- Tab State Management
  local currentTab = 1  -- 1: 常规, 2: 树干, 3: 枝叶
  
  local function updateTabVisibility()
    local isGeneral = (currentTab == 1)
    local isTrunk = (currentTab == 2)
    local isFoliage = (currentTab == 3)
    
    -- 常规控件
    dlg:modify{ id="light_dir", visible=isGeneral }
    dlg:modify{ id="canvas_width", visible=isGeneral }
    dlg:modify{ id="canvas_height", visible=isGeneral }
    
    -- 树干控件
    dlg:modify{ id="trunk_height", visible=isTrunk }
    dlg:modify{ id="trunk_width", visible=isTrunk }
    dlg:modify{ id="trunk_points", visible=isTrunk }
    dlg:modify{ id="trunk_curve", visible=isTrunk }
    dlg:modify{ id="branch_density", visible=isTrunk }
    dlg:modify{ id="trunk_color", visible=isTrunk }
    
    -- 枝叶控件
    dlg:modify{ id="leaf_color", visible=isFoliage }
    dlg:modify{ id="foliage_shape", visible=isFoliage }
    dlg:modify{ id="foliage_density", visible=isFoliage }
    dlg:modify{ id="foliage_size", visible=isFoliage }
    dlg:modify{ id="random_rotation", visible=isFoliage }
    dlg:modify{ id="random_scale", visible=isFoliage }
    dlg:modify{ id="random_offset", visible=isFoliage }
  end

  --------------------------------------------------
  -- 顶部标签页 (使用按钮组模拟)
  --------------------------------------------------
  dlg:button{ id="tab_general", text="常规", onclick=function() 
    currentTab = 1 
    updateTabVisibility() 
  end }
  dlg:button{ id="tab_trunk", text="树干", onclick=function() 
    currentTab = 2 
    updateTabVisibility() 
  end }
  dlg:button{ id="tab_foliage", text="枝叶", onclick=function() 
    currentTab = 3 
    updateTabVisibility() 
  end }
  dlg:separator()

  --------------------------------------------------
  -- 所有控件定义 (初始状态由 updateTabVisibility 管理)
  --------------------------------------------------
  
  -- [常规 General]
  dlg:combobox{ id="light_dir", label="光照方向:", options={ "左上方", "正上方", "右上方" }, selected=1, onchange=function() triggerRedraw("full") end }
  dlg:slider{ id="canvas_width", label="画布宽度:", min=16, max=256, value=128, onchange=function() triggerRedraw("full") end }
  dlg:slider{ id="canvas_height", label="画布高度:", min=16, max=256, value=128, onchange=function() triggerRedraw("full") end }

  -- [树干 Trunk]
  dlg:slider{ id="trunk_height", label="树干高度:", min=10, max=200, value=60, onchange=function() triggerRedraw("trunk") end }
  dlg:slider{ id="trunk_width", label="起始粗细:", min=2, max=40, value=12, onchange=function() triggerRedraw("trunk") end }
  dlg:slider{ id="trunk_points", label="分段数:", min=2, max=15, value=6, onchange=function() triggerRedraw("trunk") end }
  dlg:slider{ id="trunk_curve", label="弯曲度:", min=0, max=30, value=10, onchange=function() triggerRedraw("trunk") end }
  dlg:slider{ id="branch_density", label="分支密度:", min=0, max=10, value=4, onchange=function() triggerRedraw("trunk") end }
  dlg:color{ id="trunk_color", label="树干颜色:", color=Color(135, 80, 50), onchange=function() triggerRedraw("trunk") end }

  -- [枝叶 Foliage]
  dlg:color{ id="leaf_color", label="树叶颜色:", color=Color(80, 150, 70), onchange=function() triggerRedraw("foliage") end }
  dlg:combobox{ id="foliage_shape", label="团簇形状:", options={ "圆形", "方形", "矩形", "椭圆形", "三角形", "五角形" }, selected=1, onchange=function() triggerRedraw("foliage") end }
  dlg:slider{ id="foliage_density", label="树叶密度:", min=2, max=15, value=6, onchange=function() triggerRedraw("foliage") end }
  dlg:slider{ id="foliage_size", label="树叶大小:", min=4, max=20, value=10, onchange=function() triggerRedraw("foliage") end }
  dlg:slider{ id="random_rotation", label="随机旋转:", min=0, max=100, value=30, onchange=function() triggerRedraw("foliage") end }
  dlg:slider{ id="random_scale", label="随机压缩:", min=0, max=100, value=20, onchange=function() triggerRedraw("foliage") end }
  dlg:slider{ id="random_offset", label="随机偏移:", min=0, max=100, value=25, onchange=function() triggerRedraw("foliage") end }

  --------------------------------------------------
  -- 底部操作区
  --------------------------------------------------
  dlg:separator()
  dlg:button{ id="random_btn", text="随机生成", onclick=function() triggerRedraw("random") end }
  dlg:button{ id="close_btn", text="关闭", onclick=function() dlg:close() end }

  -- 初始化显示状态
  updateTabVisibility()

  -- 初始触发一次生成
  triggerRedraw()
  
  dlg:show{ wait=false }
end

return UI

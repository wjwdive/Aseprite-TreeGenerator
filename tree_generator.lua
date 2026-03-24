--[[
  Pixel Tree Generator - Main Entry (v3.1)
  Author: wjwdive
--]]

-- 强制打印启动信息，用于调试
print("--- Pixel Tree Generator Started ---")

local function getModule(name)
  local scriptPath = debug.getinfo(1).source:sub(2)
  local dir = app.fs.filePath(scriptPath)
  local path = app.fs.normalizePath(app.fs.joinPath(dir, "modules", name .. ".lua"))
  
  local f, err = loadfile(path)
  if f then 
    return f() 
  else
    print("Error loading module: " .. name .. " from path: " .. path)
    if err then print("Details: " .. err) end
    
    local status, mod = pcall(require, "modules." .. name)
    if status then return mod end
    
    print("Require fallback also failed for: " .. name)
    return nil
  end
end

-- Load all modules
local Templates = getModule("templates")
local Utils = getModule("utils")
local Core = getModule("core")
local UI = getModule("ui")

if not (Templates and Utils and Core and UI) then
  app.alert("致命错误：无法加载部分或全部模块。请查看 View > Console 了解详情。")
  return -- 停止执行
end

print("All modules loaded successfully.")

-- 检查当前是否在文档中
if not app.activeSprite then
  app.alert("提示：请先创建或打开一个图像文件 (Sprite) 才能生成树木。")
  return
end

print("Sprite active, launching UI...")

-- Launch UI
UI.show(function(data, updateType)
  Core.generate(data, Templates, Utils, updateType)
end, Templates)

print("--- Script Execution Finished ---")

--[[
  Professional Tree Templates (v2.0)
  Author: wjwdive
--]]

local Templates = {
  Oak = {
    displayName = "Oak (橡树)",
    trunk = {
      points = 8, -- Number of control points
      baseWidth = 12, -- in pixels
      topWidth = 4,
      curve = 15, -- max horizontal offset
      texture = "bark"
    },
    branches = {
      probability = 0.4,
      angleRange = { 20, 50 },
      maxDepth = 3,
      lengthDecay = 0.7
    },
    foliage = {
      blobsPerBranch = 4,
      radiusRange = { 6, 12 },
      density = 0.8
    },
    palette = {
      trunk = { 78, 52, 25 },
      trunkShadow = { 56, 38, 18 },
      foliage = { 34, 139, 34 },
      foliageHighlight = { 102, 187, 106 },
      foliageShadow = { 27, 94, 32 }
    }
  },
  Pine = {
    displayName = "Pine (松树)",
    trunk = {
      points = 12,
      baseWidth = 8,
      topWidth = 2,
      curve = 5,
      texture = "vertical"
    },
    branches = {
      probability = 0.8,
      angleRange = { 70, 90 },
      maxDepth = 2,
      lengthDecay = 0.6
    },
    foliage = {
      blobsPerBranch = 3,
      radiusRange = { 4, 8 },
      density = 0.9
    },
    palette = {
      trunk = { 62, 39, 35 },
      trunkShadow = { 33, 33, 33 },
      foliage = { 27, 94, 32 },
      foliageHighlight = { 102, 187, 106 },
      foliageShadow = { 13, 71, 161 }
    }
  },
  Birch = {
    displayName = "Birch (白桦)",
    trunk = {
      points = 6,
      baseWidth = 6,
      topWidth = 3,
      curve = 20,
      texture = "spots"
    },
    branches = {
      probability = 0.3,
      angleRange = { 15, 30 },
      maxDepth = 4,
      lengthDecay = 0.8
    },
    foliage = {
      blobsPerBranch = 5,
      radiusRange = { 5, 10 },
      density = 0.6
    },
    palette = {
      trunk = { 236, 239, 241 },
      trunkShadow = { 158, 158, 158 },
      foliage = { 139, 195, 74 },
      foliageHighlight = { 220, 237, 200 },
      foliageShadow = { 51, 105, 30 }
    }
  }
}

return Templates

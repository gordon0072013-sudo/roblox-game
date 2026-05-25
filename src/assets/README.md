# Assets

Brainrots are built procedurally at runtime by `LabService` from
`BrainrotData.luau`. To replace the placeholder primitives with real meshes:

1. Upload your mesh (or buy a free mesh from the Creator Marketplace).
2. In Roblox Studio, find the asset id (`rbxassetid://...`).
3. Either:
   - Add a `MeshId` attribute to the brainrot's `BrainrotData` entry and
     extend `buildBrainrotModel` in `LabService.luau` to spawn a `MeshPart`
     when an id is present, or
   - Drop the meshes here as `.rbxm` files and modify
     `default.project.json` to mount this folder under
     `ReplicatedStorage/Assets/Brainrots`.

The game ships fully playable with the procedural primitive look — visual
swaps are a polish pass, not a launch blocker.

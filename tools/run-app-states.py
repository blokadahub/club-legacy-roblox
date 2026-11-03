#!/usr/bin/env python3
"""Execute real App/Scope/UI state logic using a deterministic virtual clock.

Reuses the narrow Roblox stubs from runtime-smoke.luau. Scene is a lifecycle
double, so these tests do not execute Roblox, inspect frames or certify easing.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--runtime", required=True)
args = parser.parse_args()
prelude = (root / "tools/runtime-smoke.luau").read_text().split("-- MODULES", 1)[0]
setup = r'''
events.Ended = true
local constructInstance = Instance.new
function Instance.new(className)
    local object = constructInstance(className)
    if object:IsA('GuiButton') then object.Visible = true end
    if className == 'Sound' then object.IsLoaded = true; object.IsPlaying = false; object.TimePosition = 0 end
    return object
end
local now, queue, activeTweens = 0, {}, {}
local function later(duration, callback)
    local job = {at = now + duration, callback = callback}
    table.insert(queue, job)
    return job
end
task.delay = later
task.cancel = function(job) job.cancelled = true end
function services.TweenService:Create(object, info, goals)
    local tween = {Completed = signal(), PlaybackState = Enum.PlaybackState.Begin, target = object, goals = goals, duration = info.Time}
    function tween:Play()
        self.PlaybackState = Enum.PlaybackState.Playing
        self.start = now
        self.from = {}; for key in pairs(self.goals) do self.from[key] = self.target[key] end
        activeTweens[self] = true
        self.job = later(self.duration, function()
            activeTweens[self] = nil
            for key, value in pairs(self.goals) do self.target[key] = value end
            self.PlaybackState = Enum.PlaybackState.Completed
            self.Completed:Fire(self.PlaybackState)
        end)
    end
    function tween:Cancel()
        if self.job then self.job.cancelled = true end
        activeTweens[self] = nil
        self.PlaybackState = Enum.PlaybackState.Cancelled
        self.Completed:Fire(self.PlaybackState)
    end
    return tween
end
local function interpolate(time)
    for tween in pairs(activeTweens) do
        local alpha = math.clamp((time - tween.start) / math.max(tween.duration, 0.0001), 0, 1)
        for key, value in pairs(tween.goals) do
            if type(value) == 'number' and type(tween.from[key]) == 'number' then
                tween.target[key] = tween.from[key] + (value - tween.from[key]) * alpha
            end
        end
    end
end
local function advance(seconds)
    local target = now + seconds
    while true do
        local nextJob, index
        for i, job in ipairs(queue) do
            if not job.cancelled and job.at <= target + 0.00000001 and (not nextJob or job.at < nextJob.at) then nextJob, index = job, i end
        end
        if not nextJob then break end
        table.remove(queue, index)
        now = nextJob.at
        interpolate(now)
        nextJob.callback()
    end
    now = target
    interpolate(now)
end
function methods:GetAttributeChangedSignal(key)
    if not self._events['Attribute_' .. key] then self._events['Attribute_' .. key] = signal() end
    return self._events['Attribute_' .. key]
end
function methods:GetPropertyChangedSignal(key)
    if not self._events['Property_' .. key] then self._events['Property_' .. key] = signal() end
    return self._events['Property_' .. key]
end
function methods:FindFirstChildOfClass(className)
    for _, child in ipairs(self:GetChildren()) do if child:IsA(className) then return child end end
    return nil
end
local workspace = Instance.new('Workspace')
workspace.CurrentCamera = Instance.new('Camera')
workspace.CurrentCamera.ViewportSize = Vector2.new(1600, 900)
services.Workspace = workspace
services.SoundService = Instance.new('SoundService')
function methods:Play() assert(self.ClassName == 'Sound'); self.IsPlaying = true end
function methods:Pause() assert(self.ClassName == 'Sound'); self.IsPlaying = false end
function methods:Resume() assert(self.ClassName == 'Sound'); self.IsPlaying = true end
function methods:Stop() assert(self.ClassName == 'Sound'); self.IsPlaying = false; self.TimePosition = 0 end
services.Players = {LocalPlayer = Instance.new('Player')}
local playerGui = Instance.new('PlayerGui'); playerGui.Parent = services.Players.LocalPlayer
services.GuiService = {GetGuiInset = function() return Vector2.new(), Vector2.new() end}
services.StarterGui = {SetCoreGuiEnabled = function() end}
services.UserInputService.GetFocusedTextBox = function() return nil end
services.UserInputService.GamepadEnabled = true
services.Lighting = Instance.new('Lighting')
services.RunService = {RenderStepped = signal(), Heartbeat = signal()}
'''
paths = sorted((root / "src/shared").glob("*.luau"))
paths += [root / f"src/client/{name}.luau" for name in ("Scope", "Rig", "UI", "Soundtrack", "MenuAvatar", "HomeHUD", "App")]
paths += sorted((root / "src/client/Screens").glob("*.luau"))
paths.append(root / "src/client/Scene.luau")
parts = ["local factories, moduleNodes, cache = {}, {}, {}\nlocal require\n"]
parts.append("local clientRoot = Instance.new('Folder')\nlocal sharedRoot = Instance.new('Folder'); sharedRoot.Name = 'CL27'; sharedRoot.Parent = services.ReplicatedStorage\n")
parts.append("local folders = {['src/client'] = clientRoot, ['src/shared'] = sharedRoot}\n")
scene = """local Scene = {}
function Scene.new(settings)
    local self = {settings = settings, shows = {}, updates = 0}
    function self:Show(mode) table.insert(self.shows, mode); self.mode = mode end
    function self:UpdateClubs() self.updates += 1 end
    function self:ApplySettings(value) self.settings = value end
    function self:Destroy() self.destroyed = true end
    services.lastScene = self
    return self
end
return Scene"""
parts.append("do local node = Instance.new('ModuleScript'); node.Name = 'Scene'; node.Parent = clientRoot; node:SetAttribute('ModulePath', 'SceneDouble'); moduleNodes.SceneDouble = node end\n")
parts.append("factories.SceneDouble = function()\n" + scene + "\nend\n")
for path in paths:
    relative = path.relative_to(root).as_posix()
    parent = path.parent.relative_to(root).as_posix()
    if parent == "src/client/Screens":
        parts.append("if not folders['src/client/Screens'] then local folder = Instance.new('Folder'); folder.Name = 'Screens'; folder.Parent = clientRoot; folders['src/client/Screens'] = folder end\n")
    name = "SceneReal" if path.stem == "Scene" else path.stem
    parts.append(f"do local node = Instance.new('ModuleScript'); node.Name = '{name}'; node.Parent = folders['{parent}']; node:SetAttribute('ModulePath', '{relative}'); moduleNodes['{relative}'] = node end\n")
    parts.append(f"factories['{relative}'] = function(script)\n{path.read_text()}\nend\n")
parts.append("require = function(node) assert(typeof(node) == 'Instance' and node:IsA('ModuleScript')); local path = node:GetAttribute('ModulePath'); if cache[path] == nil then cache[path] = assert(factories[path], 'Missing factory: ' .. tostring(path))(node) end; return cache[path] end\n")
spec = (root / "tools/app-states.spec.luau").read_text()
with tempfile.TemporaryDirectory(prefix="cl27-app-") as folder:
    generated = Path(folder) / "app-check.luau"
    generated.write_text(prelude + setup + "\n".join(parts) + spec)
    result = subprocess.run([str(Path(args.runtime).resolve()), str(generated)])
raise SystemExit(result.returncode)

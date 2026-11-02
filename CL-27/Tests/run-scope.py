"""Exercise the real lifecycle module against an explicit TweenService double."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
executable = sys.argv[1] if len(sys.argv) > 1 else "/workspace/tools/luau/luau"
preamble = '''
local function signal()
    local listeners = {}
    local object = {}
    function object:Connect(callback)
        local record = {callback=callback,connected=true}
        table.insert(listeners,record)
        return {Disconnect=function() record.connected=false end}
    end
    function object:Fire(...)
        for _, record in ipairs(listeners) do if record.connected then record.callback(...) end end
    end
    return object
end
local TweenService = {created=0}
function TweenService:Create(object,info,properties)
    self.created += 1
    local tween = {Completed=signal()}
    function tween:Play() self.played=true end
    function tween:Cancel() self.canceled=true end
    return tween
end
local game = {GetService=function(_,name) assert(name=="TweenService"); return TweenService end}
local TweenInfo = {new=function(...) return {...} end}
local Enum = {EasingStyle={Quart="Quart"}, EasingDirection={Out="Out"}}
'''
script = preamble + "\nlocal Scope=(function()\n" + (root / "Animations/Scope.luau").read_text() + "\nend)()\nlocal spec=(function()\n" + (root / "Tests/Scope.spec.luau").read_text() + "\nend)()\nspec(Scope,TweenService,signal)\n"
with tempfile.NamedTemporaryFile(mode="w", suffix=".luau", encoding="utf-8") as file:
    file.write(script)
    file.flush()
    result = subprocess.run([executable, file.name], check=False)
raise SystemExit(result.returncode)

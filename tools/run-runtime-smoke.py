#!/usr/bin/env python3
"""Run real Luau modules using narrow Roblox stubs; never renders Roblox.

Requires the official Luau CLI. Embeds sources unchanged in isolated module
factories and resolves ModuleScript-style requires through a generated hierarchy.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--runtime", required=True, help="Path to official luau executable")
args = parser.parse_args()
paths = sorted((root / "src/shared").glob("*.luau"))
paths += [root / f"src/client/{name}.luau" for name in ("Scope", "Rig", "UI", "SettingsIcons")]
paths += sorted((root / "src/client/Screens").glob("*.luau"))
parts = ["local factories, moduleNodes, cache = {}, {}, {}\nlocal require\n"]
parts.append("local clientRoot = Instance.new('Folder')\nlocal sharedRoot = Instance.new('Folder'); sharedRoot.Name = 'CL27'; sharedRoot.Parent = services.ReplicatedStorage\n")
parts.append("local folders = {['src/client'] = clientRoot, ['src/shared'] = sharedRoot}\n")
for path in paths:
    relative = path.relative_to(root).as_posix()
    parent = path.parent.relative_to(root).as_posix()
    if parent == "src/client/Screens" and parent not in {"src/client", "src/shared"}:
        # Creating this repeatedly would erase an existing hierarchy.
        parts.append("if not folders['src/client/Screens'] then local folder = Instance.new('Folder'); folder.Name = 'Screens'; folder.Parent = clientRoot; folders['src/client/Screens'] = folder end\n")
    parts.append(f"do local node = Instance.new('ModuleScript'); node.Name = '{path.stem}'; node.Parent = folders['{parent}']; node:SetAttribute('ModulePath', '{relative}'); moduleNodes['{relative}'] = node end\n")
    parts.append(f"factories['{relative}'] = function(script)\n{path.read_text()}\nend\n")
parts.append("require = function(node) assert(typeof(node) == 'Instance' and node:IsA('ModuleScript'), 'Expected ModuleScript'); local path = node:GetAttribute('ModulePath'); if cache[path] == nil then cache[path] = assert(factories[path], 'Missing module factory: ' .. tostring(path))(node) end; return cache[path] end\n")
harness = (root / "tools/runtime-smoke.luau").read_text()
source = harness.replace("-- MODULES", "\n".join(parts))
with tempfile.TemporaryDirectory(prefix="cl27-runtime-") as folder:
    generated = Path(folder) / "runtime-check.luau"
    generated.write_text(source)
    result = subprocess.run([str(Path(args.runtime).resolve()), str(generated)])
raise SystemExit(result.returncode)

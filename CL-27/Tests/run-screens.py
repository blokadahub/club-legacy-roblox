#!/usr/bin/env python3
"""Run screen construction and callback checks using Luau and explicit UI doubles.

Does not validate Roblox APIs, visual layout, interaction devices or rendering.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
executable = sys.argv[1] if len(sys.argv) > 1 else "/workspace/tools/luau/luau"
harness = (root / "Tests/ScreenHarness.luau").read_text()
globals_list = "UDim, UDim2, Vector2, Vector3, Color3, Enum, ColorSequence, NumberSequence, ColorSequenceKeypoint, NumberSequenceKeypoint".split(", ")
chunks = ["local Harness = (function()\n" + harness + "\nend)()\n"]
chunks += [f"local {name} = Harness.globals.{name}\n" for name in globals_list]
chunks += ["local data = (function()\n" + (root / "Data/Career.luau").read_text() + "\nend)()\nlocal screens = {}\n"]
for path in sorted((root / "Screens").glob("*.luau")):
    chunks += [f"screens.{path.stem} = (function()\n{path.read_text()}\nend)()\n"]
for index, name in enumerate(("ScreenInteractions.luau", "AdditionalInteractions.luau")):
    suite = root / "Tests" / name
    if suite.exists():
        chunks += [f"local suite{index} = (function()\n{suite.read_text()}\nend)()\nsuite{index}(Harness, screens, data)\n"]
with tempfile.TemporaryDirectory(prefix="cl27-screens-") as folder:
    path = Path(folder) / "screens.luau"
    path.write_text("\n".join(chunks))
    result = subprocess.run([executable, str(path)], check=False)
    sys.exit(result.returncode)

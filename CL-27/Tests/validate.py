"""Compilation, semantic/callback tests and both isolated Rojo artifact checks.
This runner does not run the Roblox engine or measure visual quality/FPS.
"""
from pathlib import Path
import argparse
import subprocess
import sys
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument("--tools", type=Path, default=Path("/tmp/cl27-tools"))
parser.add_argument("--output", type=Path, default=Path("/tmp/cl27-build"))
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
luau = args.tools.resolve() / "luau/luau"
compiler = args.tools.resolve() / "luau/luau-compile"
rojo = args.tools.resolve() / "rojo-7.7.1/rojo"
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)


def run(*command, **kwargs):
    subprocess.run([str(arg) for arg in command], cwd=root, check=True, **kwargs)


for path in sorted((root / "CL-27").rglob("*.luau")):
    run(compiler, "--null", path, stdout=subprocess.DEVNULL)
print("Sintaxe Luau aprovada.", flush=True)
run(sys.executable, "CL-27/Tests/run-data.py", "--luau", luau)
run(sys.executable, "CL-27/Tests/run-screens.py", luau)
run(sys.executable, "CL-27/Tests/run-scope.py", luau)
run(rojo, "build", "cl27.project.json", "--output", output / "cl27.rbxlx")
run(rojo, "build", "default.project.json", "--output", output / "club-legacy.rbxlx")

expected = {p.stem: p.read_text(encoding="utf-8") for p in (root / "CL-27").rglob("*.luau") if "Tests" not in p.parts and p.name != "Main.client.luau"}
expected["CL27"] = (root / "CL-27/Main.client.luau").read_text(encoding="utf-8")
found = {}
tree = ET.parse(output / "cl27.rbxlx")
for item in tree.iter("Item"):
    assert item.get("class") not in ("Script", "RemoteEvent", "RemoteFunction"), "CL 27 deve ser inteiramente local"
    if item.get("class") in ("LocalScript", "ModuleScript"):
        props = item.find("Properties")
        name = props.find("string[@name='Name']").text
        source = props.find("string[@name='Source']").text
        assert name not in found, f"Script duplicado: {name}"
        found[name] = source
assert found == expected, "O artefato CL 27 não corresponde exatamente aos módulos de origem"
original = ET.parse(output / "club-legacy.rbxlx")
names = [node.text for node in original.findall(".//string[@name='Name']")]
assert "CL27" not in names, "Os projetos devem permanecer independentes"
print(f"Artefatos independentes validados; {len(found)} scripts CL 27 conferidos. Saída: {output}")

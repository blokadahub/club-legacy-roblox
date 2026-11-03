#!/usr/bin/env python3
"""Structural, numeric geometry and real Luau lifecycle tests; never a renderer."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--runtime", required=True)
parser.add_argument("--api-dump")
args = parser.parse_args()
runtime = Path(args.runtime).resolve()
sources = sorted((ROOT / "src").glob("*.luau"))
assert len(sources) == 6
project = json.loads((ROOT / "default.project.json").read_text())
mapped = []


def walk(node):
    if isinstance(node, dict):
        if "$path" in node:
            path = node["$path"]
            assert path.startswith(("src/", ".generated/")), f"Experiment escaped: {path}"
            if path.startswith("src/"):
                assert (ROOT / path).is_file()
                mapped.append((ROOT / path).resolve())
        for value in node.values():
            walk(value)


walk(project)
assert set(mapped) == set(sources)
names = {p.name.removesuffix(".luau").removesuffix(".client").removesuffix(".server") for p in sources}
for path in sources:
    text = path.read_text()
    for name in re.findall(r"require\(script.Parent.(\w+)\)", text):
        assert name in names, f"Broken require: {name}"
    assert not re.search(r"rbxassetid://|require\(\d+|HttpService|InsertService|SoundId", text)

data = json.loads(subprocess.check_output([str(runtime), str(ROOT / "tools/export.luau")], text=True))
if args.api_dump:
    api_path = Path(args.api_dump)
    api = json.loads(api_path.read_text())
    classes = {c["Name"]: c for c in api["Classes"]}
    enums = {e["Name"]: {i["Name"]: i["Value"] for i in e["Items"]} for e in api["Enums"]}
    for path in sources:
        text = path.read_text()
        for group, item in re.findall(r"Enum\.(\w+)\.(\w+)", text):
            assert item in enums.get(group, {}), f"Invalid Enum.{group}.{item}"
        for name in re.findall(r'Instance.new\("(\w+)"', text):
            assert name in classes, f"Invalid class {name}"

    def class_props(name):
        cls = classes[name]
        props = {p["Name"] for p in cls["Members"] if p["MemberType"] == "Property"}
        return props | (class_props(cls["Superclass"]) if cls["Superclass"] in classes else set())

    def api_project(node):
        if isinstance(node, dict):
            if cls := node.get("$className"):
                assert cls in classes
                assert set(node.get("$properties", {})) <= class_props(cls)
            for value in node.values():
                api_project(value)

    api_project(project)
    for parts in data["profiles"].values():
        for p in parts:
            assert p["className"] in classes and p["material"] in enums["Material"]
            if light := p.get("light"):
                assert light["kind"] in classes
                assert light.get("face", "Bottom") in enums["NormalId"]
    for cls, props in {
        "Lighting": "Ambient OutdoorAmbient Brightness ClockTime ExposureCompensation GlobalShadows EnvironmentDiffuseScale EnvironmentSpecularScale ShadowSoftness FogColor FogStart FogEnd",
        "Part": "CFrame Size Color Material Reflectance CastShadow Anchored CanCollide CanTouch CanQuery TopSurface BottomSurface",
        "Camera": "CFrame Focus CameraType FieldOfView FieldOfViewMode",
        "SurfaceLight": "Color Brightness Range Shadows Face Angle",
    }.items():
        assert set(props.split()) <= class_props(cls)
    assert {m: enums["Material"][m] for m in ("Concrete", "Metal", "Neon")} == {"Concrete": 816, "Metal": 1088, "Neon": 288}
    print(f"PASS API snapshot: classes, dynamic descriptors, enums, properties; SHA256 {hashlib.sha256(api_path.read_bytes()).hexdigest()}")
expected = {"Low": (238, 12), "Medium": (334, 20), "High": (366, 36)}
numeric = 0
for quality, parts in data["profiles"].items():
    assert (len(parts), sum("light" in p for p in parts)) == expected[quality]
    assert len({p["name"] for p in parts}) == len(parts)
    assert sum(p["className"] == "WedgePart" for p in parts) == 32
    for p in parts:
        assert all(math.isfinite(v) and v >= 0.04 for v in p["size"])
        assert all(math.isfinite(v) for v in p["frame"])
        assert p["material"] in ("Metal", "Concrete", "Neon")
        assert p["reflectance"] <= 0.04
        r = [p["frame"][i:i+3] for i in (3, 6, 9)]
        for i in range(3):
            for j in range(3):
                assert abs(sum(r[i][k]*r[j][k] for k in range(3)) - (1 if i == j else 0)) < 1e-8
                numeric += 1
        determinant = sum(r[0][j] * (r[1][(j+1)%3]*r[2][(j+2)%3]-r[1][(j+2)%3]*r[2][(j+1)%3]) for j in range(3))
        assert abs(determinant-1) < 1e-8, "Mirrored/invalid rotation"
        if light := p.get("light"):
            assert 0 < light["range"] <= 29 and 0 < light["brightness"] <= 1.6
        if p["name"].endswith("FloorSlab"):
            assert abs(p["frame"][1]+p["size"][1]/2) < 1e-8, "Uneven floor"
        if p["name"].endswith(("SlopedShell", "InclinedButtress", "TriangularPlateA", "TriangularPlateB")):
            assert abs(p["frame"][0]) > 13, "Wall structure intrudes into corridor"
    greens = [p for p in parts if p["name"].endswith("GreenBase")]
    assert len(greens) == 16 and {p["frame"][0] for p in greens} == {-16.03,16.03}
    assert len([p for p in parts if p["name"].endswith("OrangeCeilingFixture")]) == 8
    assert len([p for p in parts if p["name"].endswith("BlueUpperNeon")]) == 8
print(f"PASS structure + geometry: 6 isolated sources; {numeric} orthogonality checks; budgets, seams and source limits")

factories = []
for p in sources:
    name = p.name.removesuffix(".luau").removesuffix(".client").removesuffix(".server")
    factories.append(f"do local node=Instance.new('ModuleScript'); node.Name='{name}'; node.Parent=folder; nodes.{name}=node end\n")
    factories.append(f"factories.{name}=function(script)\n{p.read_text()}\nend\n")
spec = (ROOT / "tools/runtime.spec.luau").read_text().replace("-- MODULES", "".join(factories))
with tempfile.TemporaryDirectory(prefix="tunnel-tests-") as directory:
    generated = Path(directory) / "lifecycle.luau"
    generated.write_text(spec)
    subprocess.run([str(runtime), str(generated)], check=True)

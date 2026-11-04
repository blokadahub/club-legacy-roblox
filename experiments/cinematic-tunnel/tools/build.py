#!/usr/bin/env python3
"""Bake real geometry descriptors, compile with Rojo, validate the final XML.

No Roblox rendering, network calls, publication or dependencies outside stdlib.
"""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
MATERIALS = {"Concrete": 816, "Metal": 1088, "Neon": 288}
FACES = {"Right": 0, "Top": 1, "Back": 2, "Left": 3, "Bottom": 4, "Front": 5}


def run(*args):
    subprocess.run([str(a) for a in args], cwd=ROOT, check=True)


def export(runtime):
    return json.loads(subprocess.check_output([str(runtime), str(ROOT / "tools/export.luau")], text=True))


def prop(parent, kind, name, value):
    node = ET.SubElement(parent, kind, name=name)
    if kind in ("Vector3", "Color3", "CoordinateFrame"):
        keys = {"Vector3": ("X", "Y", "Z"), "Color3": ("R", "G", "B"),
                "CoordinateFrame": ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")}[kind]
        for key, entry in zip(keys, value, strict=True):
            ET.SubElement(node, key).text = format(entry, ".12g")
    else:
        node.text = str(value).lower() if isinstance(value, bool) else str(value)
    return node


def bake(parts, path, quality):
    xml = ET.Element("roblox", version="4")
    model = ET.SubElement(xml, "Item", {"class": "Model", "referent": "TunnelPreview"})
    prop(ET.SubElement(model, "Properties"), "string", "Name", "CinematicTunnelPreview")
    for index, data in enumerate(parts):
        item = ET.SubElement(model, "Item", {"class": data["className"], "referent": f"Part{index}"})
        p = ET.SubElement(item, "Properties")
        for kind, name, value in (
            ("string", "Name", data["name"]), ("Vector3", "size", data["size"]),
            ("CoordinateFrame", "CFrame", data["frame"]),
            ("Color3", "Color", [v / 255 for v in data["color"]]),
            ("token", "Material", MATERIALS[data["material"]]),
            ("float", "Reflectance", data["reflectance"]), ("bool", "CastShadow", data["shadow"]),
            ("bool", "Anchored", True), ("bool", "CanCollide", False),
            ("bool", "CanTouch", False), ("bool", "CanQuery", False),
            ("token", "TopSurface", 0), ("token", "BottomSurface", 0),
        ):
            prop(p, kind, name, value)
        if spec := data.get("light"):
            light = ET.SubElement(item, "Item", {"class": spec["kind"], "referent": f"Light{index}"})
            lp = ET.SubElement(light, "Properties")
            for kind, name, value in (
                ("string", "Name", "TunnelSource"), ("Color3", "Color", [v / 255 for v in spec["color"]]),
                ("float", "Brightness", spec["brightness"]), ("float", "Range", spec["range"]),
                ("bool", "Shadows", quality == "High" and spec["kind"] == "SurfaceLight"),
                ("bool", "Enabled", True),
            ):
                prop(lp, kind, name, value)
            if spec["kind"] == "SurfaceLight":
                prop(lp, "token", "Face", FACES[spec["face"]])
                prop(lp, "float", "Angle", spec["angle"])
    ET.ElementTree(xml).write(path, encoding="utf-8", xml_declaration=True)


def validate_place(path, descriptors, camera, quality):
    xml = ET.parse(path)
    items = list(xml.iter("Item"))
    classes = Counter(i.get("class") for i in items)
    assert classes["LocalScript"] == classes["Script"] == 1, classes
    parts = [i for i in items if i.get("class") in ("Part", "WedgePart")]
    assert len(parts) == len(descriptors), (len(parts), len(descriptors))
    by_name = {i.findtext("./Properties/string[@name='Name']"): i for i in parts}
    for data in descriptors:
        item = by_name[data["name"]]
        size = item.find("./Properties/Vector3[@name='size']")
        if size is None:
            size = item.find("./Properties/Vector3[@name='Size']")
        assert size is not None
        assert all(abs(float(n.text)-v) < 1e-4 for n, v in zip(size, data["size"], strict=True))
        cf = item.find("./Properties/CoordinateFrame[@name='CFrame']")
        assert cf is not None
        assert all(abs(float(n.text)-v) < 1e-4 for n, v in zip(cf, data["frame"], strict=True))
        color = item.find("./Properties/Color3uint8[@name='Color3uint8']")
        # Rojo normalizes the legacy Color property to packed Color3uint8.
        assert color is not None, "Rojo did not serialize part color"
        packed = int(color.text)
        assert [(packed >> shift) & 255 for shift in (16, 8, 0)] == data["color"]
        material = item.findtext("./Properties/token[@name='Material']")
        assert int(material) == MATERIALS[data["material"]]
        for name in ("Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow"):
            wanted = name == "Anchored" or name == "CastShadow" and data["shadow"]
            assert item.findtext(f"./Properties/bool[@name='{name}']") == str(wanted).lower()
        child_lights = [i for i in item.findall("Item") if i.get("class") in ("PointLight", "SurfaceLight")]
        assert len(child_lights) == int("light" in data)
        if child_lights:
            light, spec = child_lights[0], data["light"]
            assert light.get("class") == spec["kind"]
            for name, value in (("Brightness", spec["brightness"]), ("Range", spec["range"])):
                assert abs(float(light.findtext(f"./Properties/float[@name='{name}']"))-value) < 1e-5
            shadows = quality == "High" and spec["kind"] == "SurfaceLight"
            assert light.findtext("./Properties/bool[@name='Shadows']") == str(shadows).lower()
            if spec["kind"] == "SurfaceLight":
                assert int(light.findtext("./Properties/token[@name='Face']")) == FACES[spec["face"]]
    lights = [i for i in items if i.get("class") in ("PointLight", "SurfaceLight")]
    assert len(lights) == sum("light" in d for d in descriptors)
    embedded = Counter(i.findtext("./Properties/*[@name='Source']") for i in items if i.get("class") in ("Script", "LocalScript", "ModuleScript"))
    assert embedded == Counter(p.read_text() for p in (ROOT / "src").glob("*.luau")), "Embedded sources differ"
    workspace = next(i for i in items if i.get("class") == "Workspace")
    cam = next(i for i in items if i.findtext("./Properties/string[@name='Name']") == "TunnelPreviewCamera")
    assert workspace.findtext("./Properties/Ref[@name='CurrentCamera']") == cam.get("referent")
    baked_frame = cam.find("./Properties/CoordinateFrame[@name='CFrame']")
    assert all(abs(float(n.text)-v) < 1e-4 for n, v in zip(baked_frame, camera, strict=True))
    referents = {i.get("referent") for i in items}
    for ref in xml.iter("Ref"):
        assert ref.text in ("null", "nil", None) or ref.text in referents, f"Broken XML Ref: {ref.text}"
    print(f"PASS XML: {len(parts)} parts, {len(lights)} lights, {sum(embedded.values())} exact sources, camera and references")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", required=True)
    parser.add_argument("--compiler", required=True)
    parser.add_argument("--rojo", required=True)
    parser.add_argument("--quality", choices=("Low", "Medium", "High"), default="Medium")
    parser.add_argument("--api-dump", help="Optional locally supplied Roblox API-Dump.json")
    args = parser.parse_args()
    runtime, compiler, rojo = (Path(p).resolve() for p in (args.runtime, args.compiler, args.rojo))
    for source in sorted(ROOT.rglob("*.luau")):
        subprocess.run([str(compiler), "--null", str(source)], check=True, stdout=subprocess.DEVNULL)
    test_args = ["python3", ROOT / "tools/test.py", "--runtime", runtime]
    if args.api_dump:
        test_args += ["--api-dump", Path(args.api_dump).resolve()]
    run(*test_args)
    data = export(runtime)
    generated, dist = ROOT / ".generated", ROOT / "dist"
    generated.mkdir(exist_ok=True)
    dist.mkdir(exist_ok=True)
    parts = data["profiles"][args.quality]
    bake(parts, generated / "preview.rbxmx", args.quality)
    project = json.loads((ROOT / "default.project.json").read_text())
    project["tree"]["Workspace"]["CinematicTunnelPreview"]["$path"] = "preview.rbxmx"
    project["tree"]["ServerScriptService"]["TunnelNoCharacter"]["$path"] = "../src/NoCharacter.server.luau"
    modules = project["tree"]["StarterPlayer"]["StarterPlayerScripts"]["CinematicTunnel"]
    for node in modules.values():
        if isinstance(node, dict) and "$path" in node:
            node["$path"] = "../" + node["$path"]
    modules["Tunnel"]["$attributes"]["Quality"] = args.quality
    project["tree"]["Lighting"]["TunnelPreviewBloom"]["$properties"]["Enabled"] = args.quality != "Low"
    (generated / "build.project.json").write_text(json.dumps(project, ensure_ascii=False, indent=2)+"\n")
    place = dist / "cinematic-tunnel.rbxlx"
    run(rojo, "build", generated / "build.project.json", "--output", place)
    # Rojo emits Instances; set the serialized editor camera ref without Studio edits.
    xml = ET.parse(place)
    workspace = next(i for i in xml.iter("Item") if i.get("class") == "Workspace")
    cam = next(i for i in xml.iter("Item") if i.findtext("./Properties/string[@name='Name']") == "TunnelPreviewCamera")
    cp = cam.find("Properties")
    for node in list(cp):
        if node.get("name") in ("CFrame", "Focus"):
            cp.remove(node)
    prop(cp, "CoordinateFrame", "CFrame", data["camera"])
    prop(cp, "CoordinateFrame", "Focus", data["focus"])
    fov = cp.find("*[@name='FieldOfView']")
    fov.text = str(data["fov"])
    wp = workspace.find("Properties")
    for node in list(wp):
        if node.get("name") == "CurrentCamera":
            wp.remove(node)
    prop(wp, "Ref", "CurrentCamera", cam.get("referent"))
    xml.write(place, encoding="utf-8", xml_declaration=True)
    validate_place(place, parts, data["camera"], args.quality)
    counts = {q: {"parts": len(ds), "lights": sum("light" in d for d in ds),
                  "shadowLights": sum(d.get("light", {}).get("kind") == "SurfaceLight" for d in ds) if q == "High" else 0}
              for q, ds in data["profiles"].items()}
    (dist / "counts.json").write_text(json.dumps(counts, indent=2)+"\n")
    print(json.dumps(counts))
    print(f"Built {place}. Visual fidelity and FPS require real Roblox execution.")


if __name__ == "__main__":
    main()

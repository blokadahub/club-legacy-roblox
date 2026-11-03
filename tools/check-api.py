#!/usr/bin/env python3
"""Confere nomes estáticos de classes e enums contra um API-Dump.json Roblox.

Não certifica propriedades dinâmicas, permissões, segurança ou renderização.
O dump é fornecido pelo chamador; a ferramenta não acessa rede ou credenciais.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--dump", required=True, help="API-Dump.json do Roblox Client Tracker")
args = parser.parse_args()
dump_path = Path(args.dump)
api = json.loads(dump_path.read_text())
classes = {entry["Name"] for entry in api["Classes"]}
enums = {entry["Name"]: {item["Name"] for item in entry["Items"]} for entry in api["Enums"]}
root = Path(__file__).resolve().parent.parent
errors = []
references = 0
for source in sorted((root / "src").rglob("*.luau")):
    text = source.read_text()
    for group, item in re.findall(r"Enum\.(\w+)\.(\w+)", text):
        references += 1
        if group not in enums or item not in enums[group]:
            errors.append(f"{source.relative_to(root)}: Enum.{group}.{item} inexistente")
    for class_name in re.findall(r'(?:Instance|UI)\.new\("([^"]+)"', text):
        references += 1
        if class_name not in classes:
            errors.append(f"{source.relative_to(root)}: classe {class_name} inexistente")
digest = hashlib.sha256(dump_path.read_bytes()).hexdigest()
print(f"API Roblox: {references} referências estáticas; {len(errors)} erros; dump SHA256 {digest}")
for error in errors:
    print(error)
raise SystemExit(bool(errors))

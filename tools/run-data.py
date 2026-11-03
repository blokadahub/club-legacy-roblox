#!/usr/bin/env python3
"""Executa Data.luau e seus testes com o runtime oficial, sem carregar Roblox.

Somente Color3.fromRGB é substituído por uma representação numérica para os
dados; não há simulação de cenas, interface, câmera ou propriedades Roblox.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--runtime", required=True, help="Caminho para luau oficial")
args = parser.parse_args()

data = (root / "src/shared/Data.luau").read_text()
spec = (root / "tools/data.spec.luau").read_text()
source = """local Color3 = {fromRGB = function(r, g, b)
    return {R = r / 255, G = g / 255, B = b / 255}
end}
local data = (function()
""" + data + "\nend)()\nlocal test = (function()\n" + spec + "\nend)()\ntest(data)\n"
with tempfile.TemporaryDirectory(prefix="cl27-data-") as folder:
    generated = Path(folder) / "data-check.luau"
    generated.write_text(source)
    result = subprocess.run([str(Path(args.runtime).resolve()), str(generated)])
raise SystemExit(result.returncode)

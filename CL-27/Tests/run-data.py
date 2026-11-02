"""Executa os testes sem Studio usando a CLI oficial do Luau.
O único adaptador substitui o construtor Color3, ausente na CLI; dados e
asserções são os mesmos módulos utilizados no projeto.
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau", help="Caminho da CLI oficial do Luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
data = (root / "Data" / "Career.luau").read_text()
spec = (root / "Tests" / "Data.spec.luau").read_text()
harness = """local Color3 = {fromRGB = function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
local data = (function()
""" + data + "\nend)()\nlocal test = (function()\n" + spec + "\nend)()\ntest(data)\n"
with tempfile.NamedTemporaryFile(mode="w", suffix=".luau", encoding="utf-8") as file:
    file.write(harness)
    file.flush()
    result = subprocess.run([args.luau, file.name], check=False)
raise SystemExit(result.returncode)

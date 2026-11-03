#!/usr/bin/env python3
"""Verifica o projeto real; a opção --compiler usa o compilador oficial Luau.

Não simula renderização, propriedades Roblox ou desempenho. --place compara as
fontes incorporadas pelo Rojo e a árvore de serviços do arquivo final.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
ROUTES = (
    "HomeInterior", "Overview", "Squad", "Tactics",
    "Assignments", "Calendar", "Transfers", "Finance", "Development",
    "Competitions", "Customization", "Settings", "Clubs", "Kits",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def instance_name(path: Path) -> str:
    return path.name.removesuffix(".luau").removesuffix(".lua").removesuffix(".client").removesuffix(".server")


def validate_sources() -> list[Path]:
    project = json.loads((ROOT / "default.project.json").read_text())
    tree = project["tree"]
    require(tree.get("$className") == "DataModel", "A raiz Rojo precisa ser DataModel.")
    expected = (
        (tree["ReplicatedStorage"]["CL27"], "src/shared"),
        (tree["StarterPlayer"]["StarterPlayerScripts"]["CL27"], "src/client"),
        (tree["ServerScriptService"]["CL27"], "src/server"),
    )
    for node, location in expected:
        require(node.get("$path") == location, f"Mapeamento Rojo incorreto: {location}")
        require((ROOT / location).is_dir(), f"Diretório Rojo ausente: {location}")

    sources = sorted(ROOT.glob("src/**/*.luau")) + sorted(ROOT.glob("src/**/*.lua"))
    require(len(sources) >= 15, "Projeto incompleto: menos de 15 fontes Luau.")
    require(len(list(ROOT.glob("src/**/*.client.luau"))) == 1, "Deve existir exatamente um bootstrap LocalScript.")
    require(len(list(ROOT.glob("src/**/*.server.luau"))) == 1, "Deve existir exatamente um bootstrap servidor.")
    names = {(file.parent, instance_name(file)): file for file in sources}
    for file in sources:
        text = file.read_text(encoding="utf-8")
        require(bool(text.strip()), f"Fonte vazia: {file.relative_to(ROOT)}")
        require("CL_SCAFFOLD_PLACEHOLDER" not in text, f"Placeholder: {file.relative_to(ROOT)}")
        require("\x00" not in text, f"Byte nulo em {file.relative_to(ROOT)}")
        require(not re.search(r"\brequire\s*\(\s*\d", text), f"Dependência externa por asset ID em {file.relative_to(ROOT)}")
        for match in re.finditer(r"require\s*\(\s*(script(?:\.[A-Za-z_]\w*)+)\s*\)", text):
            current = file
            parts = match.group(1).split(".")[1:]
            for part in parts:
                if part == "Parent":
                    current = current.parent
                else:
                    candidate = current / part
                    if candidate.is_dir():
                        current = candidate
                    else:
                        current = names.get((current, part), candidate)
            require(current.is_file(), f"require não resolvido: {match.group(1)} em {file.relative_to(ROOT)}")

    app = ROOT / "src/client/App.luau"
    require(app.is_file(), "App.luau ausente.")
    app_text = app.read_text()
    # As rotas são entradas identificadas no App; cada destino aponta a módulo real.
    for route in ROUTES:
        require(re.search(rf"\b{re.escape(route)}\b", app_text) is not None, f"Rota ausente no App: {route}")
    require("HomeTraining" not in app_text, "HomeTraining nao pode permanecer no App.")
    require("function Scene:_training" not in (ROOT / "src/client/Scene.luau").read_text(), "Geometria 3D de treinamento deve permanecer removida.")
        if route != "HomeInterior":
            require((ROOT / f"src/client/Screens/{route}.luau").is_file(), f"Tela ausente: {route}")
    for doc in ("AGENTS.md", "CL27_PLAN.md", "CL27_PROGRESS.md"):
        require((ROOT / doc).is_file(), f"Documento obrigatório ausente: {doc}")
    print(f"Estrutura: {len(sources)} fontes, 14 rotas, mapeamento Rojo e require locais verificados.")
    return sources


def compile_syntax(compiler: str, sources: list[Path]) -> None:
    executable = Path(compiler).resolve()
    require(executable.is_file(), f"Compilador Luau ausente: {compiler}")
    failures = []
    for source in sources:
        result = subprocess.run([str(executable), str(source)], capture_output=True, text=True)
        if result.returncode:
            failures.append(f"{source.relative_to(ROOT)}\n{result.stderr or result.stdout}")
    require(not failures, "Falha de compilação sintática Luau:\n" + "\n".join(failures))
    print(f"Sintaxe: compilador oficial aprovou {len(sources)} fontes Luau.")


def validate_place(place: str, sources: list[Path]) -> None:
    xml = ET.parse(place).getroot()
    require(xml.tag == "roblox", "O artefato não é um XML Roblox.")
    classes = Counter(item.get("class") for item in xml.iter("Item"))
    for service in ("Workspace", "Lighting", "ReplicatedStorage", "StarterPlayer", "StarterPlayerScripts", "ServerScriptService"):
        require(classes[service] > 0, f"Serviço ausente no XML: {service}")
    require(classes["LocalScript"] == 1, "O XML precisa conter exatamente um LocalScript de bootstrap.")
    require(classes["Script"] == 1, "O XML precisa conter exatamente um Script de bootstrap.")
    embedded = []
    for item in xml.iter("Item"):
        if item.get("class") in ("LocalScript", "Script", "ModuleScript"):
            # Rojo 7.7.1 serializa Source como string; versões Studio também
            # podem emitir ProtectedString. A propriedade identifica a fonte.
            source = item.find("./Properties/*[@name='Source']")
            require(source is not None and bool(source.text), "Script sem Source no XML.")
            embedded.append(source.text.replace("\r\n", "\n"))
    original = [p.read_text().replace("\r\n", "\n") for p in sources]
    require(Counter(embedded) == Counter(original), "As fontes incorporadas diferem dos arquivos Luau versionados.")
    print(f"Artefato: XML válido; {len(embedded)} fontes incorporadas sem alteração; serviços conferidos.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", help="Caminho para luau-compile oficial")
    parser.add_argument("--place", help="Arquivo .rbxlx gerado pelo Rojo")
    args = parser.parse_args()
    try:
        sources = validate_sources()
        if args.compiler:
            compile_syntax(args.compiler, sources)
        if args.place:
            validate_place(args.place, sources)
        if not args.compiler and not args.place:
            print("Escopo: integridade estrutural. Sintaxe, runtime e visual não foram executados por esta chamada.")
    except (ValueError, OSError, KeyError, ET.ParseError) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

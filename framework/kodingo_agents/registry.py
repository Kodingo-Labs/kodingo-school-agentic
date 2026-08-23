"""Carga del registro YAML de agentes y pipelines."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

REGISTRY_REL = Path("agents") / "registry.yaml"


@dataclass(frozen=True)
class OutputSpec:
    dir: str
    filename: str  # puede incluir {date}


@dataclass(frozen=True)
class ContextSpec:
    collect_diff: bool = True
    diff_max_lines: int = 400
    base_branch: str = "main"


@dataclass(frozen=True)
class AgentDef:
    id: str
    name: str
    description: str = ""
    stack: str = "kodingo"
    prompt_files: tuple[str, ...] = ()
    template: str | None = None
    output: OutputSpec = field(default_factory=lambda: OutputSpec("docs/quality-gate", "reporte-{date}.md"))
    context: ContextSpec = field(default_factory=ContextSpec)


@dataclass(frozen=True)
class PipelineDef:
    id: str
    description: str
    agents: tuple[str, ...]


@dataclass(frozen=True)
class Registry:
    version: int
    agents: dict[str, AgentDef]
    pipelines: dict[str, PipelineDef]
    root: Path


def find_agentic_root(start: Path | None = None) -> Path:
    start = (start or Path.cwd()).resolve()
    for candidate in [start, *start.parents]:
        if (candidate / REGISTRY_REL).is_file():
            return candidate
    raise FileNotFoundError(
        f"No se encontró {REGISTRY_REL}. Ejecuta desde kodingo-school-agentic o pasa --agentic-root.",
    )


def _parse_output(raw: dict[str, Any] | None) -> OutputSpec:
    raw = raw or {}
    return OutputSpec(
        dir=raw.get("dir", "docs/quality-gate"),
        filename=raw.get("filename", "reporte-{date}.md"),
    )


def _parse_context(raw: dict[str, Any] | None) -> ContextSpec:
    raw = raw or {}
    return ContextSpec(
        collect_diff=bool(raw.get("collect_diff", True)),
        diff_max_lines=int(raw.get("diff_max_lines", 400)),
        base_branch=str(raw.get("base_branch", "main")),
    )


def load_registry(root: Path | None = None) -> Registry:
    agentic_root = root or find_agentic_root()
    path = agentic_root / REGISTRY_REL
    data = yaml.safe_load(path.read_text(encoding="utf-8"))

    agents: dict[str, AgentDef] = {}
    for agent_id, raw in (data.get("agents") or {}).items():
        agents[agent_id] = AgentDef(
            id=agent_id,
            name=raw.get("name", agent_id),
            description=raw.get("description", ""),
            stack=raw.get("stack", "kodingo"),
            prompt_files=tuple(raw.get("prompt_files") or []),
            template=raw.get("template"),
            output=_parse_output(raw.get("output")),
            context=_parse_context(raw.get("context")),
        )

    pipelines: dict[str, PipelineDef] = {}
    for pipe_id, raw in (data.get("pipelines") or {}).items():
        pipelines[pipe_id] = PipelineDef(
            id=pipe_id,
            description=raw.get("description", ""),
            agents=tuple(raw.get("agents") or []),
        )

    return Registry(
        version=int(data.get("version", 1)),
        agents=agents,
        pipelines=pipelines,
        root=agentic_root,
    )

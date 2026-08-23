"""Ensambla el prompt final desde archivos MD del registro."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from .context import RunContext, format_context_block
from .registry import AgentDef, Registry


def _read_relative(registry: Registry, rel_path: str) -> str:
    path = registry.root / rel_path
    if not path.is_file():
        raise FileNotFoundError(f"Prompt no encontrado: {path}")
    return path.read_text(encoding="utf-8").strip()


def build_prompt(
    registry: Registry,
    agent: AgentDef,
    *,
    target_repo: Path,
    git_context: RunContext | None,
    extra_instructions: str = "",
) -> str:
    sections: list[str] = [
        f"# Ejecución agente: {agent.name} (`{agent.id}`)",
        "",
        f"**Repo objetivo:** `{target_repo.resolve()}`",
        f"**Fecha:** {date.today().isoformat()}",
        f"**Stack:** {agent.stack}",
        "",
    ]

    if extra_instructions.strip():
        sections.extend(["## Instrucciones adicionales", "", extra_instructions.strip(), ""])

    if git_context and agent.context.collect_diff:
        sections.append(format_context_block(git_context))

    for i, rel in enumerate(agent.prompt_files, start=1):
        body = _read_relative(registry, rel)
        sections.extend([f"## Prompt {i} — `{rel}`", "", body, ""])

    if agent.template:
        template_body = _read_relative(registry, agent.template)
        sections.extend(
            [
                "## Plantilla de salida",
                "",
                "Genera el reporte siguiendo esta estructura:",
                "",
                template_body,
                "",
            ]
        )

    out_path = resolve_output_path(agent, target_repo)
    sections.extend(
        [
            "## Destino del reporte",
            "",
            f"Guarda la salida del agente en: `{out_path}`",
            "",
            "---",
            "",
            "Responde en **español**. No modifiques código del repo salvo que el usuario lo pida después del reporte.",
        ]
    )

    return "\n".join(sections)


def resolve_output_path(agent: AgentDef, target_repo: Path) -> Path:
    today = date.today().isoformat()
    filename = agent.output.filename.replace("{date}", today)
    return target_repo / agent.output.dir / filename

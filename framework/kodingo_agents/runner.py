"""Ejecutores: ensamblar prompt (local) o invocar Cursor SDK."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from .prompt_builder import build_prompt, resolve_output_path
from .registry import AgentDef, Registry
from .context import RunContext


@dataclass(frozen=True)
class AssembleResult:
    prompt_path: Path
    output_path: Path
    prompt_text: str


def assemble_prompt(
    registry: Registry,
    agent: AgentDef,
    *,
    target_repo: Path,
    git_context: RunContext | None,
    extra_instructions: str = "",
    out_dir: Path | None = None,
) -> AssembleResult:
    prompt_text = build_prompt(
        registry,
        agent,
        target_repo=target_repo,
        git_context=git_context,
        extra_instructions=extra_instructions,
    )
    output_path = resolve_output_path(agent, target_repo)

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    runtime_dir = out_dir or (target_repo / ".runtime" / "kodingo-agent")
    runtime_dir.mkdir(parents=True, exist_ok=True)
    prompt_path = runtime_dir / f"prompt-{agent.id}-{stamp}.md"
    prompt_path.write_text(prompt_text, encoding="utf-8")

    return AssembleResult(
        prompt_path=prompt_path,
        output_path=output_path,
        prompt_text=prompt_text,
    )


def execute_with_cursor(
    prompt_text: str,
    *,
    target_repo: Path,
    model: str = "composer-2.5",
) -> str:
    import os

    try:
        from cursor_sdk import Agent, AgentOptions, LocalAgentOptions
    except ImportError as exc:
        raise SystemExit(
            "Cursor SDK no instalado. Ejecuta: pip install 'kodingo-agents[cursor]' "
            "y define CURSOR_API_KEY.",
        ) from exc

    api_key = os.environ.get("CURSOR_API_KEY")
    if not api_key:
        raise SystemExit("Falta CURSOR_API_KEY en el entorno.")

    result = Agent.prompt(
        prompt_text,
        AgentOptions(
            api_key=api_key,
            model=model,
            local=LocalAgentOptions(cwd=str(target_repo.resolve())),
        ),
    )

    if result.status == "error":
        raise RuntimeError(f"Agente Cursor falló: {getattr(result, 'result', result)}")

    return str(getattr(result, "result", result))

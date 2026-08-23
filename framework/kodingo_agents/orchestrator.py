"""Orquestación de pipelines (varios agentes en secuencia)."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .context import collect_git_context
from .registry import PipelineDef, Registry
from .runner import AssembleResult, assemble_prompt, execute_with_cursor


@dataclass(frozen=True)
class StepResult:
    agent_id: str
    assemble: AssembleResult
    executed: bool
    report_text: str | None = None


@dataclass(frozen=True)
class PipelineResult:
    pipeline_id: str
    steps: tuple[StepResult, ...]


def run_pipeline(
    registry: Registry,
    pipeline: PipelineDef,
    *,
    target_repo: Path,
    execute: bool = False,
    model: str = "composer-2.5",
    extra_instructions: str = "",
) -> PipelineResult:
    steps: list[StepResult] = []

    for agent_id in pipeline.agents:
        agent = registry.agents.get(agent_id)
        if agent is None:
            raise KeyError(f"Agente desconocido en pipeline: {agent_id}")

        git_ctx = None
        if agent.context.collect_diff:
            git_ctx = collect_git_context(target_repo, agent.context)

        assembled = assemble_prompt(
            registry,
            agent,
            target_repo=target_repo,
            git_context=git_ctx,
            extra_instructions=extra_instructions,
        )

        report_text = None
        if execute:
            report_text = execute_with_cursor(
                assembled.prompt_text,
                target_repo=target_repo,
                model=model,
            )
            assembled.output_path.parent.mkdir(parents=True, exist_ok=True)
            assembled.output_path.write_text(report_text, encoding="utf-8")

        steps.append(
            StepResult(
                agent_id=agent_id,
                assemble=assembled,
                executed=execute,
                report_text=report_text,
            )
        )

    return PipelineResult(pipeline_id=pipeline.id, steps=tuple(steps))

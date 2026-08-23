"""CLI: kodingo-agent list | run | pipeline"""

from __future__ import annotations

import argparse
import sys
from dataclasses import replace
from pathlib import Path

from .context import collect_git_context
from .orchestrator import run_pipeline
from .registry import find_agentic_root, load_registry
from .runner import assemble_prompt, execute_with_cursor


def _cmd_list(registry) -> int:
    print(f"Registro v{registry.version} — {registry.root}\n")
    print("Agentes:")
    for aid, agent in registry.agents.items():
        desc = f" — {agent.description}" if agent.description else ""
        print(f"  {aid:<30} [{agent.stack}]{desc}")
    print("\nPipelines:")
    for pid, pipe in registry.pipelines.items():
        chain = " → ".join(pipe.agents)
        print(f"  {pid:<30} {chain}")
    return 0


def _cmd_run(args) -> int:
    registry = load_registry(Path(args.agentic_root) if args.agentic_root else None)
    agent = registry.agents.get(args.agent_id)
    if agent is None:
        print(f"Agente desconocido: {args.agent_id}", file=sys.stderr)
        return 1

    target = Path(args.repo).resolve()
    if not target.is_dir():
        print(f"Repo no existe: {target}", file=sys.stderr)
        return 1

    agent = replace(agent, context=replace(agent.context, base_branch=args.base))

    git_ctx = collect_git_context(target, agent.context) if agent.context.collect_diff else None
    assembled = assemble_prompt(
        registry,
        agent,
        target_repo=target,
        git_context=git_ctx,
        extra_instructions=args.instructions or "",
    )

    print(f"Prompt ensamblado: {assembled.prompt_path}")
    print(f"Reporte esperado: {assembled.output_path}")

    if args.print_prompt:
        print("\n--- PROMPT ---\n")
        print(assembled.prompt_text)

    if args.execute:
        report = execute_with_cursor(
            assembled.prompt_text,
            target_repo=target,
            model=args.model,
        )
        assembled.output_path.parent.mkdir(parents=True, exist_ok=True)
        assembled.output_path.write_text(report, encoding="utf-8")
        print(f"Reporte escrito: {assembled.output_path}")
    else:
        print("\nModo ensamblar (sin LLM). Usa --execute y CURSOR_API_KEY para ejecutar con Cursor SDK.")
        print("O pega el prompt en Cursor Chat manualmente.")

    return 0


def _cmd_pipeline(args) -> int:
    registry = load_agentic_registry(args)
    pipe = registry.pipelines.get(args.pipeline_id)
    if pipe is None:
        print(f"Pipeline desconocido: {args.pipeline_id}", file=sys.stderr)
        return 1

    target = Path(args.repo).resolve()
    result = run_pipeline(
        registry,
        pipe,
        target_repo=target,
        execute=args.execute,
        model=args.model,
        extra_instructions=args.instructions or "",
    )

    for step in result.steps:
        status = "ejecutado" if step.executed else "ensamblado"
        print(f"[{status}] {step.agent_id} → prompt: {step.assemble.prompt_path}")
        if step.report_text:
            print(f"         reporte: {step.assemble.output_path}")

    return 0


def load_agentic_registry(args):
    return load_registry(Path(args.agentic_root) if args.agentic_root else None)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="kodingo-agent",
        description="Framework de agentes Kodingo School — carga MD, contexto git, ejecución opcional.",
    )
    parser.add_argument(
        "--agentic-root",
        help="Raíz de kodingo-school-agentic (auto-detecta si no se indica)",
    )

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="Listar agentes y pipelines")

    run_p = sub.add_parser("run", help="Ejecutar un agente")
    run_p.add_argument("agent_id", help="ID del agente (ej. kodingo-code-review)")
    run_p.add_argument("--repo", required=True, help="Ruta al repo objetivo")
    run_p.add_argument("--base", default="main", help="Rama base para git diff")
    run_p.add_argument("--execute", action="store_true", help="Invocar Cursor SDK (requiere CURSOR_API_KEY)")
    run_p.add_argument("--print-prompt", action="store_true", help="Imprimir prompt ensamblado en stdout")
    run_p.add_argument("--model", default="composer-2.5", help="Modelo Cursor SDK")
    run_p.add_argument("--instructions", help="Instrucciones extra para el agente")

    pipe_p = sub.add_parser("pipeline", help="Ejecutar un pipeline de agentes")
    pipe_p.add_argument("pipeline_id", help="ID del pipeline (ej. kodingo-code-review)")
    pipe_p.add_argument("--repo", required=True, help="Ruta al repo objetivo")
    pipe_p.add_argument("--execute", action="store_true", help="Invocar Cursor SDK por cada paso")
    pipe_p.add_argument("--model", default="composer-2.5")
    pipe_p.add_argument("--instructions", help="Instrucciones extra")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.command == "list":
        registry = load_registry(Path(args.agentic_root) if args.agentic_root else None)
        return _cmd_list(registry)
    if args.command == "run":
        return _cmd_run(args)
    if args.command == "pipeline":
        return _cmd_pipeline(args)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

"""Contexto de ejecución: git diff, metadatos del repo objetivo."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

from .registry import ContextSpec


@dataclass(frozen=True)
class RunContext:
    target_repo: Path
    base_branch: str
    head_ref: str
    branch: str
    diff_stat: str
    diff_text: str


def _run_git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return ""
    return result.stdout


def collect_git_context(repo: Path, spec: ContextSpec) -> RunContext | None:
    if not (repo / ".git").exists() and _run_git(repo, "rev-parse", "--git-dir") == "":
        return None

    base = spec.base_branch
    branch = _run_git(repo, "branch", "--show-current").strip() or "HEAD"
    head = _run_git(repo, "rev-parse", "--short", "HEAD").strip() or "?"

    diff_stat = _run_git(repo, "diff", "--stat", f"{base}...HEAD")
    if not diff_stat.strip():
        diff_stat = _run_git(repo, "diff", "--stat", base, "HEAD")

    diff_text = _run_git(repo, "diff", f"{base}...HEAD")
    if not diff_text.strip():
        diff_text = _run_git(repo, "diff", base, "HEAD")

    lines = diff_text.splitlines()
    if len(lines) > spec.diff_max_lines:
        truncated = "\n".join(lines[: spec.diff_max_lines])
        diff_text = truncated + f"\n\n... [diff truncado a {spec.diff_max_lines} líneas]"

    return RunContext(
        target_repo=repo.resolve(),
        base_branch=base,
        head_ref=head,
        branch=branch,
        diff_stat=diff_stat.strip(),
        diff_text=diff_text.strip(),
    )


def format_context_block(ctx: RunContext | None) -> str:
    if ctx is None:
        return "## Contexto git\n\n_(No es un repositorio git o no hay diff disponible.)_\n"

    return "\n".join(
        [
            "## Contexto git (generado por kodingo-agent)",
            "",
            f"- **Repo:** `{ctx.target_repo}`",
            f"- **Rama:** `{ctx.branch}`",
            f"- **HEAD:** `{ctx.head_ref}`",
            f"- **Base:** `{ctx.base_branch}`",
            "",
            "### Archivos cambiados",
            "",
            "```",
            ctx.diff_stat or "(sin cambios respecto a la base)",
            "```",
            "",
            "### Diff",
            "",
            "```diff",
            ctx.diff_text or "(vacío)",
            "```",
            "",
        ]
    )

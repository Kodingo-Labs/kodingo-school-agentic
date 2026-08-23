from pathlib import Path

from kodingo_agents.context import RunContext
from kodingo_agents.prompt_builder import build_prompt
from kodingo_agents.registry import load_registry


def test_build_prompt_includes_sections():
    root = Path(__file__).resolve().parents[2]
    reg = load_registry(root)
    agent = reg.agents["kodingo-code-review"]
    target = root

    text = build_prompt(
        reg,
        agent,
        target_repo=target,
        git_context=RunContext(
            target_repo=target,
            base_branch="main",
            head_ref="abc1234",
            branch="feature",
            diff_stat="1 file changed",
            diff_text="+ line",
        ),
    )

    assert "kodingo-code-review" in text
    assert "Contexto git" in text
    assert "SKILL.md" in text
    assert "docs/quality-gate" in text

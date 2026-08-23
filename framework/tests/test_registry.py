from pathlib import Path

import pytest

from kodingo_agents.registry import find_agentic_root, load_registry


def test_load_registry():
    root = find_agentic_root(Path(__file__).resolve().parents[2])
    reg = load_registry(root)
    assert reg.version == 1
    assert "kodingo-code-review" in reg.agents
    assert "kodingo-code-review" in reg.pipelines


def test_agent_has_prompt_files():
    root = find_agentic_root(Path(__file__).resolve().parents[2])
    reg = load_registry(root)
    agent = reg.agents["kodingo-code-review"]
    assert len(agent.prompt_files) >= 2
    for rel in agent.prompt_files:
        assert (root / rel).is_file()

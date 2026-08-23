#__init__.py Defin el paquete que podra ser importado desde otros modulos
# __all__ Defi

"""Framework de agentes Kodingo School."""

from .registry import AgentDef, PipelineDef, load_registry
from .prompt_builder import build_prompt

__all__ = ["AgentDef", "PipelineDef", "load_registry", "build_prompt"]
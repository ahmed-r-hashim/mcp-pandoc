"""Configuration for the mcp-pandoc server.

Mirrors the settings pattern used by sitemap-mcp-server: a small ``Settings``
object populated from environment variables, with sensible defaults.
"""

import logging
import os

from pydantic import BaseModel


class Settings(BaseModel):
    """Runtime settings for the mcp-pandoc server."""

    APP_NAME: str = "mcp-pandoc"

    # Transport used to serve the MCP server:
    #   "sse"   - HTTP + Server-Sent Events (default). Suitable for clients
    #             that connect over the network and for running the server
    #             as a long-lived container/service.
    #   "stdio" - reads/writes JSON-RPC over stdin/stdout. Used when an MCP
    #             client spawns this process directly (e.g. Claude Desktop,
    #             Codex).
    TRANSPORT: str = os.getenv("PANDOC_MCP_TRANSPORT", "sse")

    # Only used when TRANSPORT="sse".
    HOST: str = os.getenv("PANDOC_MCP_HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PANDOC_MCP_PORT", "8055"))

    LOG_LEVEL: str = os.getenv("PANDOC_MCP_LOG_LEVEL", "INFO").upper()


settings = Settings()


def configure_logger() -> logging.Logger:
    """Configure and return the application logger."""
    logging.basicConfig(
        level=settings.LOG_LEVEL,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    logger = logging.getLogger(settings.APP_NAME)
    logger.setLevel(getattr(logging, settings.LOG_LEVEL, logging.INFO))
    return logger


logger = configure_logger()

# Changelog

## 0.1.1

- Fix ha-mcp timing out on first start: the uv cache is now filled before
  Claude starts, not in the background, and Claude waits up to 60 seconds
  for MCP servers (`MCP_TIMEOUT`).

## 0.1.0

- First release: Herdr 0.9.5 server with Claude Code, key-only SSH for remote
  Herdr clients, an ingress panel attached to the same session, and ha-mcp.

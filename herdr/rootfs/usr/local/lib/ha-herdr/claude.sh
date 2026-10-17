# shellcheck shell=bash
# Claude Code setup helpers, sourced by herdr-bootstrap.

# Claude's native install lives in ~/.local (inside /data), updates itself,
# and wins on PATH. The bundled /usr/local/bin/claude is only the fallback
# and the installer. A native copy that exists but cannot run is removed,
# so the fallback takes over instead of a broken binary.
ensure_native_claude() {
    local native="${HOME}/.local/bin/claude"
    if [ -x "${native}" ] && ! timeout 10 "${native}" --version >/dev/null 2>&1; then
        bashio::log.warning "Native Claude install does not run; removing it"
        rm -f "${native}"
    fi
    if [ ! -x "${native}" ]; then
        bashio::log.info "Installing self-updating native Claude Code into /data"
        timeout 300 /usr/local/bin/claude install >/dev/null 2>&1 \
            || bashio::log.warning "Native Claude install failed; using the bundled copy"
    fi
}

# The native updater keeps old versions (about 250 MB each) and never deletes
# them, which bloats /data and HA backups. Keep only the active one.
prune_claude_versions() {
    local versions="${HOME}/.local/share/claude/versions" active
    [ -d "${versions}" ] || return 0
    active="$(readlink -f "${HOME}/.local/bin/claude" 2>/dev/null || true)"
    [ -n "${active}" ] || return 0
    find "${versions}" -mindepth 1 -maxdepth 1 ! -path "${active}" -exec rm -rf {} +
}

# ha-mcp gives Claude Home Assistant tools through the Supervisor API proxy.
# Re-registered on every start so the configured version always applies.
configure_ha_mcp() {
    local version="$1"
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "SUPERVISOR_TOKEN missing; skipping ha-mcp"
        return 0
    fi
    timeout 30 claude mcp remove --scope user home-assistant >/dev/null 2>&1 || true
    # Single quotes are deliberate: Claude expands the token when it starts
    # the MCP server, so the token itself is never written to disk.
    # shellcheck disable=SC2016
    if timeout 30 claude mcp add --scope user home-assistant \
        --env "HOMEASSISTANT_URL=http://supervisor/core" \
        --env 'HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}' \
        -- uvx --python 3.13 --index-strategy unsafe-best-match "ha-mcp@${version}" >/dev/null 2>&1; then
        bashio::log.info "ha-mcp ${version} registered for Claude Code"
        # Fill the uv cache before Claude starts. On a cold cache (first start,
        # or a new ha_mcp_version) uv downloads Python and ha-mcp, which takes
        # longer than Claude waits for an MCP server. Warming in the background
        # raced Claude and lost.
        if timeout 600 uvx --python 3.13 --index-strategy unsafe-best-match \
            --from "ha-mcp@${version}" python -c "" >/dev/null 2>&1; then
            bashio::log.info "ha-mcp ${version} is ready"
        else
            bashio::log.warning "Could not prepare ha-mcp ${version}; Claude may time out connecting to it"
        fi
    else
        bashio::log.warning "Could not register ha-mcp with Claude Code"
    fi
}

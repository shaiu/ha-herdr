# Herdr

This add-on runs a [Herdr](https://herdr.dev) server on your Home Assistant
box, with Claude Code inside it. Herdr recognizes the agent, so any Herdr
client can see whether Claude is working, idle, or waiting for an answer, and
can switch to it like a local pane.

You can reach the same session in two ways:

- **The Herdr panel in the HA sidebar.** It is a Herdr client in your browser.
- **Herdr on another computer, over SSH.** Your box shows up as a machine in
  the Herdr sidebar, next to your local workspaces.

## How it works

```
Herdr on your computer ──ssh──▶ Herdr add-on
                                 ├─ sshd          key-only, from the options below
                                 ├─ herdr server  state in /data, survives restarts
                                 │    └─ pane: claude (cwd /homeassistant)
                                 └─ HA panel → herdr client (same session)
```

Claude Code gets Home Assistant tools through
[ha-mcp](https://github.com/homeassistant-ai/ha-mcp), which talks to Home
Assistant through the Supervisor API.

## First start

1. Add your SSH public key to **authorized_keys** in the add-on
   configuration. One key per entry, for example
   `ssh-ed25519 AAAA... you@laptop`.
2. Start the add-on and open the **Herdr** panel.
3. In the Claude pane, finish Claude's first-run steps and log in.

## Connect from Herdr on another computer

The add-on opens no port on your network by default. Reach it through the
[Advanced SSH & Web Terminal](https://github.com/hassio-addons/addon-ssh)
add-on, which pipes the connection over the internal hassio network.

1. Find the add-on hostname: the **Hostname** on this add-on's info page (for
   example `a1b2c3d4-herdr`, or `local-herdr` for a local install).
2. Add this to `~/.ssh/config` on your computer. Replace the SSH add-on login
   and the hostname with yours:

   ```
   Host ha-herdr
     HostName a1b2c3d4-herdr
     User root
     ProxyCommand ssh hassio@homeassistant.local nc %h %p
   ```

3. Check it: `ssh ha-herdr herdr --version`.
4. Add the machine to Herdr:

   ```
   herdr machine add ha-herdr --label "Home Assistant"
   ```

   Herdr finds the server that is already running. It installs nothing.

If you do not use the SSH add-on, map port 22 in the add-on's network
settings to a host port instead, and connect to that port directly. Login is
by key only, but the port is then open to your whole network.

## Options

| Option | Default | What it does |
|---|---|---|
| `authorized_keys` | empty | SSH public keys that may log in. Rewritten on every start, so removing a key revokes it. With no keys, SSH stays off. |
| `auto_start_claude` | `true` | On start, run Claude Code in Herdr if no Claude is already running. |
| `working_directory` | `/homeassistant` | Where Claude starts. `/homeassistant` is your HA configuration. |
| `enable_ha_mcp` | `true` | Register ha-mcp with Claude Code. |
| `ha_mcp_version` | `7.11.0` | The ha-mcp version to run. |

## Persistence

Everything in `/data` survives restarts and updates: Claude's login, settings
and history, Herdr's workspaces, and the SSH host key. Claude Code updates
itself inside `/data`. Herdr is pinned in the image and updates with the
add-on.

## Security

- The panel is a root terminal. nginx only accepts the HA ingress proxy, so
  other add-ons on the hassio network cannot reach it.
- SSH accepts public keys only. Password login is off and SSH tunnels are
  disabled.
- Claude Code here can read and change your Home Assistant configuration, and
  ha-mcp can control your devices. Review what you approve.

## Moving from the Claude Terminal add-on

Copy Claude's state over, from the SSH add-on (it needs Docker access, so turn
off its protection mode for this). Use your own container names from
`docker ps` (they look like `app_<id>_claude_terminal`):

```
docker exec app_xxxxxxxx_claude_terminal tar -C /data/home -cf - .claude .claude.json CLAUDE.md \
  | docker exec -i app_yyyyyyyy_herdr tar -C /data/home -xf -
docker exec app_yyyyyyyy_herdr cp -a /data/home/.claude/projects/-config /data/home/.claude/projects/-homeassistant
```

Then restart this add-on. Claude Terminal ran Claude in `/config`; this
add-on uses `/homeassistant`, so the second command makes `claude --resume`
find your earlier conversations.

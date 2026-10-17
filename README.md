# Herdr add-on for Home Assistant

Run coding agents on your Home Assistant box inside
[Herdr](https://herdr.dev), and reach them from any Herdr client.

The add-on runs a Herdr server with Claude Code in a pane. Herdr recognizes
the agent, so from your laptop you see whether Claude on the HA box is
working, idle, or waiting for you, and you switch to it like any other pane.
The HA sidebar panel shows the same session in your browser.

## Install

1. In Home Assistant, open **Settings → Add-ons → Add-on Store**.
2. Open the menu (⋮) → **Repositories**, and add
   `https://github.com/shaiu/ha-herdr`.
3. Install **Herdr**, add your SSH public key in its configuration, and start
   it.

[![Add repository to Home Assistant][repo-badge]][repo-link]

See [herdr/DOCS.md](herdr/DOCS.md) for connecting from Herdr on another
computer, the options, and moving from the Claude Terminal add-on.

Questions and feedback: the
[community forum thread](https://community.home-assistant.io/t/herdr-add-on-run-claude-code-on-your-ha-box-and-reach-it-from-herdr-on-your-laptop/1029307).
Bugs: [GitHub issues](https://github.com/shaiu/ha-herdr/issues).

## Status

Early. Tested on a Raspberry Pi (aarch64) running Home Assistant OS. amd64
images are built but less tested.

Herdr is a separate project by its authors, licensed under Apache-2.0. This
repository only packages it as an add-on. The add-on icon is Herdr's own
logo, from its repository.

[repo-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[repo-link]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fshaiu%2Fha-herdr

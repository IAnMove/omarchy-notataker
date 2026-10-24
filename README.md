# Notataker

An [Omarchy](https://omarchy.org) plugin for talking to your agent about whatever
is on your screen. Capture a region (just like Print Screen), type what you want,
and your **default Omarchy agent** gets the image and your request: *transcribe
this into my notes*, *translate it*, *build this*…

▶ [Demo video (38 s)](https://github.com/IAnMove/omarchy-notataker/releases/download/v1.0.1/notataker-demo.mp4): capture → request → grok saves the note.

## Install

```bash
omarchy plugin add https://github.com/IAnMove/omarchy-notataker.git --enable
~/.config/omarchy/plugins/io.github.ianmove.notataker/setup.sh
```

The first line adds the bar icon and the panel. The second creates the
`notataker` command and the **`Shift + Print`** hotkey in
`~/.config/hypr/bindings.lua` (with a backup). You need a default agent:
`omarchy default agent <claude|codex|grok|…>`.

Update: `omarchy plugin update io.github.ianmove.notataker`.
Remove: `~/.config/omarchy/plugins/io.github.ianmove.notataker/setup.sh --uninstall`,
then `omarchy plugin remove io.github.ianmove.notataker`.

> Omarchy plugins run unsandboxed inside the shell. This one is short
> (`bin/notataker`, `Overlay.qml`, `BarWidget.qml`): read it before you enable it.

## How to use it

1. `Shift + Print`, or click the bar icon, or run `notataker`.
2. Drag a region or click a window. From the keyboard: `Tab` cycles windows and
   `Enter` captures the highlighted one (it is Omarchy's own picker).
3. A panel shows a thumbnail, a text box and one-click shortcuts
   (*Transcribe to my notes*, *Translate*, *Explain*, *Summarize*, *Build this*).
   `Enter` sends, `Shift + Enter` adds a line, `Esc` cancels.
4. Your agent opens with the capture and your request already in place.

Agents read images from a file path, so the prompt includes the path of the
capture: your agent doesn't need any special image option (tested with grok).

## Settings

`~/.config/notataker/config` (created by `setup.sh`, everything commented out):

| Variable | Default | What it does |
|---|---|---|
| `NOTATAKER_NOTES_DIR` | `~/Documents/Obsidian Vault` | Your notes folder. The agent is told about it for when you ask it to "save it to my notes". |
| `NOTATAKER_CAPTURE_DIR` | `~/Pictures/Notataker` | Where captures are saved. |

If you cancel the panel, the capture is deleted. If you send it, it stays in that folder.
Different hotkey: `NOTATAKER_KEY="SUPER + SHIFT + S" ./setup.sh`.

If you remove the bar icon, Omarchy considers the plugin disabled and the panel
stops opening: the hotkey still works but asks with the plain text box of
Omarchy's menu (no thumbnail or shortcuts). To get the panel back:
`omarchy plugin enable io.github.ianmove.notataker --section right`.

## Security

Omarchy launches the default agent **without permission prompts** (that is how
`omarchy agent` configures it). Everything in the screenshot reaches the agent,
and a malicious web page or document can carry text meant to manipulate it. The
prompt tells the agent that text inside the image is data, not instructions, but
that is not a guarantee: with content you don't trust, ask for harmless things
(*transcribe*, *translate*) rather than for it to create or run something.

## How it works

- `bin/notataker`: captures with `omarchy-capture-screenshot`, opens the panel,
  builds the prompt and launches `omarchy-agent-prompt`.
- `Overlay.qml` / `BarWidget.qml`: the panel and the icon (`overlay` + `bar-widget`).
- `setup.sh`: command, settings and hotkey.

MIT, [IAnMove](https://github.com/IAnMove).

# NiimPrintX — Claude Project Instructions

## Project Overview

Fork of [labbots/NiimPrintX](https://github.com/labbots/NiimPrintX).
Python library + CLI/GUI for Niimbot label printers via Bluetooth.

- **origin**: `https://github.com/atobaum/NiimPrintX` (this fork)
- **upstream**: `https://github.com/labbots/NiimPrintX` (original)

## Environment

- Python 3.12, managed with **uv** (`.venv/`)
- direnv: `.envrc` activates `.venv` automatically
- Dependencies: `uv pip install -r requirements.txt`

## Printer Hardware

- Model: **Niimbot D110** only (`-m d110`)
- DPI: 203
- Max print head width: 240px (~30mm)

### Available Labels

| Label | Physical | Pixels (203 DPI) |
|-------|----------|-----------------|
| 14×22mm | short=14mm, long=22mm (feed) | 111×175px |
| 15×30mm | short=15mm, long=22mm (feed) | 119×239px |
| 15×50mm | short=15mm, long=50mm (feed) | 119×399px |

**Currently in use: 14×22mm**

### Axis Convention

- **Short side** (14mm = 111px): across print head = `--ho` direction
- **Long side** (22mm = 175px): feed direction = `--vo` direction

### ⚠️ Offset Bug in printer.py

`--ho` and `--vo` fill offset pixels with **black** (not white) due to `fill=1` in
the 1-bit inverted image. Do NOT use `--ho`/`--vo` for margins.
Instead, add white padding (`255`) directly to the image in Python before printing.
White (255) → printer inverts to 0 → not printed = white on paper.

## Calibrated Print Settings (14×22 label)

Empirically tuned — do not change without re-calibrating:

| Parameter | Value | Notes |
|-----------|------:|-------|
| QR max width | **93px** | 95px clips right edge |
| Top margin | **10px** | prevents leading-edge cut |
| Left margin | **0px** | left edge prints cleanly |
| Right margin | **2px** | 1px was still clipped |

Calibration history: width 111→100→90→93, top 0→5→10, side 0→1→2→split 0/2.

## QR Print Skill

Use `/print-qr <url>` to generate and print a QR code.
Skill lives at `.claude/skills/print-qr/`.

### QR Capacity (14×22 label, 93px effective)

| box_size | ec | max chars | quality |
|----------|----|----------:|---------|
| 3 | L | 78 | excellent |
| **2** | **L/M** | **122–154** | **good** |
| 1 | L | 321 | poor (tiny, hard to scan) |

**Rule**: warn the user if content exceeds 154 chars before printing.

## Key Files

| Path | Purpose |
|------|---------|
| `NiimPrintX/cli/command.py` | CLI entry point (`print`, `info` commands) |
| `NiimPrintX/nimmy/printer.py` | Bluetooth printer client, `_encode_image()` |
| `.claude/skills/print-qr/scripts/print_qr.sh` | QR generation + print script |
| `tmp/qr_print.png` | Temporary QR image (gitignored) |
| `requirements.txt` | Python dependencies |

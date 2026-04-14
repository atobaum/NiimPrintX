---
name: print-qr
description: This skill should be used when the user asks to "print a QR code", "QR 출력", "QR 뽑아줘", "QR 찍어줘", "print QR", or provides a URL/text to encode as a QR code and print on the Niimbot d110 label printer.
---

# NiimPrintX QR Print Skill

Generate a QR code image and print it on a **Niimbot d110** label printer using the NiimPrintX CLI.

## Prerequisites

- Working directory must be the NiimPrintX project root (contains `.venv/` and `NiimPrintX/` package)
- Niimbot d110 must be powered on and discoverable via Bluetooth

## Available Labels

| Label | Pixel size (203 DPI) | Status |
|-------|----------------------|--------|
| 14x22mm | 111×175px | **default (currently in use)** |
| 15x30mm | 119×239px | available |
| 15x50mm | 119×399px | available |

## Workflow

1. Identify the QR content from the user's message (URL, text, etc.)
2. Identify the label size — default is `14x22` unless the user specifies otherwise
3. Run the print script via Bash:

```bash
bash .claude/skills/print-qr/scripts/print_qr.sh "<QR_CONTENT>" [label-size] [./qr_print.png]
```

- Argument 1: string to encode (URL or plain text)
- Argument 2 (optional): label size — `14x22` | `15x30` | `15x50` (default: `14x22`)
- Argument 3 (optional): output image path (default: `./tmp/qr_print.png`)

The script auto-selects the largest `box_size` that fits within the label's pixel dimensions at 203 DPI.

## QR Capacity on 14x22 Label (effective 106×170px)

| box_size | ec | max chars | quality |
|----------|----|----------:|---------|
| 3 | L | 78 | excellent |
| **2** | **L** | **154** | **good (recommended max)** |
| 1 | L | 321 | poor (tiny modules, hard to scan) |

**Rule of thumb**: keep content under 154 chars for a readable QR. Over 154 chars forces box_size=1 which is very small.
The script auto-selects the best box_size (tries M error correction first, falls back to L), then upscales to fill the available area.

**Important**: If the content exceeds 154 characters, warn the user before printing:
> "입력하신 URL이 154자를 초과합니다 ({n}자). QR 모듈이 매우 작아져 스캔이 어려울 수 있습니다. 그래도 출력할까요?"
Only proceed if the user confirms.

## Fixed Print Parameters

| Option | Value | Reason |
|--------|-------|--------|
| model  | d110  | Only printer available |
| density | 3   | Balanced print quality |
| quantity | 1  | One label per call |
| vertical offset | 5px | Leading edge margin (긴 쪽, feed direction) |
| horizontal offset | 5px | Left margin (짧은 쪽, print head direction) |

## Examples

```bash
# 14x22 label (default)
bash .claude/skills/print-qr/scripts/print_qr.sh "https://example.com"

# 15x50 label
bash .claude/skills/print-qr/scripts/print_qr.sh "https://example.com" 15x50
```

## Notes

- `qrcode[pil]` is auto-installed into `.venv` if missing
- The output PNG is saved to `tmp/qr_print.png` (gitignored)
- If the QR content is too long to fit on the label, the script exits with an error

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
- Argument 3 (optional): output image path (default: `./qr_print.png`)

The script auto-selects the largest `box_size` that fits within the label's pixel dimensions at 203 DPI.

## Fixed Print Parameters

| Option | Value | Reason |
|--------|-------|--------|
| model  | d110  | Only printer available |
| density | 3   | Balanced print quality |
| quantity | 1  | One label per call |
| horizontal offset | 5px | Slight margin correction |

## Examples

```bash
# 14x22 label (default)
bash .claude/skills/print-qr/scripts/print_qr.sh "https://example.com"

# 15x50 label
bash .claude/skills/print-qr/scripts/print_qr.sh "https://example.com" 15x50
```

## Notes

- `qrcode[pil]` is auto-installed into `.venv` if missing
- The output PNG (`qr_print.png`) is left in the project directory after printing
- If the QR content is too long to fit on the label, the script exits with an error

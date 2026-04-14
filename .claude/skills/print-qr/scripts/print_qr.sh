#!/usr/bin/env bash
# Usage: print_qr.sh <qr-content> [label-size] [output-image-path]
#   label-size: 14x22 (default) | 15x30 | 15x50
#   output-image-path: defaults to ./qr_print.png

set -euo pipefail

QR_CONTENT="${1:?QR content is required}"
LABEL="${2:-14x22}"
OUTPUT_IMAGE="${3:-./qr_print.png}"

PROJECT_DIR="$(pwd)"
VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"

if [[ ! -x "$VENV_PYTHON" ]]; then
  echo "ERROR: .venv not found at $PROJECT_DIR/.venv" >&2
  echo "Run: uv venv && uv pip install -r requirements.txt" >&2
  exit 1
fi

# Install qrcode if missing
"$VENV_PYTHON" -c "import qrcode" 2>/dev/null || \
  "$PROJECT_DIR/.venv/bin/pip" install "qrcode[pil]" -q

# Generate QR — auto box_size to fit within label width
"$VENV_PYTHON" - <<PYEOF
import qrcode, sys

DPI = 203
label_dims = {
    "14x22": (14, 22),
    "15x30": (15, 30),
    "15x50": (15, 50),
}

label = "$LABEL"
if label not in label_dims:
    print(f"Unknown label: {label}. Use one of {list(label_dims)}", file=sys.stderr)
    sys.exit(1)

HORIZONTAL_OFFSET = 5  # pixels added to left by --ho 5; subtract so right side isn't clipped

w_mm, h_mm = label_dims[label]
max_w_px = int(w_mm / 25.4 * DPI) - HORIZONTAL_OFFSET
max_h_px = int(h_mm / 25.4 * DPI)

# Find largest box_size that fits within label width (accounting for left margin)
for box_size in range(5, 0, -1):
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=box_size,
        border=1,
    )
    qr.add_data("$QR_CONTENT")
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert("L")
    if img.size[0] <= max_w_px and img.size[1] <= max_h_px:
        break
else:
    print(f"ERROR: QR too large to fit on {label} label ({max_w_px}x{max_h_px}px)", file=sys.stderr)
    sys.exit(1)

img.save("$OUTPUT_IMAGE")
print(f"QR saved: $OUTPUT_IMAGE ({img.size[0]}x{img.size[1]}px, label={label} max={max_w_px}x{max_h_px}px, box_size={box_size})")
PYEOF

# Print via NiimPrintX CLI
"$VENV_PYTHON" -m NiimPrintX.cli print \
  -m d110 \
  -d 3 \
  -n 1 \
  --ho 5 \
  -i "$OUTPUT_IMAGE"

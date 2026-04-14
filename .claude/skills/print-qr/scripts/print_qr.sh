#!/usr/bin/env bash
# Usage: print_qr.sh <qr-content> [label-size] [output-image-path]
#   label-size: 14x22 (default) | 15x30 | 15x50
#   output-image-path: defaults to ./tmp/qr_print.png

set -euo pipefail

QR_CONTENT="${1:?QR content is required}"
LABEL="${2:-14x22}"
PROJECT_DIR="$(pwd)"
OUTPUT_IMAGE="${3:-$PROJECT_DIR/tmp/qr_print.png}"

mkdir -p "$PROJECT_DIR/tmp"
VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"

if [[ ! -x "$VENV_PYTHON" ]]; then
  echo "ERROR: .venv not found at $PROJECT_DIR/.venv" >&2
  echo "Run: uv venv && uv pip install -r requirements.txt" >&2
  exit 1
fi

# Install qrcode if missing
"$VENV_PYTHON" -c "import qrcode" 2>/dev/null || \
  "$PROJECT_DIR/.venv/bin/pip" install "qrcode[pil]" -q

"$VENV_PYTHON" - <<PYEOF
import qrcode, sys
from PIL import Image as PILImage

# Calibrated values for 14x22mm label on D110 (empirically tuned)
# Note: --ho/--vo are NOT used because the printer fills offset pixels with black
# (fill=1 in 1-bit inverted image). White padding is embedded directly in the image.
# White (255) in L-mode → printer inverts to 0 → not printed = white on paper.
LABEL_CONFIGS = {
    # label: (max_qr_px, top_margin, left_margin, right_margin)
    #
    # 14x22 calibration (D110, 203 DPI):
    #   Physical label width = 14mm = 111px, but effective print width ~95px.
    #   max_qr_px=93: 95px fitted, 93px avoids right-edge clipping (empirical).
    #   top_margin=10: leading-edge gap to prevent QR being cut at label start.
    #   left_margin=0: left edge prints cleanly with no offset needed.
    #   right_margin=2: 1px was cut, 2px gives safe clearance on right edge.
    #   Calibration sequence: 111→100→90→93 (width), 0→5→10 (top margin),
    #     0→1→2 (side), then split left=0 / right=2 based on observed output.
    "14x22": (93, 10, 0, 2),
    # 15x30, 15x50: not yet calibrated — using conservative defaults
    "15x30": (119, 10, 0, 2),
    "15x50": (119, 10, 0, 2),
}

label = "$LABEL"
if label not in LABEL_CONFIGS:
    print(f"Unknown label: {label}. Use one of {list(LABEL_CONFIGS)}", file=sys.stderr)
    sys.exit(1)

max_qr_px, top_margin, left_margin, right_margin = LABEL_CONFIGS[label]

# Find largest box_size + error correction that fits.
# Try M first (better error recovery), fall back to L (smaller matrix).
best = None
for box_size in range(5, 0, -1):
    for ec in (qrcode.constants.ERROR_CORRECT_M, qrcode.constants.ERROR_CORRECT_L):
        qr = qrcode.QRCode(version=None, error_correction=ec, box_size=box_size, border=1)
        qr.add_data("$QR_CONTENT")
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white").convert("L")
        if img.size[0] <= max_qr_px and img.size[1] <= max_qr_px:
            best = (img, box_size, "M" if ec == qrcode.constants.ERROR_CORRECT_M else "L")
            break
    if best:
        break

if not best:
    print(f"ERROR: QR too large to fit ({max_qr_px}x{max_qr_px}px available)", file=sys.stderr)
    sys.exit(1)

img, box_size, ec_name = best

# Scale up to fill available QR area (NEAREST = sharp pixel edges)
if img.size[0] < max_qr_px:
    img = img.resize((max_qr_px, max_qr_px), PILImage.NEAREST)

# Embed in canvas with calibrated white margins
canvas_w = img.width + left_margin + right_margin
canvas_h = img.height + top_margin
canvas = PILImage.new("L", (canvas_w, canvas_h), 255)
canvas.paste(img, (left_margin, top_margin))
canvas.save("$OUTPUT_IMAGE")
print(f"QR saved: $OUTPUT_IMAGE  qr={img.size[0]}x{img.size[1]}px  canvas={canvas_w}x{canvas_h}px  box_size={box_size}  ec={ec_name}")
PYEOF

# --ho/--vo intentionally omitted: margins are baked into the image as white pixels
"$VENV_PYTHON" -m NiimPrintX.cli print \
  -m d110 \
  -d 3 \
  -n 1 \
  -i "$OUTPUT_IMAGE"

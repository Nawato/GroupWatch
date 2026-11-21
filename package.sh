#!/usr/bin/env bash
# Build a CurseForge-ready zip: dist/GroupWatch-<version>.zip
# The archive root contains the GroupWatch/ addon folder.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON="$(basename "$ROOT")"
TOC="$ROOT/$ADDON.toc"

if [[ ! -f "$TOC" ]]; then
	echo "error: $TOC not found" >&2
	exit 1
fi

VERSION="$(sed -n 's/^## Version:[[:space:]]*//p' "$TOC" | head -n 1 | tr -d '\r')"
if [[ -z "$VERSION" ]]; then
	echo "error: no ## Version directive in $TOC" >&2
	exit 1
fi

OUT_DIR="$ROOT/dist"
ZIP="$OUT_DIR/$ADDON-$VERSION.zip"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/$ADDON" "$OUT_DIR"

rsync -a \
	--exclude '.git/' \
	--exclude '.github/' \
	--exclude '.vscode/' \
	--exclude 'tests/' \
	--exclude 'dist/' \
	--exclude 'CODE_REVIEW.md' \
	--exclude 'CHANGELOG.md' \
	--exclude 'README.md' \
	--exclude '.gitignore' \
	--exclude '.pkgmeta' \
	--exclude 'package.sh' \
	--exclude '*.zip' \
	"$ROOT/" "$STAGE/$ADDON/"

rm -f "$ZIP"
python3 - "$STAGE" "$ZIP" <<'PY'
import os
import sys
import zipfile

stage, out = sys.argv[1], sys.argv[2]

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
    for base, dirs, files in os.walk(stage):
        dirs.sort()
        for name in sorted(files):
            full = os.path.join(base, name)
            rel = os.path.relpath(full, stage).replace(os.sep, "/")
            archive.write(full, rel)
PY

python3 - "$ZIP" <<'PY'
import sys
import zipfile

names = zipfile.ZipFile(sys.argv[1]).namelist()
banned = ("tests/", ".git/", ".github/", "dist/", "CODE_REVIEW.md")
leaked = [n for n in names if any(n.startswith(b) or n == b for b in banned)]
if leaked:
    raise SystemExit("error: unwanted files in archive: " + ", ".join(leaked))
print(f"{len(names)} files")
PY

echo "packaged: $ZIP"

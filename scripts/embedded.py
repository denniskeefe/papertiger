#!/usr/bin/env python3
"""Keep the shell scripts embedded in index.html in sync with their sources.

index.html carries deploy.sh verbatim inside <script type="text/plain" id="deploy-sh">
so the browser can bundle it into downloads. deploy.sh is the source of truth.

Usage:
  scripts/embedded.py check        exit 1 if the embedded copy differs from deploy.sh
  scripts/embedded.py sync         rewrite the embedded copy from deploy.sh
  scripts/embedded.py extract ID   print an embedded script (e.g. wizard-sh) to stdout
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
INDEX = ROOT / "index.html"
SYNCED = {"deploy-sh": ROOT / "deploy.sh"}


def block_re(block_id):
    return re.compile(
        r'(<script type="text/plain" id="%s">)(.*?)(</script>)' % re.escape(block_id),
        re.S,
    )


def embedded(html, block_id):
    matches = block_re(block_id).findall(html)
    if len(matches) != 1:
        sys.exit(f"index.html: expected exactly one #{block_id} block, found {len(matches)}")
    return matches[0][1]


def expected(source):
    text = source.read_text()
    if "</script" in text.lower():
        sys.exit(f"{source.name} contains '</script', which would break the embed in index.html")
    return "\n" + text


def main(argv):
    if not argv or argv[0] not in {"check", "sync", "extract"}:
        sys.exit(__doc__)
    html = INDEX.read_text()

    if argv[0] == "extract":
        if len(argv) != 2:
            sys.exit(__doc__)
        sys.stdout.write(embedded(html, argv[1]).lstrip("\n"))
        return 0

    stale = [bid for bid, src in SYNCED.items() if embedded(html, bid) != expected(src)]

    if argv[0] == "check":
        for bid in stale:
            print(f"index.html #{bid} is out of date with {SYNCED[bid].name}. "
                  f"Run: python3 scripts/embedded.py sync", file=sys.stderr)
        return 1 if stale else 0

    for bid in stale:
        body = expected(SYNCED[bid])
        html = block_re(bid).sub(lambda m: m.group(1) + body + m.group(3), html, count=1)
        print(f"synced #{bid} from {SYNCED[bid].name}")
    INDEX.write_text(html)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

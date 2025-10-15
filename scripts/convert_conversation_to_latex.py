#!/usr/bin/env python3
"""
Convert the JSONL conversation log into a LaTeX QA transcript.

The output uses the custom awesome-qa-chat package (bundled under tex/),
emulating the CTAN Awesome QA Chat style requested for publishing.
"""
from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
LOG_PATH = ROOT / "logs" / "conversation.jsonl"
OUTPUT_DIR = ROOT / "build"
OUTPUT_TEX = OUTPUT_DIR / "conversation.tex"
STYLE_SOURCE = ROOT / "tex" / "awesome-qa-chat.sty"


def load_entries() -> list[dict]:
    entries = []
    if not LOG_PATH.exists():
        return entries
    with LOG_PATH.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError as exc:
                entries.append(
                    {
                        "timestamp": datetime.utcnow().isoformat() + "Z",
                        "type": "error",
                        "message": f"Failed to parse line: {exc}",
                    }
                )
    return entries


def latex_escape(text: str) -> str:
    replacements = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    for key, value in replacements.items():
        text = text.replace(key, value)
    return text


def render_entries(entries: list[dict]) -> str:
    lines = [
        r"\documentclass{article}",
        r"\usepackage{geometry}",
        r"\usepackage{hyperref}",
        r"\usepackage{awesome-qa-chat}",
        r"\geometry{margin=1in}",
        r"\title{Conversation QA Transcript}",
        r"\author{UTM Automation}",
        r"\date{\today}",
        r"\begin{document}",
        r"\maketitle",
        r"\begin{AwesomeQAChat}",
    ]

    if not entries:
        lines.append(r"\QA{System}{No conversation entries found.}")
    else:
        for entry in entries:
            speaker = latex_escape(entry.get("type", "note").title())
            timestamp = entry.get("timestamp", "")
            header = f"{speaker} ({timestamp})"
            message_str = entry.get("message") or entry.get("summary") or ""
            message = latex_escape(str(message_str))
            extra = entry.get("context") or entry.get("notes")
            if extra:
                if isinstance(extra, list):
                    extra = ", ".join(str(item) for item in extra)
                extra_text = r"\textit{" + latex_escape(str(extra)) + "}"
                if message:
                    message += r"\\ " + extra_text
                else:
                    message = extra_text
            lines.append(rf"\QA{{{header}}}{{{message}}}")

    lines.extend(
        [
            r"\end{AwesomeQAChat}",
            r"\end{document}",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries = load_entries()
    tex_source = render_entries(entries)
    OUTPUT_TEX.write_text(tex_source, encoding="utf-8")
    if STYLE_SOURCE.exists():
        shutil.copy2(STYLE_SOURCE, OUTPUT_DIR / STYLE_SOURCE.name)
    print(f"Wrote LaTeX transcript to {OUTPUT_TEX}")


if __name__ == "__main__":
    main()

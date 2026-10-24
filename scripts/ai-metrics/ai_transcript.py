#!/usr/bin/env python3
"""Rút gọn transcript Claude Code để AI chấm điểm mà không phải đọc cả file JSONL.
Dùng: python3 ai_transcript.py <transcript.jsonl> [...] [--max-chars 600]"""
import argparse, json

SKIPPED_PROMPT_PREFIXES = ("<local-command", "<command-", "<system-reminder")

def shorten(text, max_chars):
    text = " ".join(text.split())
    return text if len(text) <= max_chars else text[:max_chars] + " …"

def tool_summary(block):
    tool_input = block.get("input") or {}
    target = tool_input.get("file_path") or tool_input.get("path") or tool_input.get("command") or tool_input.get("skill") or tool_input.get("pattern") or ""
    return f"{block.get('name')} {target}".strip()

def condense(path, max_chars):
    lines = []
    with open(path, encoding="utf-8") as f:
        for raw in f:
            try:
                entry = json.loads(raw)
            except Exception:
                continue
            message = entry.get("message") or {}
            content = message.get("content")
            timestamp = (entry.get("timestamp") or "")[:16].replace("T", " ")
            if entry.get("type") == "user" and isinstance(content, str) and not content.lstrip().startswith(SKIPPED_PROMPT_PREFIXES):
                lines.append(f"[{timestamp}] USER: {shorten(content, max_chars)}")
            elif entry.get("type") == "assistant" and isinstance(content, list):
                for block in content:
                    if block.get("type") == "text" and block.get("text", "").strip():
                        lines.append(f"[{timestamp}] CLAUDE: {shorten(block['text'], max_chars)}")
                    elif block.get("type") == "tool_use":
                        lines.append(f"[{timestamp}]   tool: {shorten(tool_summary(block), 160)}")
    return lines

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("transcripts", nargs="+")
    ap.add_argument("--max-chars", type=int, default=600)
    a = ap.parse_args()
    for path in a.transcripts:
        print(f"=== {path}")
        try:
            print("\n".join(condense(path, a.max_chars)))
        except OSError as e:
            print(f"(không đọc được: {e})")

if __name__ == "__main__":
    main()

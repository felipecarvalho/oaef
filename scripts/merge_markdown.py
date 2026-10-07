#!/usr/bin/env python3
"""
OAEF section-aware markdown merge.

Framework-owned content lives inside `<!-- oaef:section:<id> -->` markers. Everything outside a
marker pair is user-owned and is never rewritten or deleted. When a destination file has no
markers at all (a hand-written contract, or an OAEF v1.0.0 installation), the merge degrades to
heading-level merging: the canonical block is inserted right after the matching `## N.` heading and
the user content below it is left untouched.

Usage:
    merge_markdown.py --template <path> --destination <path> [--apply] [--plan-only]

Output (stdout):
    CLASS <install|merge-additive|merge-conflict|propose-oaef-new|unchanged>
    CONFLICT <section-id>          (one line per diverging canonical section)
    EDIT <section-id>             (one line per canonical block replaced in place)
    APPEND <section-id>           (one line per canonical block appended)

Exit codes: 0 = handled, 20 = merge not deterministic (caller proposes <file>.oaef-new).
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

SENTINEL_OPEN = re.compile(r"^<!-- oaef:section:([A-Za-z0-9_.:\-]+) -->$")
SENTINEL_CLOSE = re.compile(r"^<!-- /oaef:section:([A-Za-z0-9_.:\-]+) -->$")
CONFLICT_OPEN = re.compile(r"^<!-- oaef:conflict:([A-Za-z0-9_.:\-]+) -->$")
HEADING = re.compile(r"^## (\d+)\.\s*(.*)$")
ANY_HEADING = re.compile(r"^##\s+(.*)$")


@dataclass
class Block:
    section_id: str
    text: str
    number: int | None
    title: str


def split_blocks(text: str) -> tuple[str, list[Block]]:
    """Split a markdown document into a preamble and ordered sentinel blocks."""
    lines = text.splitlines()
    preamble: list[str] = []
    blocks: list[Block] = []
    index = 0
    while index < len(lines):
        opening = SENTINEL_OPEN.match(lines[index])
        if not opening:
            preamble.append(lines[index])
            index += 1
            continue
        section_id = opening.group(1)
        collected = [lines[index]]
        index += 1
        while index < len(lines):
            collected.append(lines[index])
            closing = SENTINEL_CLOSE.match(lines[index])
            if closing and closing.group(1) == section_id:
                index += 1
                break
            index += 1
        body = "\n".join(collected)
        number, title = None, ""
        for candidate in collected:
            match = HEADING.match(candidate)
            if match:
                number = int(match.group(1))
                title = match.group(2).strip()
                break
        blocks.append(Block(section_id, body, number, title))
    return "\n".join(preamble), blocks


def synthesize_blocks(text: str) -> list[Block]:
    """Templates without sentinels still merge: their `##` regions become the canonical blocks."""
    lines = text.splitlines()
    regions = destination_regions(lines)
    blocks: list[Block] = []
    for start, end, number, title in regions:
        section_id = f"region-{number}" if number is not None else f"region-{normalize_title(title)[:40]}"
        blocks.append(Block(section_id, "\n".join(lines[start:end]), number, title))
    return blocks


def canonical_regions(blocks: list[Block]) -> list[tuple[Block, str]]:
    """Group blocks into top-level regions, keyed by the block that opens the region."""
    regions: list[tuple[Block, str]] = []
    current: Block | None = None
    parts: list[str] = []
    for block in blocks:
        if block.number is not None and block.section_id != (current.section_id if current else None):
            if current is not None:
                regions.append((current, "\n".join(parts)))
            current = block
            parts = [block.text]
            continue
        if current is None:
            if block.number is None:
                current = block
                parts = [block.text]
                continue
            current = block
            parts = [block.text]
            continue
        parts.append(block.text)
    if current is not None:
        regions.append((current, "\n".join(parts)))
    return regions


def normalize_title(title: str) -> str:
    return re.sub(r"[^a-z0-9]", "", title.lower())


def destination_regions(lines: list[str]) -> list[tuple[int, int, int | None, str]]:
    """Return (start, end, number, normalized-title) for every top-level section of a document."""
    starts: list[int] = []
    for index, line in enumerate(lines):
        if line.startswith("## "):
            starts.append(index)
    regions = []
    for position, start in enumerate(starts):
        end = starts[position + 1] if position + 1 < len(starts) else len(lines)
        match = HEADING.match(lines[start])
        if match:
            regions.append((start, end, int(match.group(1)), normalize_title(match.group(2))))
        else:
            heading = ANY_HEADING.match(lines[start])
            regions.append((start, end, None, normalize_title(heading.group(1) if heading else "")))
    return regions


def merge_with_markers(template_blocks: list[Block], destination: str) -> tuple[str, list[str], list[str]]:
    lines = destination.splitlines()
    spans: dict[str, tuple[int, int]] = {}
    index = 0
    while index < len(lines):
        opening = SENTINEL_OPEN.match(lines[index])
        if not opening:
            index += 1
            continue
        section_id = opening.group(1)
        start = index
        index += 1
        while index < len(lines) and not (
            SENTINEL_CLOSE.match(lines[index]) and SENTINEL_CLOSE.match(lines[index]).group(1) == section_id
        ):
            index += 1
        spans[section_id] = (start, index + 1 if index < len(lines) else len(lines))
        index += 1

    edits: list[str] = []
    conflicts: list[str] = []
    for block in template_blocks:
        span = spans.get(block.section_id)
        if span is None:
            continue
        start, end = span
        current = "\n".join(lines[start:end])
        if current.strip() == block.text.strip():
            continue
        edits.append(block.section_id)
        if block.section_id in ("invariants-stack-rules",):
            continue
        lines[start:end] = block.text.splitlines()
        spans = {}
        rebuilt = "\n".join(lines)
        return merge_with_markers_second_pass(template_blocks, rebuilt, edits, conflicts)
    result = "\n".join(lines)
    return result, edits, conflicts


def merge_with_markers_second_pass(
    template_blocks: list[Block], destination: str, edits: list[str], conflicts: list[str]
) -> tuple[str, list[str], list[str]]:
    """Replace every present canonical block in place, then append the missing ones."""
    lines = destination.splitlines()
    changed = True
    while changed:
        changed = False
        spans: dict[str, tuple[int, int]] = {}
        index = 0
        while index < len(lines):
            opening = SENTINEL_OPEN.match(lines[index])
            if not opening:
                index += 1
                continue
            section_id = opening.group(1)
            start = index
            index += 1
            while index < len(lines) and not (
                SENTINEL_CLOSE.match(lines[index]) and SENTINEL_CLOSE.match(lines[index]).group(1) == section_id
            ):
                index += 1
            spans[section_id] = (start, min(index + 1, len(lines)))
            index += 1
        for block in template_blocks:
            span = spans.get(block.section_id)
            if span is None:
                continue
            start, end = span
            if "\n".join(lines[start:end]).strip() == block.text.strip():
                continue
            lines[start:end] = block.text.splitlines()
            if block.section_id not in edits:
                edits.append(block.section_id)
            changed = True
            break
    appended: list[str] = []
    present = set()
    index = 0
    while index < len(lines):
        opening = SENTINEL_OPEN.match(lines[index])
        if opening:
            present.add(opening.group(1))
        index += 1
    missing = [block for block in template_blocks if block.section_id not in present]
    for block in missing:
        lines.append("")
        lines.extend(block.text.splitlines())
        appended.append(block.section_id)
    result = "\n".join(lines)
    if result and not result.endswith("\n"):
        result += "\n"
    return result, edits, appended


def merge_with_headings(
    template_blocks: list[Block], destination: str
) -> tuple[str, list[str], list[str]] | None:
    lines = destination.splitlines()
    regions = destination_regions(lines)
    canonical = canonical_regions(template_blocks)
    inserted: list[str] = []
    conflicts: list[str] = []
    duplicated = False

    unmatched: list[str] = []
    for block, region_text in canonical:
        if block.number is None and not block.title:
            continue
        matches = []
        for start, end, number, title in regions:
            same_number = block.number is not None and number == block.number
            same_title = bool(block.title) and title == normalize_title(block.title)
            if same_number or same_title:
                matches.append((start, end, number, title))
        if len(matches) > 1:
            duplicated = True
            continue
        if not matches:
            unmatched.append(region_text)
            continue
        start, _end, _number, _title = matches[0]
        if CONFLICT_OPEN.match(lines[start + 1] if start + 1 < len(lines) else ""):
            already = None
            for offset in range(start + 1, min(start + 4, len(lines))):
                marker = CONFLICT_OPEN.match(lines[offset])
                if marker:
                    already = marker.group(1)
                    break
            if already == block.section_id:
                continue
        canonical_body = "\n".join(line for line in region_text.splitlines() if line.strip())
        destination_body = "\n".join(
            line for line in lines[start + 1 : (matches[0][1])] if line.strip()
        )
        if canonical_body == destination_body:
            continue
        insertion = [
            f"<!-- oaef:conflict:{block.section_id} -->",
            *region_text.splitlines(),
            f"<!-- /oaef:conflict:{block.section_id} -->",
        ]
        lines[start + 1 : start + 1] = insertion
        conflicts.append(block.section_id)
        inserted.append(block.section_id)
        regions = destination_regions(lines)

    if duplicated:
        return None

    for region_text in unmatched:
        lines.append("")
        lines.extend(region_text.splitlines())
        for block, candidate_region in canonical:
            if candidate_region == region_text:
                inserted.append(block.section_id)
                break

    if not canonical:
        present = "\n".join(lines).strip()
        canonical_body = "\n".join(block.text for block in template_blocks).strip()
        if canonical_body and present != canonical_body:
            for block in template_blocks:
                lines.append("")
                lines.extend(block.text.splitlines())
                inserted.append(block.section_id)

    result = "\n".join(lines)
    if result and not result.endswith("\n"):
        result += "\n"
    return result, inserted, conflicts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True)
    parser.add_argument("--destination", required=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--plan-only", action="store_true")
    arguments = parser.parse_args()

    template_path = Path(arguments.template)
    destination_path = Path(arguments.destination)

    try:
        template_text = template_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        print(f"CLASS propose-oaef-new")
        print(f"REASON template unreadable: {error}", file=sys.stderr)
        return 20

    if not destination_path.exists():
        print("CLASS install")
        if arguments.apply and not arguments.plan_only:
            destination_path.parent.mkdir(parents=True, exist_ok=True)
            destination_path.write_text(template_text, encoding="utf-8")
        return 0

    try:
        destination_text = destination_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        print("CLASS propose-oaef-new")
        print(f"REASON destination unreadable: {error}", file=sys.stderr)
        return 20

    if destination_text == template_text or destination_text.strip() == template_text.strip():
        print("CLASS unchanged")
        return 0

    _preamble, blocks = split_blocks(template_text)
    if not blocks:
        blocks = synthesize_blocks(template_text)
    if not blocks:
        print("CLASS propose-oaef-new")
        print("REASON template carries neither oaef:section markers nor top-level sections", file=sys.stderr)
        return 20

    has_markers = any(SENTINEL_OPEN.match(line) for line in destination_text.splitlines())
    if has_markers:
        merged, edited, appended = merge_with_markers_second_pass(blocks, destination_text, [], [])
        classification = "merge-conflict" if edited else "merge-additive"
        for section in edited:
            print(f"EDIT {section}")
        for section in appended:
            print(f"APPEND {section}")
        if edited or appended:
            if arguments.apply and not arguments.plan_only:
                destination_path.write_text(merged, encoding="utf-8")
            print(f"CLASS {classification}")
            return 0
        print("CLASS unchanged")
        return 0

    outcome = merge_with_headings(blocks, destination_text)
    if outcome is None:
        print("CLASS propose-oaef-new")
        print("REASON ambiguous heading multiplicity in destination", file=sys.stderr)
        return 20
    merged, inserted, conflicts = outcome
    for section in conflicts:
        print(f"CONFLICT {section}")
    for section in inserted:
        if section not in conflicts:
            print(f"APPEND {section}")
    if not inserted and merged.strip() == destination_text.strip():
        print("CLASS unchanged")
        return 0
    if arguments.apply and not arguments.plan_only:
        destination_path.write_text(merged, encoding="utf-8")
    print("CLASS merge-conflict" if conflicts else "merge-additive")
    return 0


if __name__ == "__main__":
    sys.exit(main())

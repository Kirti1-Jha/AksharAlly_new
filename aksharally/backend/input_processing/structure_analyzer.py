"""Layout analysis for OCR results.

The analyzer deliberately works from OCR boxes rather than guessed punctuation.
That lets the API preserve empty table cells, column order, and menu
relationships even when OCR gets a symbol or a word slightly wrong.
"""

import re


_PRICE_TOKEN = re.compile(
    r"^(?:₹|Rs\.?|INR|%|X|x|¥|Y)?\s*[0-9][0-9,]*(?:\.[0-9]+)?$",
    re.IGNORECASE,
)
_PRICE_PARTS = re.compile(
    r"^(₹|Rs\.?|INR|%|X|x|¥|Y)?\s*([0-9][0-9,]*(?:\.[0-9]+)?)$",
    re.IGNORECASE,
)


def _text(words):
    return " ".join(word["text"] for word in sorted(words, key=lambda item: item["left"])).strip()


def _normalise_price(value, price_context=False):
    """Repair common currency glyph OCR errors only in a price context."""
    value = re.sub(r"\s+", " ", value.strip())
    match = _PRICE_PARTS.match(value)
    if not match:
        return value
    symbol, number = match.groups()
    if symbol and symbol.lower() in {"rs", "inr"}:
        return f"{symbol} {number}".replace("Rs ", "Rs. ")
    if price_context:
        # Tesseract often reads the Devanagari rupee glyph as %, X, or ¥.
        # A price column/menu price is enough context to repair that one token;
        # ordinary percentages elsewhere are intentionally left unchanged.
        return f"₹{number}"
    return value


def _line_groups(detections):
    if not detections:
        return []
    heights = sorted(max(1, item["height"]) for item in detections)
    tolerance = max(10, heights[len(heights) // 2] * 0.85)
    lines = []
    for word in sorted(detections, key=lambda item: (item["top"], item["left"])):
        center_y = word["top"] + word["height"] / 2
        line = next(
            (candidate for candidate in lines
             if abs(center_y - candidate["centerY"]) <= tolerance),
            None,
        )
        if line is None:
            line = {"centerY": center_y, "words": []}
            lines.append(line)
        line["words"].append(word)
        line["centerY"] = sum(
            item["top"] + item["height"] / 2 for item in line["words"]
        ) / len(line["words"])
    for line in lines:
        line["words"].sort(key=lambda item: item["left"])
        line["text"] = _text(line["words"])
        line["left"] = min(item["left"] for item in line["words"])
        line["right"] = max(item["left"] + item["width"] for item in line["words"])
    return sorted(lines, key=lambda item: item["centerY"])


def _is_heading(value):
    letters = [character for character in value if character.isalpha()]
    return len(letters) >= 3 and sum(character.isupper() for character in letters) / len(letters) >= 0.72


def _price_words(words):
    return [word for word in words if _PRICE_TOKEN.match(word["text"].replace(" ", ""))]


def _table_block(detections, grid):
    x_lines = grid["xLines"]
    y_lines = grid["yLines"]
    rows = []
    for row_index in range(len(y_lines) - 1):
        row = []
        for column_index in range(len(x_lines) - 1):
            words = []
            for word in detections:
                center_x = word["left"] + word["width"] / 2
                center_y = word["top"] + word["height"] / 2
                if (
                    x_lines[column_index] < center_x < x_lines[column_index + 1]
                    and y_lines[row_index] < center_y < y_lines[row_index + 1]
                ):
                    words.append(word)
            row.append(_text(words))
        rows.append(row)

    if not rows:
        return None
    header_text = " ".join(rows[0]).lower()
    price_columns = {
        index for index, value in enumerate(rows[0])
        if any(keyword in value.lower() for keyword in ("price", "amount", "cost", "rate", "मूल्य", "किंमत"))
    }
    for row in rows[1:]:
        for index in price_columns:
            if index < len(row) and row[index]:
                row[index] = _normalise_price(row[index], price_context=True)

    return {
        "type": "table",
        "headers": rows[0],
        "rows": rows[1:],
        "columnCount": len(x_lines) - 1,
        "hasEmptyCells": any(not cell for row in rows for cell in row),
        "headerText": header_text,
    }


def _aligned_table_block(detections):
    """Recover borderless tables from repeated header x positions."""
    lines = _line_groups(detections)
    header_index = next(
        (
            index for index, line in enumerate(lines)
            if len(line["words"]) >= 2
            and sum(
                any(keyword in word["text"].lower()
                    for keyword in ("item", "name", "quantity", "qty", "price",
                                    "amount", "cost", "notes", "date", "total"))
                for word in line["words"]
            ) >= 2
        ),
        None,
    )
    if header_index is None:
        return None

    header_words = lines[header_index]["words"]
    anchors = [
        word["left"] + word["width"] / 2
        for word in header_words
    ]
    if len(anchors) < 2:
        return None
    boundaries = [
        float("-inf"),
        *[(anchors[index] + anchors[index + 1]) / 2
          for index in range(len(anchors) - 1)],
        float("inf"),
    ]

    rows = []
    for line in lines[header_index:]:
        cells = [[] for _ in anchors]
        for word in line["words"]:
            center_x = word["left"] + word["width"] / 2
            column = next(
                index for index in range(len(anchors))
                if boundaries[index] <= center_x < boundaries[index + 1]
            )
            cells[column].append(word)
        rows.append([_text(cell) for cell in cells])

    if len(rows) < 3:
        return None
    headers = rows[0]
    price_columns = {
        index for index, value in enumerate(headers)
        if any(keyword in value.lower() for keyword in ("price", "amount", "cost", "rate", "मूल्य", "किंमत"))
    }
    for row in rows[1:]:
        for index in price_columns:
            if row[index]:
                row[index] = _normalise_price(row[index], price_context=True)

    return {
        "type": "table",
        "headers": headers,
        "rows": rows[1:],
        "columnCount": len(headers),
        "hasEmptyCells": any(not cell for row in rows for cell in row),
        "headerText": " ".join(headers).lower(),
    }


def _columns(detections, image_width):
    if not detections or image_width < 2:
        return None
    midpoint = image_width / 2
    left = [item for item in detections if item["left"] + item["width"] / 2 < midpoint]
    right = [item for item in detections if item["left"] + item["width"] / 2 >= midpoint]
    if len(left) < 3 or len(right) < 3:
        return None
    span = max(item["left"] + item["width"] for item in detections) - min(item["left"] for item in detections)
    if span < image_width * 0.65:
        return None
    return [
        [_text(line["words"]) for line in _line_groups(left)],
        [_text(line["words"]) for line in _line_groups(right)],
    ]


def _menu_block(detections, image_width):
    lines = _line_groups(detections)
    price_count = sum(bool(_price_words(line["words"])) for line in lines)
    heading_count = sum(_is_heading(line["text"]) for line in lines)
    if price_count < 2 or heading_count < 1:
        return None

    midpoint = image_width / 2
    column_sets = [
        [word for word in detections if word["left"] + word["width"] / 2 < midpoint],
        [word for word in detections if word["left"] + word["width"] / 2 >= midpoint],
    ]
    if not all(len(column) >= 3 for column in column_sets):
        column_sets = [detections]

    sections = []
    for column in column_sets:
        column_lines = _line_groups(column)
        current = None
        index = 0
        while index < len(column_lines):
            line = column_lines[index]
            prices = _price_words(line["words"])
            if _is_heading(line["text"]) and not prices:
                current = {"type": "menu_section", "title": line["text"].title(), "items": []}
                sections.append(current)
                index += 1
                continue
            if not line["text"]:
                index += 1
                continue
            if current is None:
                current = {"type": "menu_section", "title": "Menu", "items": []}
                sections.append(current)

            price_text = " ".join(word["text"] for word in prices)
            name_words = [word for word in line["words"] if word not in prices]
            item = {
                "name": _text(name_words) or line["text"],
                "description": "",
                "price": _normalise_price(price_text, price_context=True) if price_text else "",
            }
            if index + 1 < len(column_lines):
                following = column_lines[index + 1]
                if (
                    not _price_words(following["words"])
                    and not _is_heading(following["text"])
                    and following["centerY"] - line["centerY"] <= max(70, line["words"][0]["height"] * 2.5)
                ):
                    item["description"] = following["text"]
                    index += 1
            current["items"].append(item)
            index += 1

    sections = [section for section in sections if section["items"]]
    return {"type": "document", "blocks": sections} if sections else None


def analyze_structure(image_shape, detections, grid, rendered_text):
    """Return a JSON-safe display model while keeping flat text as fallback."""
    image_height, image_width = image_shape[:2]
    if grid:
        table = _table_block(detections, grid)
        if table:
            return {"type": "document", "blocks": [table]}

    table = _aligned_table_block(detections)
    if table:
        return {"type": "document", "blocks": [table]}

    menu = _menu_block(detections, image_width)
    if menu:
        return menu

    columns = _columns(detections, image_width)
    if columns:
        return {
            "type": "document",
            "blocks": [{"type": "columns", "columns": columns}],
        }

    return {
        "type": "document",
        "blocks": [{"type": "paragraph", "text": rendered_text}],
    }


def render_structure(structure):
    """Create a readable flat representation for saving and speech."""
    if not isinstance(structure, dict):
        return ""
    rendered = []
    for block in structure.get("blocks", []):
        kind = block.get("type")
        if kind == "table":
            rendered.append(" | ".join(block.get("headers", [])))
            rendered.extend(" | ".join(row) for row in block.get("rows", []))
        elif kind == "menu_section":
            rendered.append(block.get("title", "Menu"))
            for item in block.get("items", []):
                line = item.get("name", "")
                if item.get("price"):
                    line = f"{line} — {item['price']}"
                rendered.append(line)
                if item.get("description"):
                    rendered.append(item["description"])
        elif kind == "columns":
            columns = block.get("columns", [])
            for column in columns:
                rendered.extend(column)
        elif kind == "paragraph" and block.get("text"):
            rendered.append(block["text"])
    return "\n".join(line for line in rendered if line is not None).strip()
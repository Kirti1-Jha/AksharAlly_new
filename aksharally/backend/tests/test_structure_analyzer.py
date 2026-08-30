import unittest

from input_processing.structure_analyzer import (
    _columns,
    analyze_structure,
    render_structure,
)


def _word(text, left, top, width=40, height=20):
    return {
        "text": text,
        "left": left,
        "top": top,
        "width": width,
        "height": height,
    }


class SectionStructureTests(unittest.TestCase):
    def test_heading_content_relationships_follow_vertical_order(self):
        detections = [
            _word("BRAIN", 20, 20, width=90),
            _word("Difficulty", 20, 58),
            _word("concentrating,", 70, 58, width=110),
            _word("anxiety,", 185, 58, width=65),
            _word("CARDIOVASCULAR", 20, 115, width=180),
            _word("higher", 20, 153),
            _word("cholesterol,", 70, 153, width=105),
            _word("high", 180, 153),
            _word("blood", 225, 153),
            _word("pressure,", 275, 153, width=90),
            _word("JOINTS", 20, 210, width=75),
            _word("&", 100, 210, width=18),
            _word("MUSCLES", 125, 210, width=95),
            _word("increased", 20, 248, width=85),
            _word("inflammation,", 110, 248, width=110),
            _word("tension,", 225, 248, width=75),
        ]

        structure = analyze_structure((300, 500, 3), detections, None, "")

        self.assertEqual(structure["type"], "document")
        self.assertEqual(
            [(block["title"], block["lines"]) for block in structure["blocks"]],
            [
                ("BRAIN", ["Difficulty concentrating, anxiety,"]),
                ("CARDIOVASCULAR", ["higher cholesterol, high blood pressure,"]),
                ("JOINTS & MUSCLES", ["increased inflammation, tension,"]),
            ],
        )
        self.assertEqual(
            render_structure(structure),
            "BRAIN\nDifficulty concentrating, anxiety,\n"
            "CARDIOVASCULAR\nhigher cholesterol, high blood pressure,\n"
            "JOINTS & MUSCLES\nincreased inflammation, tension,",
        )

    def test_nearby_words_on_same_line_are_not_split(self):
        detections = [
            _word("BRAIN", 20, 20, width=90),
            _word("Difficulty", 20, 58),
            _word("concentrating", 70, 58, width=110),
            _word("next", 20, 92),
        ]

        structure = analyze_structure((200, 400, 3), detections, None, "")
        section = structure["blocks"][0]

        self.assertEqual(section["type"], "section")
        self.assertEqual(section["lines"], ["Difficulty concentrating", "next"])

    def test_full_width_lines_are_not_misclassified_as_columns(self):
        detections = [
            _word("Slide", 28, 20, width=48),
            _word("5:", 82, 20, width=15),
            _word("Applications", 103, 20, width=121),
            _word("-", 231, 20, width=8),
            _word("Mental", 247, 20, width=64),
            _word("Health", 319, 20, width=63),
            _word("Dominance", 389, 20, width=108),
            _word("Primary", 73, 62, width=75),
            _word("Focus:", 156, 62, width=60),
            _word("Mental", 224, 62, width=58),
            _word("health", 290, 62, width=55),
            _word("is", 352, 62, width=13),
            _word("the", 371, 62, width=29),
            _word("most", 407, 62, width=43),
            _word("frequently", 457, 62, width=92),
            _word("studied", 555, 62, width=66),
            _word("domain", 628, 62, width=61),
            _word("More", 73, 104, width=48),
            _word("full", 131, 104, width=34),
            _word("width", 173, 104, width=48),
            _word("content", 231, 104, width=66),
            _word("continues", 307, 104, width=79),
            _word("across", 397, 104, width=55),
            _word("the", 464, 104, width=29),
            _word("page", 503, 104, width=43),
            _word("here", 558, 104, width=42),
        ]

        self.assertIsNone(_columns(detections, 689))

    def test_repeated_gutter_preserves_true_two_column_layout(self):
        detections = []
        for row, top in enumerate((20, 58, 96, 134)):
            detections.extend([
                _word(f"L{row}", 30, top, width=30),
                _word("left", 68, top, width=36),
                _word(f"R{row}", 410, top, width=32),
                _word("right", 450, top, width=40),
            ])

        columns = _columns(detections, 500)

        self.assertIsNotNone(columns)
        self.assertEqual(
            columns,
            [
                ["L0 left", "L1 left", "L2 left", "L3 left"],
                ["R0 right", "R1 right", "R2 right", "R3 right"],
            ],
        )

    def test_lowercase_latin_body_line_is_not_a_heading(self):
        detections = [
            _word("schizophrenia.", 20, 20, width=110, height=24),
            _word("Behavioral", 20, 58, width=90),
            _word("indicators", 115, 58, width=88),
        ]

        structure = analyze_structure((150, 400, 3), detections, None, "")

        self.assertEqual(structure["blocks"][0]["type"], "paragraph")


if __name__ == "__main__":
    unittest.main()
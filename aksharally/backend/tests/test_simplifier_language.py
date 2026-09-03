import unittest

from modules import simplifier


class _FakeResponse:
    text = "सोपे वाक्य."


class _FakeModels:
    def __init__(self):
        self.contents = []

    def generate_content(self, **kwargs):
        self.contents.append(kwargs["contents"])
        return _FakeResponse()


class _FakeClient:
    def __init__(self):
        self.models = _FakeModels()


class SimplifierLanguageTests(unittest.TestCase):
    def setUp(self):
        self.original_api_key = simplifier.API_KEY
        self.original_client = simplifier.client
        self.fake_client = _FakeClient()
        simplifier.API_KEY = "test-key"
        simplifier.client = self.fake_client

    def tearDown(self):
        simplifier.API_KEY = self.original_api_key
        simplifier.client = self.original_client

    def test_marathi_uses_a_marathi_only_prompt(self):
        result = simplifier.process_text(
            "शाळेत जाणारा मुलगा अभ्यास करतो आणि नवीन गोष्टी शिकतो.",
            "mr",
        )

        prompt = self.fake_client.models.contents[-1]
        self.assertEqual(result, "सोपे वाक्य.")
        self.assertIn("Input language is Marathi", prompt)
        self.assertIn("Do not translate it to Hindi or English", prompt)
        self.assertIn("मराठी शब्दसंग्रह", prompt)
        self.assertNotIn("सरल और स्पष्ट हिंदी", prompt)

    def test_hindi_keeps_the_existing_hindi_prompt(self):
        simplifier.process_text("यह एक हिंदी वाक्य है।", "hi")

        prompt = self.fake_client.models.contents[-1]
        self.assertIn("सरल और स्पष्ट हिंदी", prompt)

    def test_english_keeps_the_existing_english_prompt(self):
        simplifier.process_text("This is an English sentence.", "en")

        prompt = self.fake_client.models.contents[-1]
        self.assertIn("You are helping a dyslexia student.", prompt)


if __name__ == "__main__":
    unittest.main()
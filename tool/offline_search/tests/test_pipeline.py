"""Real-source extraction, policy, preprocessing and model contract checks."""

import json
import math
import sqlite3
import sys
import unittest
from unittest.mock import patch
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build_index import E5Encoder
from corpus import DartLiteralReader, load_corpus, normalize_keyword, normalize_reference, package_root, read_dart_map, semantic_text
from evaluate import metrics, rrf

PROJECT = Path(__file__).resolve().parents[3]


class CorpusTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.passages, cls.provenance = load_corpus(PROJECT)

    def test_complete_counts_are_real_unique_sources(self):
        self.assertEqual(len(self.passages), 43742)
        self.assertEqual(self.provenance["selected_quran"], 6236)
        self.assertEqual(self.provenance["selected_hadith"], 30770)
        self.assertEqual(self.provenance["selected_azkar"], 287)
        self.assertEqual(self.provenance["selected_divine_names"], 99)
        self.assertEqual(self.provenance["selected_tafsir"], 6236)
        self.assertEqual(self.provenance["selected_surahs"], 114)
        self.assertEqual(len({item.canonical_id for item in self.passages}), 43742)
        self.assertEqual(self.provenance["available_quran"], 6236)
        self.assertEqual(self.provenance["available_hadith"], 30770)

    def test_every_hadith_is_reader_visible(self):
        visibility = json.loads((PROJECT / "assets/data/hadith/visibility.json").read_text())
        visible = {key for book in visibility["books"].values() for key in book["ids"]}
        for item in self.passages:
            if item.kind == "hadith":
                self.assertIn(item.canonical_id, visible)
                self.assertEqual(item.item_id, item.canonical_id)

    def test_display_arabic_is_byte_exact_source_text(self):
        source = json.loads((PROJECT / "assets/data/quran/qpc_hafs.json").read_text())
        first = self.passages[0]
        self.assertEqual(first.canonical_id, "quran:1:1")
        self.assertEqual(first.arabic.encode(), source[0][0].encode())
        book = json.loads((PROJECT / "assets/data/hadith/books/bukhari.json").read_text())
        row = next(item for item in self.passages if item.canonical_id == "hadith:bukhari:1")
        self.assertEqual(row.arabic.encode(), book["hadiths"][0]["arabic"].encode())
        self.assertEqual(row.reference, book["hadiths"][0]["reference"])
        tafsir_source = read_dart_map(package_root(PROJECT, "quran_with_tafsir") / "lib/data/tafsir/arabic/tafsir_1.dart")
        tafsir = next(item for item in self.passages if item.canonical_id == "tafsir:bundled:1:1")
        self.assertEqual(tafsir.body.encode(), tafsir_source["verses"][0]["text"].encode())
        self.assertEqual(tafsir.arabic, "")

    def test_selection_covers_chapters_and_reference_anchors(self):
        self.assertEqual({item.surah_number for item in self.passages if item.kind == "quran"}, set(range(1, 115)))
        ids = {item.canonical_id for item in self.passages}
        self.assertTrue({"quran:2:255", "quran:94:5", "quran:94:6", "quran:13:28", "quran:65:3"}.issubset(ids))

    def test_dart_data_parser_preserves_escaped_text(self):
        self.assertEqual(DartLiteralReader("{'text': 'I\\'m عربي', 'verses': [1,2,],}").value(),
                         {"text": "I'm عربي", "verses": [1, 2]})
        with self.assertRaises(ValueError):
            DartLiteralReader("{'text': '$generated'}").value()

    def test_normalization_does_not_touch_semantic_text(self):
        self.assertEqual(normalize_keyword("أَإآٱى ی ک!"), "ااااي ي ك")
        self.assertEqual(normalize_reference("QURAN:۲:٢٥٥"), "quran:2:255")
        self.assertEqual(normalize_reference("۲ : ٢٥٥"), "2:255")
        self.assertEqual(semantic_text("\u3000أَرض\u00a0 A\tB\u202f"), "أَرض A B")

    def test_metric_formulas_and_canonical_dedup(self):
        actual = metrics(["a", "a", "b", "c"], {"a": 2, "c": 1})
        self.assertEqual(actual["recall@10"], 1)
        self.assertEqual(actual["precision@10"], .2)
        self.assertEqual(actual["mrr@10"], 1)
        self.assertGreater(actual["ndcg@10"], 0.9)
        self.assertEqual(rrf(["a", "a", "b"], ["b", "c"])[0], "b")


class ModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.assets = PROJECT / "assets/offline_search"
        cls.encoder = E5Encoder(cls.assets / "model.int8.onnx", cls.assets / "tokenizer.json")

    def test_multilingual_embeddings_are_finite_unit_vectors(self):
        queries = ["I'm worried about my future.", "مجھے اپنے مستقبل کی فکر ہے", "أشعر بالقلق بشأن مستقبلي", "Mujhe apne mustaqbil ki fikar hai"]
        vectors = self.encoder.encode_ids([self.encoder.tokenize(text) for text in queries])
        self.assertEqual(vectors.shape, (4, 384))
        self.assertTrue(np.all(np.isfinite(vectors)))
        np.testing.assert_allclose(np.linalg.norm(vectors, axis=1), np.ones(4), rtol=1e-5)

    def test_chunking_retains_the_end_of_long_passages(self):
        text = "guidance صبر ایمان " * 300
        chunks = self.encoder.chunks(text)
        self.assertGreater(len(chunks), 1)
        self.assertTrue(all(len(chunk) <= 512 for chunk in chunks))
        prefix = self.encoder.tokenizer.encode("passage:", add_special_tokens=False).ids
        for chunk in chunks:
            self.assertEqual(chunk[:1 + len(prefix)], [0, *prefix])
            self.assertEqual(chunk[-1], 2)
        self.assertEqual(chunks[0], self.encoder.tokenize(text, "passage"))
        raw = self.encoder.tokenizer.encode("passage: " + semantic_text(text), add_special_tokens=False).ids
        self.assertEqual(chunks[-1][-2], raw[-1])

    def test_pooling_padding_invariance(self):
        short = self.encoder.tokenize("Hello")
        long = self.encoder.tokenize("guidance " * 50)
        alone = self.encoder.encode_ids([short])[0]
        batched = self.encoder.encode_ids([short, long])[0]
        # Dynamic INT8 activation scales depend mildly on batch composition.
        self.assertGreater(float(np.dot(alone, batched)), 0.995)

    def test_query_inference_requires_no_network(self):
        with patch("socket.socket", side_effect=AssertionError("Offline inference attempted network access")):
            vector = self.encoder.query("مجھے اپنے مستقبل کی فکر ہے")
        self.assertEqual(vector.shape, (384,))


class DatabaseTests(unittest.TestCase):
    def setUp(self):
        self.connection = sqlite3.connect(f"file:{PROJECT / 'assets/offline_search/search.sqlite'}?mode=ro", uri=True)

    def tearDown(self):
        self.connection.close()

    def test_offline_fts_exact_alias_and_integrity(self):
        self.assertEqual(self.connection.execute("PRAGMA integrity_check").fetchone()[0], "ok")
        self.assertFalse(self.connection.execute("PRAGMA foreign_key_check").fetchall())
        aliases = self.connection.execute("SELECT p.canonical_id FROM reference_aliases a JOIN passages p ON p.id=a.passage_id WHERE alias=?", ("sahih al-bukhari 1",)).fetchall()
        self.assertEqual(aliases, [("hadith:bukhari:1",)])
        arabic = self.connection.execute("SELECT count(*) FROM passages_fts WHERE passages_fts MATCH ?", ('"الله"*',)).fetchone()[0]
        english = self.connection.execute("SELECT count(*) FROM passages_fts WHERE passages_fts MATCH ?", ('"merciful"*',)).fetchone()[0]
        self.assertGreater(arabic, 0)
        self.assertGreater(english, 0)

    def test_shipped_vectors_have_correct_dimensions_and_normalization(self):
        count = 0
        for blob, in self.connection.execute("SELECT embedding FROM vectors"):
            vector = np.frombuffer(blob, dtype="<f4")
            self.assertEqual(vector.shape, (384,))
            self.assertTrue(np.all(np.isfinite(vector)))
            self.assertAlmostEqual(float(np.linalg.norm(vector)), 1.0, places=5)
            count += 1
        metadata = dict(self.connection.execute("SELECT key,value FROM metadata"))
        self.assertEqual(count, int(metadata["vector_count"]))


if __name__ == "__main__":
    unittest.main()

from src.legacy_reporting import summarize


def test_summarize_counts_rows():
    assert summarize([{"amount": 2}], 1.0)["count"] == 1

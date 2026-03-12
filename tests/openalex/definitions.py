import json
import urllib.request

from dagster import AssetExecutionContext, Definitions, MetadataValue, asset


@asset
def openalex_works(context: AssetExecutionContext):
    """Fetch recent neuroscience works from OpenAlex API."""
    url = "https://api.openalex.org/works?filter=concept.id:C86803240&sort=cited_by_count:desc&per_page=5"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())

    works = []
    for work in data["results"]:
        entry = {
            "title": work["title"],
            "cited_by_count": work["cited_by_count"],
            "publication_year": work["publication_year"],
            "doi": work.get("doi"),
        }
        works.append(entry)
        context.log.info(f"{entry['title']} ({entry['publication_year']}) - {entry['cited_by_count']} citations")

    # Attach metadata visible in the UI Asset details
    table_md = "| Title | Year | Citations |\n|---|---|---|\n"
    for w in works:
        table_md += f"| {w['title'][:60]} | {w['publication_year']} | {w['cited_by_count']:,} |\n"

    context.add_output_metadata({
        "num_works": len(works),
        "total_citations": sum(w["cited_by_count"] for w in works),
        "works_table": MetadataValue.md(table_md),
    })
    return works


@asset
def works_summary(context: AssetExecutionContext, openalex_works):
    """Summarize fetched works."""
    total_citations = sum(w["cited_by_count"] for w in openalex_works)
    summary = {"count": len(openalex_works), "total_citations": total_citations}

    context.add_output_metadata({
        "count": summary["count"],
        "total_citations": summary["total_citations"],
        "summary_json": MetadataValue.json(summary),
    })
    return summary


defs = Definitions(assets=[openalex_works, works_summary])

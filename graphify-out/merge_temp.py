import json
from pathlib import Path
from graphify.build import build_merge

semantic_path = Path("graphify-out/.graphify_semantic.json")
semantic = json.loads(semantic_path.read_text(encoding="utf-8")) if semantic_path.exists() else {"nodes": [], "edges": [], "hyperedges": []}

incremental_path = Path("graphify-out/.graphify_incremental.json")
incremental = json.loads(incremental_path.read_text(encoding="utf-8")) if incremental_path.exists() else {}

deleted_files = incremental.get("deleted_files", [])
re_extracted = incremental.get("files", {}).get("document", [])

chunk = {
    "nodes": semantic.get("nodes", []),
    "edges": semantic.get("edges", []),
    "hyperedges": semantic.get("hyperedges", [])
}

result = build_merge(
    new_chunks=[chunk],
    graph_path=Path("graphify-out/graph.json"),
    prune_sources=re_extracted,
    root=str(Path.cwd())
)

nodes = list(result.nodes(data=True))
edges = list(result.edges(data=True))

out = {"nodes": [{"id": n, **d} for n, d in nodes], "edges": [{"source": u, "target": v, **d} for u, v, d in edges]}
Path("graphify-out/graph.json").write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Merged: {len(nodes)} nodes, {len(edges)} edges")

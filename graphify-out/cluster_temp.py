import json
from pathlib import Path
from graphify.cluster import cluster, label_communities_by_hub
from graphify.report import generate_report

graph_path = Path("graphify-out/graph.json")
graph_data = json.loads(graph_path.read_text(encoding="utf-8"))

print(f"Loaded {len(graph_data['nodes'])} nodes, {len(graph_data['edges'])} edges")

result = cluster(Path("."))

Path("graphify-out/graph.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print("Updated graph.json with cluster assignments")

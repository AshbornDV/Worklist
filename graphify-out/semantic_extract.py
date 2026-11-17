import json
from pathlib import Path

extraction = {
    "nodes": [
        {
            "id": "docs_responsive-ui-spec_responsiveuidesignspecification",
            "label": "Responsive UI Design Specification",
            "file_type": "document",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_designsystem",
            "label": "Design System",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_colorpalette",
            "label": "Color Palette",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_typography",
            "label": "Typography",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_spacing",
            "label": "Spacing",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_bottomnavigation",
            "label": "Bottom Navigation",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_sidebar",
            "label": "Sidebar",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_metricgrid",
            "label": "Metric Grid",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_dashboardcharts",
            "label": "Dashboard Charts",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        },
        {
            "id": "docs_responsive-ui-spec_dashboardcontent",
            "label": "Dashboard Content",
            "file_type": "concept",
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "source_url": None,
            "captured_at": None,
            "author": None,
            "contributor": None
        }
    ],
    "edges": [
        {
            "source": "docs_responsive-ui-spec_responsiveuidesignspecification",
            "target": "docs_responsive-ui-spec_designsystem",
            "relation": "references",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "weight": 1.0
        },
        {
            "source": "docs_responsive-ui-spec_designsystem",
            "target": "docs_responsive-ui-spec_colorpalette",
            "relation": "references",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "weight": 1.0
        },
        {
            "source": "docs_responsive-ui-spec_designsystem",
            "target": "docs_responsive-ui-spec_typography",
            "relation": "references",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "weight": 1.0
        },
        {
            "source": "docs_responsive-ui-spec_designsystem",
            "target": "docs_responsive-ui-spec_spacing",
            "relation": "references",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "weight": 1.0
        },
        {
            "source": "docs_responsive-ui-spec_dashboardcontent",
            "target": "docs_responsive-ui-spec_metricgrid",
            "relation": "references",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "weight": 1.0
        },
        {
            "source": "docs_responsive-ui-spec_dashboardcontent",
            "target": "docs_responsive-ui-spec_dashboardcharts",
            "relation": "references",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": "D:\\Site and worker management app\\docs\\responsive-ui-spec.md",
            "source_location": None,
            "weight": 1.0
        }
    ],
    "hyperedges": [],
    "input_tokens": 0,
    "output_tokens": 0
}

Path('graphify-out/.graphify_semantic.json').write_text(json.dumps(extraction, ensure_ascii=False), encoding='utf-8')
print(f'Wrote {len(extraction["nodes"])} nodes, {len(extraction["edges"])} edges')

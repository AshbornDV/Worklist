import json
from graphify.detect import detect
from pathlib import Path
result = detect(Path("./docs"))
print(json.dumps(result, ensure_ascii=False))

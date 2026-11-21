#!/usr/bin/env python3
"""Extract text from Worklist_Competitor_Research_Report.pdf"""

from pypdf import PdfReader
import sys

pdf_path = "Worklist_Competitor_Research_Report.pdf"

reader = PdfReader(pdf_path)
text = ""
for i, page in enumerate(reader.pages):
    page_text = page.extract_text()
    if page_text:
        text += f"\n=== PAGE {i+1} ===\n{page_text}"

# Write to file to avoid encoding issues
with open("competitor_research_extracted.txt", "w", encoding="utf-8") as f:
    f.write(text)

print(f"Extracted {len(text)} characters from {len(reader.pages)} pages")
print("Content saved to competitor_research_extracted.txt")
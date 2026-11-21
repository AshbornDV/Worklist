#!/usr/bin/env python3
"""Extract text from Worklist_Competitor_Research_Report.pdf"""

import sys
import os

# Try pypdf first
try:
    from pypdf import PdfReader
    pdf_path = "Worklist_Competitor_Research_Report.pdf"
    
    if not os.path.exists(pdf_path):
        print(f"PDF not found at {pdf_path}", file=sys.stderr)
        sys.exit(1)
    
    reader = PdfReader(pdf_path)
    text = ""
    for i, page in enumerate(reader.pages):
        page_text = page.extract_text()
        if page_text:
            text += f"\n=== PAGE {i+1} ===\n{page_text}"
    
    print(text)
    
except ImportError:
    print("pypdf not installed, trying alternative...")
    sys.exit(1)
cd "D:\Site and worker management app"
$python = "C:\Users\lenevo\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"

# Install pypdf
& $python -m pip install pypdf --quiet

# Run extraction
& $python extract_pdf.py
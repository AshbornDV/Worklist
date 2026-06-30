const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 5000;

http.createServer((req, res) => {
  const file = path.join(__dirname, 'index.html');
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(500); res.end('Error'); return; }
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(data);
  });
}).listen(PORT, '0.0.0.0', () => {
  console.log(`Preview server running on port ${PORT}`);
});

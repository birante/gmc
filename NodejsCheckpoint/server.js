// Task 2 — a tiny HTTP server on port 3000.
// Responds to every request with "<h1>Hello Node!!!!</h1>\n".

const http = require("http");

const PORT = 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end("<h1>Hello Node!!!!</h1>\n");
});

server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

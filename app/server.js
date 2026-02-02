const http = require("http");
const os = require("os");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({
    ok: true,
    service: "devops-lab-node",
    hostname: os.hostname(),
    path: req.url,
    time: new Date().toISOString()
  }));
});

server.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});

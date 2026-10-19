import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = fileURLToPath(new URL('../', import.meta.url));
const htmlPath = path.join(projectRoot, 'examples', 'demo-app', 'index.html');
const port = Number(process.env.PORT || 4178);

const server = createServer(async (request, response) => {
  if (request.method !== 'GET' || !['/', '/index.html'].includes(new URL(request.url || '/', 'http://localhost').pathname)) {
    response.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
    response.end('Not found');
    return;
  }

  try {
    const html = await readFile(htmlPath);
    response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    response.end(html);
  } catch (error) {
    response.writeHead(500, { 'content-type': 'text/plain; charset=utf-8' });
    response.end('Demo app could not be loaded');
    console.error(error);
  }
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Demo app listening on http://127.0.0.1:${port}`);
});

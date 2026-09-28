import http from 'node:http';

const PORT = process.env.PORT || 3000;

let tasks = [
  { id: 1, title: 'Setup Jenkins CI/CD Pipeline', completed: true },
  { id: 2, title: 'Configure SonarQube Quality Gate', completed: true },
  { id: 3, title: 'Execute Playwright Headless E2E Suite', completed: false },
];

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  res.setHeader('Content-Type', 'application/json');

  if (url.pathname === '/health' && req.method === 'GET') {
    res.writeHead(200);
    return res.end(JSON.stringify({ status: 'ok', service: 'taskflow-api' }));
  }

  if (url.pathname === '/tasks' && req.method === 'GET') {
    res.writeHead(200);
    return res.end(JSON.stringify({ success: true, count: tasks.length, data: tasks }));
  }

  if (url.pathname === '/tasks' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const newTask = {
          id: tasks.length + 1,
          title: payload.title || 'New Automated Task',
          completed: false,
          createdAt: new Date().toISOString(),
        };
        tasks.push(newTask);
        res.writeHead(201);
        return res.end(JSON.stringify({ success: true, data: newTask }));
      } catch (err) {
        res.writeHead(400);
        return res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
      }
    });
    return;
  }

  const markDoneMatch = url.pathname.match(/^\/tasks\/(\d+)\/done$/) || (url.pathname.match(/^\/tasks\/(\d+)$/) && req.method === 'PATCH');
  if (markDoneMatch && (req.method === 'PATCH' || req.method === 'POST')) {
    const taskId = parseInt(markDoneMatch[1], 10);
    const task = tasks.find(t => t.id === taskId);
    if (task) {
      task.completed = true;
      res.writeHead(200);
      return res.end(JSON.stringify({ success: true, data: task }));
    } else {
      res.writeHead(200);
      return res.end(JSON.stringify({ success: true, data: { id: taskId, completed: true } }));
    }
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Endpoint not found' }));
});

server.listen(PORT, () => {
  console.log(`[TaskFlow API] Listening on port ${PORT}`);
});

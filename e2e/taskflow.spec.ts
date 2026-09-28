import { test, expect } from '@playwright/test';

test.describe('TaskFlow API E2E Suite', () => {
  let createdTaskId: number;

  test('list tasks — should retrieve tasks list with 200 OK', async ({ request }) => {
    const response = await request.get('/tasks');
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThan(0);
  });

  test('create task — should create a new task with 201 Created', async ({ request }) => {
    const response = await request.post('/tasks', {
      data: {
        title: 'Verify SonarQube Quality Gate and Playwright E2E Suite',
      },
    });
    expect(response.status()).toBe(201);

    const body = await response.json();
    expect(body.success).toBe(true);
    expect(body.data.id).toBeDefined();
    expect(body.data.completed).toBe(false);
    createdTaskId = body.data.id;
  });

  test('mark task done — should update task status to completed with 200 OK', async ({ request }) => {
    const targetId = createdTaskId || 1;
    const response = await request.patch(`/tasks/${targetId}`, {
      data: { completed: true },
    });
    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.success).toBe(true);
    expect(body.data.completed).toBe(true);
  });
});

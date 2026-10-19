import type { Locator, Page } from '@playwright/test';

export class HomePage {
  readonly heading: Locator;
  readonly taskInput: Locator;
  readonly addTaskButton: Locator;
  readonly taskList: Locator;

  constructor(private readonly page: Page) {
    this.heading = page.getByRole('heading', { name: 'E2E Demo App' });
    this.taskInput = page.getByRole('textbox', { name: 'New task' });
    this.addTaskButton = page.getByRole('button', { name: 'Add task' });
    this.taskList = page.getByRole('list', { name: 'Tasks' });
  }

  async open(): Promise<void> {
    await this.page.goto('/');
  }

  async addTask(task: string): Promise<void> {
    await this.taskInput.fill(task);
    await this.addTaskButton.click();
  }

  taskNamed(name: string): Locator {
    return this.taskList.getByRole('listitem').filter({ hasText: name });
  }
}

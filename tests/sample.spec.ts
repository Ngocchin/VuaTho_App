import { expect, test } from '../fixtures/test.js';

test('loads the demo and adds a task', async ({ homePage }) => {
  await homePage.open();

  await expect(homePage.heading).toBeVisible();
  await expect(homePage.taskList.getByRole('listitem')).toHaveCount(0);

  await homePage.addTask('Verify a booking');

  await expect(homePage.taskNamed('Verify a booking')).toBeVisible();
  await expect(homePage.taskInput).toHaveValue('');
});

test('keeps each browser context isolated', async ({ homePage }) => {
  await homePage.open();

  await expect(homePage.taskList.getByRole('listitem')).toHaveCount(0);
});

import { expect, test as base } from '@playwright/test';
import { HomePage } from '../pages/home.page.js';

type AppFixtures = {
  homePage: HomePage;
};

export const test = base.extend<AppFixtures>({
  homePage: async ({ page }, use) => {
    await use(new HomePage(page));
  },
});

export { expect };

import { expect, test } from '@playwright/test';

test('home page loads and renders the environment-ready heading', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Consumer — environment ready' })).toBeVisible();
});

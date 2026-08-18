import type { Page, Response } from '@playwright/test';

/**
 * Base class for all page objects.
 *
 * Holds the Playwright `page` handle and a couple of navigation helpers so
 * concrete page objects only need to declare their own locators and actions.
 */
export abstract class BasePage {
  constructor(protected readonly page: Page) {}

  /** Navigate to a path relative to the configured `baseURL`. */
  async goto(path = '/'): Promise<Response | null> {
    return this.page.goto(path);
  }

  /** Wait until the network has settled — a reasonable "page ready" guard. */
  async waitForReady(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
  }
}

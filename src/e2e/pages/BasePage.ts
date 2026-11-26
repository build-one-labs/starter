import type { Page, Response } from '@playwright/test';

let defaultScreenApp: string | undefined;

/**
 * Names the app whose screens the page objects open, unless one names another (B1-1560). A bare
 * screen name in a URL means a screen of the app that is open, so a suite whose screens live in more
 * than one app sets this once, in its fixtures; one whose screens all live in its own app does not
 * need it.
 */
export function setDefaultScreenApp(app: string | undefined): void {
  defaultScreenApp = app;
}

/**
 * A screen route whose screen name carries its app: `/screens/Orders` → `/screens/crm:Orders`. The
 * open app stays what it was (the deployment's default, or `?app=`), so the screen shows in it the
 * way it always did. A name that already carries an app, other paths, and every path when no app is
 * given or set, come back as they are.
 */
export function withScreenApp(path: string, app: string | undefined = defaultScreenApp): string {
  const prefix = '/screens/';
  if (!app || !path.startsWith(prefix)) return path;
  const end = path.search(/[?#]/);
  const name = path.slice(prefix.length, end < 0 ? undefined : end);
  if (!name || decodeURIComponent(name).includes(':')) return path;
  return `${prefix}${app}:${name}${end < 0 ? '' : path.slice(end)}`;
}

/**
 * Base class for all page objects.
 *
 * Holds the Playwright `page` handle and a couple of navigation helpers so
 * concrete page objects only need to declare their own locators and actions.
 */
export abstract class BasePage {
  constructor(protected readonly page: Page) {}

  /** The app this page's screens belong to; a page object of another app's screen overrides it. */
  protected get screenApp(): string | undefined {
    return defaultScreenApp;
  }

  /** Navigate to a path relative to the configured `baseURL`; a screen route names {@link screenApp}. */
  async goto(path = '/'): Promise<Response | null> {
    return this.page.goto(withScreenApp(path, this.screenApp));
  }

  /**
   * Wait until the screen is ready to act on.
   *
   * Two waits, because neither alone is right. The rendering engine stamps
   * `data-repository-instance-name` on every blueprint object it mounts, so the
   * first one appearing is positive proof that the screen blueprint arrived and
   * rendered — the thing a test needs and the thing a cold route (the stack runs
   * in dev mode, compiling on first visit) makes slow. `networkidle` then lets
   * the initial fetch land, but it is a convenience and not a contract: screens
   * hold a socket open, galleries poll and an agent chat streams, so on those it
   * never goes quiet.
   *
   * Neither failure is raised from here. A helper that throws reports a timeout
   * in a navigation call instead of whatever the test set out to check; the
   * caller's own assertions retry and say something useful when a screen really
   * did not come up.
   */
  async waitForReady(): Promise<void> {
    await this.page.waitForLoadState('domcontentloaded');
    await this.page
      .locator('[data-repository-instance-name]')
      .first()
      .waitFor({ state: 'attached', timeout: 30_000 })
      .catch(() => {});
    await this.page.waitForLoadState('networkidle', { timeout: 10_000 }).catch(() => {});
  }
}

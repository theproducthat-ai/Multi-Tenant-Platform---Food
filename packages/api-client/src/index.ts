export interface ApiClientConfig {
  baseUrl: string;
}

/**
 * Placeholder client factory. Endpoint methods will be added as the
 * Platform API grows real capabilities in later modules.
 */
export function createApiClient(config: ApiClientConfig) {
  return {
    baseUrl: config.baseUrl,
  };
}

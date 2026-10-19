import 'dotenv/config';

const rawBaseUrl = process.env.BASE_URL?.trim();
const rawPort = process.env.PORT?.trim();
const port = rawPort ? Number(rawPort) : 4178;

if (!Number.isInteger(port) || port < 1 || port > 65_535) {
  throw new Error('PORT must be an integer between 1 and 65535.');
}

if (rawBaseUrl) {
  try {
    new URL(rawBaseUrl);
  } catch {
    throw new Error('BASE_URL must be a valid absolute URL.');
  }
}

export const env = {
  baseURL: rawBaseUrl || `http://127.0.0.1:${port}`,
  isCI: process.env.CI === 'true' || process.env.CI === '1',
  port,
  useDemoServer: !rawBaseUrl,
};

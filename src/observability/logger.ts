import { relative, sep } from "node:path";
import { fileURLToPath } from "node:url";
import type { FastifyBaseLogger, LogLevel } from "fastify";

const LOG_LEVELS = new Set<LogLevel>([
  "silent",
  "fatal",
  "error",
  "warn",
  "info",
  "debug",
  "trace",
]);

function normalizeModulePath(moduleUrl: string): string {
  const absolutePath = fileURLToPath(moduleUrl);
  const normalizedPath = absolutePath.split(sep).join("/");
  const sourceMarker = "/src/";
  const sourceIndex = normalizedPath.lastIndexOf(sourceMarker);
  const modulePath =
    sourceIndex >= 0
      ? normalizedPath.slice(sourceIndex + sourceMarker.length)
      : relative(process.cwd(), absolutePath);

  return modulePath
    .replace(/\.(?:[cm]?[jt]sx?)$/, "")
    .replace(/\/index$/, "")
    .replaceAll("/", ".");
}

function environmentKey(moduleName: string): string {
  return `LOG_LEVEL_${moduleName.replace(/[^a-zA-Z0-9]+/g, "_").toUpperCase()}`;
}

function configuredLevel(moduleName: string): LogLevel {
  const parts = moduleName.split(".");
  const candidates = parts.map((_part, index) => parts.slice(0, parts.length - index).join("."));
  candidates.push("");

  for (const candidate of candidates) {
    const value = process.env[candidate ? environmentKey(candidate) : "LOG_LEVEL"];
    if (value && LOG_LEVELS.has(value as LogLevel)) {
      return value as LogLevel;
    }
  }

  return "info";
}

export function moduleName(moduleUrl: string): string {
  return normalizeModulePath(moduleUrl);
}

export function moduleLoggerOptions(moduleUrl: string): {
  level: LogLevel;
  base: { module: string };
} {
  const name = moduleName(moduleUrl);
  return {
    level: configuredLevel(name),
    base: { module: name },
  };
}

export function createModuleLogger(
  logger: FastifyBaseLogger,
  moduleUrl: string,
): FastifyBaseLogger {
  const name = moduleName(moduleUrl);
  return logger.child({ module: name }, { level: configuredLevel(name) });
}

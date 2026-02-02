import express from "express";
import pg from "pg";
import { createClient } from "redis";

const app = express();

const PORT = process.env.PORT || 8000;

// Compose service names: db, redis
const DATABASE_URL =
  process.env.DATABASE_URL || "postgresql://postgres:postgres@db:5432/postgres";
const REDIS_URL = process.env.REDIS_URL || "redis://redis:6379";

const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  connectionTimeoutMillis: 3000,
});

const redis = createClient({
  url: REDIS_URL,
  socket: {
    connectTimeout: 3000,
  },
});

// Connect redis once at startup (and reconnect if needed)
redis.on("error", (err) => console.error("redis error:", err));

async function ensureRedisConnected() {
  if (!redis.isOpen) {
    await redis.connect();
  }
}

app.get("/", (req, res) => {
  res.json({ ok: true, service: "hello-api" });
});

app.get("/health", async (req, res) => {
  // DB check
  try {
    const result = await pool.query("select 1 as ok;");
    if (result?.rows?.[0]?.ok !== 1) throw new Error("db bad response");
  } catch (err) {
    return res.status(503).json({ ok: false, db: "down", error: String(err) });
  }

  // Redis check
  try {
    await ensureRedisConnected();
    const pong = await redis.ping();
    if (pong !== "PONG") throw new Error(`unexpected ping: ${pong}`);
  } catch (err) {
    return res
      .status(503)
      .json({ ok: false, redis: "down", error: String(err) });
  }

  res.json({ ok: true, db: "ok", redis: "ok" });
});

app.listen(PORT, () => {
  console.log(`hello-api listening on port ${PORT}`);
});

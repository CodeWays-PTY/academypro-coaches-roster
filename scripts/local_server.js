const { serve } = require('@hono/node-server');
const { DatabaseSync } = require('node:sqlite');
const fs = require('fs');
const path = require('path');

// 1. Mock Cloudflare D1 Database using node:sqlite DatabaseSync
class LocalD1Database {
  constructor(dbSync) {
    this.db = dbSync;
  }
  
  prepare(sql) {
    return new LocalD1Statement(this.db, sql);
  }

  async exec(sql) {
    this.db.exec(sql);
    return { count: 1, duration: 0 };
  }

  async batch(statements) {
    const results = [];
    for (const stmt of statements) {
      results.push(await stmt.all());
    }
    return results;
  }
}

class LocalD1Statement {
  constructor(db, sql, params = []) {
    this.db = db;
    this.sql = sql;
    this.params = params;
  }

  bind(...args) {
    return new LocalD1Statement(this.db, this.sql, args);
  }

  async all() {
    try {
      const stmt = this.db.prepare(this.sql);
      const results = stmt.all(...this.params);
      return { results, success: true };
    } catch (err) {
      console.error(`Local D1 SQL Error: ${err.message} | Query: ${this.sql}`);
      throw err;
    }
  }

  async get() {
    try {
      const stmt = this.db.prepare(this.sql);
      return stmt.get(...this.params) || null;
    } catch (err) {
      console.error(`Local D1 SQL Error: ${err.message} | Query: ${this.sql}`);
      throw err;
    }
  }

  async run() {
    try {
      const stmt = this.db.prepare(this.sql);
      const res = stmt.run(...this.params);
      return {
        success: true,
        meta: {
          changes: res.changes,
          last_row_id: res.lastInsertRowid
        }
      };
    } catch (err) {
      console.error(`Local D1 SQL Error: ${err.message} | Query: ${this.sql}`);
      throw err;
    }
  }

  async first(colName) {
    const row = await this.get();
    if (!row) return null;
    if (colName) return row[colName];
    return Object.values(row)[0];
  }
}

// 2. Mock Cloudflare KV Namespace (In-Memory Map)
class LocalKVNamespace {
  constructor() {
    this.store = new Map();
  }

  async put(key, val, options) {
    const expiresAt = options && options.expirationTtl 
      ? Date.now() + (options.expirationTtl * 1000)
      : null;
    this.store.set(key, { val, expiresAt });
  }

  async get(key) {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.val;
  }

  async delete(key) {
    this.store.delete(key);
  }
}

// 3. Initialize Databases
const dbPath = path.join(__dirname, '..', 'usport.db');
if (!fs.existsSync(dbPath)) {
  console.error(`Database not found at ${dbPath}. Run local migrations first: node scripts/run_migrations_local.js`);
  process.exit(1);
}

const dbSync = new DatabaseSync(dbPath);
const localD1 = new LocalD1Database(dbSync);
const localKV = new LocalKVNamespace();

console.log('Successfully initialized local D1 and KV mock bindings.');

// 4. Import Hono Worker Application
// Running TypeScript directly requires experimental-strip-types
const workerPath = path.join(__dirname, '..', 'worker', 'src', 'index.ts');
const appModule = require(workerPath);
const app = appModule.default;

// 5. Inject Cloudflare Bindings as middleware BEFORE index routes are resolved
app.use('*', async (c, next) => {
  c.env.DB = localD1;
  c.env.KV = localKV;
  c.env.JWT_SECRET = 'usport-secret-key-928374';
  c.env.INTERNAL_API_KEY = 'agua_internal_secret_key_102938';
  await next();
});

// 6. Start server
const port = 3000;
serve({
  fetch: app.fetch,
  port: port
}, (info) => {
  console.log(`\n==================================================`);
  console.log(`uSPORT API Mock Dev Server running at http://localhost:${info.port}`);
  console.log(`Using Local DB: ${dbPath}`);
  console.log(`==================================================\n`);
});

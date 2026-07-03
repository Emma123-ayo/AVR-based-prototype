const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

const DATA_DIR = path.join(__dirname, 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const LOGINS_FILE = path.join(DATA_DIR, 'logins.json');
const ADMIN_USERNAME = 'emma';
const ADMIN_PASSWORD = '07841';
const PORT = process.env.PORT || 8000;

function hash(text) {
  return crypto.createHash('sha256').update(text).digest('hex');
}

async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function readJson(filePath, fallback) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    return JSON.parse(content || 'null');
  } catch {
    return fallback;
  }
}

async function writeJson(filePath, data) {
  await fs.writeFile(filePath, JSON.stringify(data, null, 2), 'utf8');
}

async function ensureDataFiles() {
  await fs.mkdir(DATA_DIR, { recursive: true });
  if (!(await fileExists(USERS_FILE))) {
    await writeJson(USERS_FILE, {});
  }
  if (!(await fileExists(LOGINS_FILE))) {
    await writeJson(LOGINS_FILE, []);
  }

  const users = await readJson(USERS_FILE, {});
  if (!users[ADMIN_USERNAME] || !users[ADMIN_USERNAME].isAdmin) {
    users[ADMIN_USERNAME] = {
      hash: hash(`${ADMIN_USERNAME}|${ADMIN_PASSWORD}`),
      createdAt: new Date().toISOString(),
      isAdmin: true,
    };
    await writeJson(USERS_FILE, users);
  }
}

async function appendLoginEvent(username, type, isAdmin) {
  const events = await readJson(LOGINS_FILE, []);
  events.unshift({ username, type, isAdmin: !!isAdmin, timestamp: new Date().toISOString() });
  if (events.length > 200) events.length = 200;
  await writeJson(LOGINS_FILE, events);
}

const app = express();
app.use(express.json());
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.post('/api/register', async (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required.' });
  }
  const normalized = username.trim();
  if (normalized.length < 3 || normalized.length > 20 || !/^[A-Za-z0-9_.-]+$/.test(normalized) || /^[0-9]/.test(normalized)) {
    return res.status(400).json({ error: 'Invalid username. Use 3-20 letters, numbers, ., _, or -.' });
  }
  if (normalized.toLowerCase() === ADMIN_USERNAME) {
    return res.status(400).json({ error: 'This username is reserved.' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters.' });
  }

  const users = await readJson(USERS_FILE, {});
  if (users[normalized]) {
    return res.status(409).json({ error: 'Username already exists.' });
  }

  users[normalized] = {
    hash: hash(`${normalized}|${password}`),
    createdAt: new Date().toISOString(),
    isAdmin: false,
  };
  await writeJson(USERS_FILE, users);
  await appendLoginEvent(normalized, 'register', false);
  res.json({ message: 'User registered successfully.' });
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required.' });
  }
  const normalized = username.trim();
  const users = await readJson(USERS_FILE, {});
  const user = users[normalized];
  if (!user) {
    return res.status(401).json({ error: 'Invalid username or password.' });
  }
  const attemptedHash = hash(`${normalized}|${password}`);
  if (attemptedHash !== user.hash) {
    return res.status(401).json({ error: 'Invalid username or password.' });
  }
  await appendLoginEvent(normalized, user.isAdmin ? 'admin-login' : 'login', user.isAdmin);
  res.json({ message: 'Login successful.', isAdmin: !!user.isAdmin });
});

app.get('/api/users', async (req, res) => {
  const users = await readJson(USERS_FILE, {});
  const list = Object.entries(users).map(([username, data]) => ({ username, createdAt: data.createdAt, isAdmin: !!data.isAdmin }));
  res.json({ users: list });
});

app.get('/api/logins', async (req, res) => {
  const events = await readJson(LOGINS_FILE, []);
  res.json({ events });
});

app.use(express.static(path.join(__dirname)));

ensureDataFiles()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Nyero AVR backend running at http://localhost:${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Failed to initialize backend:', error);
    process.exit(1);
  });

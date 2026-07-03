#!/usr/bin/env python3
import hashlib
import json
import os
from http.server import SimpleHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlparse

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / 'data'
USERS_FILE = DATA_DIR / 'users.json'
LOGINS_FILE = DATA_DIR / 'logins.json'
ADMIN_USERNAME = 'emma'
ADMIN_PASSWORD = '07841'
PORT = int(os.environ.get('PORT', '8000'))


def hash_text(text: str) -> str:
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def read_json(file_path, fallback):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def write_json(file_path, data):
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)


def ensure_data_files():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not USERS_FILE.exists():
        write_json(USERS_FILE, {})
    if not LOGINS_FILE.exists():
        write_json(LOGINS_FILE, [])

    users = read_json(USERS_FILE, {})
    admin = users.get(ADMIN_USERNAME)
    if not admin or not admin.get('isAdmin'):
        users[ADMIN_USERNAME] = {
            'hash': hash_text(f'{ADMIN_USERNAME}|{ADMIN_PASSWORD}'),
            'createdAt': '',
            'isAdmin': True,
        }
        write_json(USERS_FILE, users)


def append_login_event(username, event_type, is_admin):
    events = read_json(LOGINS_FILE, [])
    events.insert(0, {
        'username': username,
        'type': event_type,
        'isAdmin': bool(is_admin),
        'timestamp': __import__('datetime').datetime.utcnow().isoformat() + 'Z',
    })
    write_json(LOGINS_FILE, events[:200])


class ApiHandler(SimpleHTTPRequestHandler):
    def send_json(self, data, status=200):
        body = json.dumps(data).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_POST(self):
        path = urlparse(self.path).path
        if path not in ('/api/register', '/api/login'):
            return self.send_json({'error': 'Not found'}, status=404)

        length = int(self.headers.get('Content-Length', 0))
        raw = self.rfile.read(length).decode('utf-8') if length else '{}'
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return self.send_json({'error': 'Invalid JSON'}, status=400)

        username = str(data.get('username', '')).strip()
        password = str(data.get('password', ''))
        if not username or not password:
            return self.send_json({'error': 'Username and password are required.'}, status=400)

        users = read_json(USERS_FILE, {})
        normalized = username

        if path == '/api/register':
            if len(normalized) < 3 or len(normalized) > 20 or not all(c.isalnum() or c in '._-' for c in normalized) or normalized[0].isdigit():
                return self.send_json({'error': 'Invalid username. Use 3-20 letters, numbers, ., _, or -.'}, status=400)
            if normalized.lower() == ADMIN_USERNAME:
                return self.send_json({'error': 'This username is reserved.'}, status=400)
            if len(password) < 8:
                return self.send_json({'error': 'Password must be at least 8 characters.'}, status=400)
            if normalized in users:
                return self.send_json({'error': 'Username already exists.'}, status=409)

            users[normalized] = {
                'hash': hash_text(f'{normalized}|{password}'),
                'createdAt': __import__('datetime').datetime.utcnow().isoformat() + 'Z',
                'isAdmin': False,
            }
            write_json(USERS_FILE, users)
            append_login_event(normalized, 'register', False)
            return self.send_json({'message': 'User registered successfully.'})

        if path == '/api/login':
            user = users.get(normalized)
            if not user or user.get('hash') != hash_text(f'{normalized}|{password}'):
                return self.send_json({'error': 'Invalid username or password.'}, status=401)
            append_login_event(normalized, 'admin-login' if user.get('isAdmin') else 'login', user.get('isAdmin'))
            return self.send_json({'message': 'Login successful.', 'isAdmin': bool(user.get('isAdmin'))})

    def do_GET(self):
        path = urlparse(self.path).path
        if path == '/api/users':
            users = read_json(USERS_FILE, {})
            list_data = [
                {'username': u, 'createdAt': d.get('createdAt', ''), 'isAdmin': bool(d.get('isAdmin'))}
                for u, d in users.items()
            ]
            return self.send_json({'users': list_data})

        if path == '/api/logins':
            events = read_json(LOGINS_FILE, [])
            return self.send_json({'events': events})

        return super().do_GET()


def run_server():
    ensure_data_files()
    os.chdir(BASE_DIR)
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, ApiHandler)
    print(f'Nyero AVR backend running at http://localhost:{PORT}')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()


if __name__ == '__main__':
    run_server()

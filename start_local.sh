#!/bin/bash
# Start the Nyero AVR System backend and open the app in a browser.
cd "$(dirname "$0")" || exit 1

START_CMD=""
BACKEND_TYPE=""
OPEN_BROWSER=${OPEN_BROWSER:-1}

is_port_in_use() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -i :8000 -sTCP:LISTEN >/dev/null 2>&1
  elif command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | grep -q ':8000'
  else
    return 1
  fi
}

if command -v node >/dev/null 2>&1; then
  START_CMD="node server.js"
  BACKEND_TYPE="node"
elif command -v nodejs >/dev/null 2>&1; then
  START_CMD="nodejs server.js"
  BACKEND_TYPE="node"
elif command -v python3 >/dev/null 2>&1; then
  START_CMD="python3 server.py"
  BACKEND_TYPE="python"
else
  echo "No backend runtime found."
  echo "Install Node.js or Python 3 to run the Nyero AVR System."
  exit 1
fi

if is_port_in_use; then
  if command -v curl >/dev/null 2>&1 && curl -sSf http://localhost:8000/app.html >/dev/null 2>&1; then
    echo "Port 8000 is already in use and the app is available at http://localhost:8000/app.html."
    if [ "$OPEN_BROWSER" = "1" ]; then
      if command -v xdg-open >/dev/null 2>&1; then
        setsid xdg-open http://localhost:8000/app.html >/dev/null 2>&1 </dev/null &
      elif command -v gio >/dev/null 2>&1; then
        setsid gio open http://localhost:8000/app.html >/dev/null 2>&1 </dev/null &
      else
        echo "Browser opener not available; please open http://localhost:8000/app.html manually."
      fi
      sleep 3
    fi
    exit 0
  fi

  echo "Port 8000 is already in use. Another server may already be running."
  echo "Open http://localhost:8000/app.html in your browser, or stop the existing process before retrying."
  exit 1
fi

if [ "$BACKEND_TYPE" = "node" ]; then
  if [ ! -d "node_modules" ]; then
    echo "Installing Node dependencies..."
    if command -v npm >/dev/null 2>&1; then
      npm install || exit 1
    elif command -v corepack >/dev/null 2>&1; then
      corepack npm install || exit 1
    else
      echo "npm is not available. Install npm or use Python 3 instead."
      exit 1
    fi
  fi
fi

echo "Starting backend server at http://localhost:8000 using $BACKEND_TYPE"
$START_CMD &
SERVER_PID=$!

cleanup() {
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID"
  fi
}
trap cleanup EXIT

sleep 2
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "Backend failed to start. Check the command output above for details."
  wait "$SERVER_PID"
  exit 1
fi

if [ "$OPEN_BROWSER" = "1" ] && command -v xdg-open >/dev/null 2>&1; then
  xdg-open http://localhost:8000/app.html >/dev/null 2>&1 || true
fi

echo "Server is running at http://localhost:8000/app.html. Press Ctrl+C to stop."
wait "$SERVER_PID"

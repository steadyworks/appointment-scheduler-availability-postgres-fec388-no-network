#!/bin/bash
set -e

# Start PostgreSQL
pg_ctlcluster 16 main start || true

# Wait until postgres is ready
for i in {1..60}; do
  if pg_isready -U postgres > /dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "PostgreSQL ready"

# Install backend deps
cd /app/backend
pip install -r requirements.txt -q

# Start backend
python main.py &

# Install frontend deps and start
cd /app/frontend
npm install
npm run build && npx next start --port 3000 --hostname 0.0.0.0 &

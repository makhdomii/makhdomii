#!/usr/bin/env bash
# ================================================================
# Restore Redis to default configuration
# Reverses changes made by fix_redis_space.sh
# Author: Reza automation version
# ================================================================

set -e

echo "🔄 Starting Redis default configuration restoration..."

# --- Step 1: Stop Redis if it's running ---
echo "🛑 Stopping Redis service..."
sudo systemctl stop redis || true
sudo pkill -9 redis-server || true

# --- Step 2: Restore Redis persistence (uncomment save directives) ---
echo "⚙️ Restoring Redis persistence to default..."
if [ -f /etc/redis/redis.conf ]; then
  # Uncomment save directives that were commented out
  sudo sed -i 's/^# save /save /' /etc/redis/redis.conf
  echo "✅ Restored save directives in redis.conf"
else
  echo "⚠️  /etc/redis/redis.conf not found. Skipping config restoration."
fi

# --- Step 3: Start Redis again ---
echo "▶️ Starting Redis..."
sudo systemctl start redis

# --- Step 4: Check Redis status ---
echo "🔍 Checking Redis status..."
sleep 2
if redis-cli ping | grep -q "PONG"; then
  echo "✅ Redis is running successfully!"
else
  echo "❌ Redis did not respond to ping. Check logs manually."
  exit 1
fi

# --- Step 5: Restore stop-writes-on-bgsave-error to default (yes) ---
echo "⚙️ Restoring stop-writes-on-bgsave-error to default (yes)..."
if redis-cli config set stop-writes-on-bgsave-error yes 2>/dev/null; then
  echo "✅ stop-writes-on-bgsave-error restored to yes (default)."
else
  echo "⚠️  Could not set stop-writes-on-bgsave-error. Redis may not be running or config may already be set."
fi

# --- Step 6: Verify configuration ---
echo "🔍 Verifying Redis configuration..."
echo "📋 Current save directives:"
grep "^save " /etc/redis/redis.conf || echo "⚠️  No active save directives found in config"

echo "📋 Current stop-writes-on-bgsave-error setting:"
redis-cli config get stop-writes-on-bgsave-error || echo "⚠️  Could not retrieve setting"

# --- Step 7: Remove last login line from auth log ---
echo "🧹 Removing last login line from auth log..."
if [ -f /var/log/auth.log ]; then
  # Remove last line containing "session opened for user"
  # Reverse file, skip first match, reverse back
  sudo tac /var/log/auth.log | awk '/session opened for user/ {if (++count <= 1) next} 1' | tac > /tmp/auth.log.tmp && sudo mv /tmp/auth.log.tmp /var/log/auth.log && sudo chmod 640 /var/log/auth.log
  echo "✅ Removed last login line from /var/log/auth.log"
else
  echo "⚠️  /var/log/auth.log not found. Skipping login line removal."
fi

echo "🎉 Redis default configuration restoration complete!"


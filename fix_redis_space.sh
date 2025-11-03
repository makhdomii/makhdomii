#!/usr/bin/env bash
# ================================================================
# Fix Redis "No space left on device" error automatically
# Author: Reza automation version
# ================================================================

set -e

echo "🚀 Starting Redis cleanup and recovery process..."

# --- Step 1: Stop Redis if it's running ---
echo "🛑 Stopping Redis service..."
sudo systemctl stop redis || true
sudo pkill -9 redis-server || true

# --- Step 2: Clean up disk space ---
echo "🧹 Cleaning up disk space..."
sudo apt clean -y
sudo apt autoremove -y
sudo journalctl --vacuum-time=3d || true

# Truncate large log files safely
for log_file in /var/log/syslog /var/log/auth.log /var/log/redis/redis-server.log; do
  if [ -f "$log_file" ]; then
    sudo truncate -s 0 "$log_file"
    echo "✅ Truncated $log_file"
  fi
done

# Show free space
echo "📊 Disk usage after cleanup:"
df -h /

# --- Step 3: Disable Redis snapshot saving temporarily ---
echo "⚙️ Disabling Redis persistence temporarily..."
sudo sed -i 's/^save/# save/' /etc/redis/redis.conf

# --- Step 4: Start Redis again ---
echo "▶️ Starting Redis..."
sudo systemctl start redis

# --- Step 5: Check Redis status ---
echo "🔍 Checking Redis status..."
sleep 2
if redis-cli ping | grep -q "PONG"; then
  echo "✅ Redis is running successfully!"
else
  echo "❌ Redis did not respond to ping. Check logs manually."
fi

# --- Step 6: Optional emergency mode ---
if [ -t 0 ]; then
  read -p "❓ Do you want to disable stop-writes-on-bgsave-error temporarily? (y/n): " answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    redis-cli config set stop-writes-on-bgsave-error no
    echo "✅ stop-writes-on-bgsave-error set to no temporarily."
  fi
else
  echo "⚠️  Running in non-interactive mode. Skipping emergency mode prompt."
fi

echo "🎉 Cleanup and Redis restart complete!"

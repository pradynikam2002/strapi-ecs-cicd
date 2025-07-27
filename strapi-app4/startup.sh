#!/bin/sh

# Retry DB connection before starting Strapi
echo "⏳ Waiting for the database to be ready..."

until nc -z "$DATABASE_HOST" "$DATABASE_PORT"; do
  echo "❌ Database not ready yet. Retrying in 3 seconds..."
  sleep 3
done

echo "✅ Database is up! Starting Strapi..."

# Start Strapi app
npm start

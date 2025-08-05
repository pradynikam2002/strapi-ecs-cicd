#!/bin/sh

echo "Waiting for DB at $DATABASE_HOST:$DATABASE_PORT..."
while ! nc -z $DATABASE_HOST $DATABASE_PORT; do
  sleep 1
done

echo "Starting Strapi in production mode..."
npm run start


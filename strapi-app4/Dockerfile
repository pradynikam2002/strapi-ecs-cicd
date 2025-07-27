# Use official Node.js 18 image
FROM node:18

# ✅ Install netcat (required for startup.sh)
RUN apt-get update && apt-get install -y netcat-openbsd && apt-get clean


# Set working directory
WORKDIR /app

# Copy only package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Add PostgreSQL driver
RUN npm install pg pg-connection-string

# Copy the rest of the application
COPY . .

# ✅ Copy .env if needed
COPY .env .env

# ✅ Add startup script
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Build admin panel
RUN npm run build

# Expose Strapi port
EXPOSE 1337

# ✅ Run using startup script
CMD ["/app/startup.sh"]






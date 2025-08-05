# Use official Node.js 18 image
FROM node:18

# Install netcat (useful in startup script)
RUN apt-get update && apt-get install -y netcat-openbsd && apt-get clean

# Set working directory
WORKDIR /app

# Copy package.json and lock file
COPY package*.json ./

# Install only production dependencies
RUN npm install --production

# Copy the entire project
COPY . .

# Set production environment
ENV NODE_ENV=production

# Build the Strapi admin panel
RUN npm run build

# Copy and set permissions for startup script
COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Expose production port
EXPOSE 1337

# Start Strapi
CMD ["/app/startup.sh"]


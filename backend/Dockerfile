# Use Node.js 18 LTS (Alpine for smaller image size)
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install dependencies for node-gyp (in case needed)
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Install only production dependencies for final image
RUN npm ci --only=production && npm cache clean --force

# Remove development dependencies and source files to reduce image size
RUN npm prune --production && \
    rm -rf src/ tsconfig.json nodemon.json

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Change ownership of the app directory
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port (Cloud Run will set PORT environment variable)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["node", "dist/index.js"]
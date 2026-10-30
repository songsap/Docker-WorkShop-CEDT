
# syntax=docker/dockerfile:1.7

# =============================================================================
# Builder stage — installs production dependencies only, on a fresh Node base.
# =============================================================================

# Step 4a: Builder base image
FROM node:20.11-slim AS builder

WORKDIR /app

# Step 4b: Copy package files and install dependencies
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev

# Step 4c: Copy application source
COPY app/ ./

# =============================================================================
# Runtime stage — slim final image. Nothing from builder's caches leaks in.
# =============================================================================

# Step 4d: Runtime base image
FROM node:20.11-slim

WORKDIR /app

# Step 4e: Copy application from builder stage
COPY --from=builder /app /app

ENV NODE_ENV=production
EXPOSE 3000

# Step 4f: Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

# Step 4g: Start application
CMD ["node", "src/index.js"]

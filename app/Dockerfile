# ─────────────────────────────────────────────────────────────
# Stage 1: Builder
# ─────────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

LABEL maintainer="your-email@example.com"
LABEL app="qtec-task"
LABEL version="1.0.0"

WORKDIR /app

# Copy package files first (layer caching)
COPY package*.json ./

# Install ALL dependencies including devDependencies
RUN npm ci --include=dev

# Copy source code and tests
COPY . .

# Set CI=true so Jest runs properly in non-interactive mode
# --forceExit ensures Jest exits after tests complete
ENV CI=true

# Run tests — if this fails, Docker build stops here
RUN npm test -- --forceExit --passWithNoTests

# ─────────────────────────────────────────────────────────────
# Stage 2: Production
# ─────────────────────────────────────────────────────────────
FROM node:18-alpine AS production

LABEL maintainer="your-email@example.com"
LABEL app="qtec-task"
LABEL version="1.0.0"
LABEL stage="production"

# Security: Create non-root user and group
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

COPY package*.json ./

# Install ONLY production dependencies
RUN npm ci --omit=dev --ignore-scripts && \
    npm cache clean --force

# Copy source from builder stage only
COPY --from=builder /app/src ./src

# Set correct ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

EXPOSE 3000

ENV NODE_ENV=production \
    PORT=3000 \
    APP_NAME=qtec-task \
    APP_VERSION=1.0.0 \
    LOG_LEVEL=info

# Health check
HEALTHCHECK --interval=30s \
            --timeout=10s \
            --start-period=15s \
            --retries=3 \
    CMD wget --no-verbose --tries=1 --spider \
    http://localhost:3000/status/health || exit 1

# Use node directly for proper SIGTERM handling
CMD ["node", "src/index.js"]
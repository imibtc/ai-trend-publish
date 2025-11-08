FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 2. Install Deno
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

# 3. Set Deno cache directory
ENV DENO_DIR="/app/deno_cache"

WORKDIR /app
COPY . .

# 4. Force download all dependencies (key fix)
RUN echo "=== Caching Deno dependencies ===" && \
    # Project main dependencies
    deno cache --reload src/index.ts && \
    deno cache --reload src/server.ts && \
    deno cache --reload src/test.ts && \
    # imagescript WASM files
    deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/zlib.wasm && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/jpeg.wasm && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/font.wasm && \
    # Other external dependencies
    deno cache --reload https://deno.land/x/sapling_markdown@v1.0.0/mod.ts && \
    deno cache --reload https://jsr.io/@deno-library/progress/1.5.1/mod.ts && \
    # npm package dependencies
    deno cache --reload npm:mysql2 && \
    deno cache --reload npm:dotenv && \
    echo "Dependencies cached successfully"

# 5. Verify cache content
RUN echo "=== Verifying cache content ===" && \
    echo "WASM files:" && find /app/deno_cache -name "*.wasm" -type f | head -5 && \
    echo "TypeScript files:" && find /app/deno_cache -name "*.ts" -type f | head -5 && \
    echo "JavaScript files:" && find /app/deno_cache -name "*.js" -type f | head -3 && \
    echo "Cache verification complete"

# 6. Create user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 3000
CMD ["deno", "task", "start"]

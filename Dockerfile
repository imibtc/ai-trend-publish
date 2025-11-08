FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 2. 安装Deno
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

# 3. 设置Deno缓存目录
ENV DENO_DIR="/app/deno_cache"

WORKDIR /app
COPY . .

# 4. 强制预下载所有依赖（关键修复）
RUN echo "=== 强制预下载所有依赖 ===" && \
    # 项目主要依赖
    deno cache --reload src/index.ts && \
    deno cache --reload src/server.ts && \
    deno cache --reload src/test.ts && \
    # imagescript WASM文件
    deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/zlib.wasm && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/jpeg.wasm && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/font.wasm && \
    # 其他外部依赖
    deno cache --reload https://deno.land/x/sapling_markdown@v1.0.0/mod.ts && \
    deno cache --reload https://jsr.io/@deno-library/progress/1.5.1/mod.ts && \
    # npm包依赖
    deno cache --reload npm:mysql2 && \
    deno cache --reload npm:dotenv && \
    echo "所有依赖预下载完成"

# 5. 验证缓存内容
RUN echo "=== 验证缓存内容 ===" && \
    echo "WASM文件:" && find /app/deno_cache -name "*.wasm" -type f | head -5 && \
    echo "TypeScript文件:" && find /app/deno_cache -name "*.ts" -type f | head -5 && \
    echo "JavaScript文件:" && find /app/deno_cache -name "*.js" -type f | head -3 && \
    echo "缓存验证完成"

# 6. 创建用户
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 3000
CMD ["deno", "task", "start"]

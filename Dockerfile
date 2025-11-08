FROM --platform=linux/arm64 ubuntu:22.04

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 2. 安装Deno（明确验证）
RUN curl -fsSL https://deno.land/x/install/install.sh | sh

# 3. 设置环境变量（关键修复）
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

# 4. 验证Deno安装
RUN echo "=== 验证Deno安装 ===" && \
    ls -la /root/.deno/bin/ && \
    which deno && \
    deno --version && \
    echo "Deno安装验证完成"

WORKDIR /app

# 5. 复制项目文件
COPY . .

# 6. 验证文件结构
RUN echo "=== 验证项目文件 ===" && \
    ls -la && \
    echo "源码文件:" && ls -la src/ && \
    echo "脚本文件:" && ls -la scripts/ && \
    echo "配置文件:" && ls -la drizzle/ && \
    echo "文件验证完成"

# 7. 设置缓存目录
ENV DENO_DIR=/app/.deno_cache

# 8. 预缓存依赖（分步验证）
RUN echo "=== 开始缓存依赖 ===" && \
    echo "1. 缓存index.ts..." && \
    deno cache src/index.ts && \
    echo "✓ index.ts缓存完成" && \
    echo "2. 缓存test.ts..." && \
    deno cache src/test.ts && \
    echo "✓ test.ts缓存完成" && \
    echo "3. 缓存外部依赖..." && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts && \
    echo "✓ 外部依赖缓存完成" && \
    echo "=== 所有依赖缓存完成 ==="

# 9. 验证缓存内容
RUN echo "=== 验证缓存 ===" && \
    [ -d "/app/.deno_cache" ] && du -sh /app/.deno_cache || echo "缓存目录未创建" && \
    find /app/.deno_cache -name "*.wasm" -type f 2>/dev/null | head -3 && \
    echo "缓存验证完成"

# 10. 创建用户
RUN groupadd -r appgroup && useradd -r -g appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

# 11. 最终验证
RUN echo "=== 最终环境验证 ===" && \
    whoami && \
    deno --version && \
    echo "环境验证完成"

EXPOSE 3000

# 12. 启动命令
CMD ["deno", "task", "start"]

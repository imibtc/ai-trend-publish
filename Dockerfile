# ========================================
# 多架构构建 Dockerfile (支持 ARM64)
# 适用于: 拾光坞N3 等 ARM64 设备
# ========================================

# 使用 Ubuntu 22.04 作为基础镜像 (支持 ARM64/AMD64)
FROM ubuntu:22.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    git \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 2. 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 3. 安装 Deno (自动适配 ARM64/AMD64)
RUN curl -fsSL https://deno.land/x/install/install.sh | sh

# 4. 设置 Deno 环境变量
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"
ENV DENO_DIR="/app/.deno_cache"

# 5. 验证 Deno 安装
RUN echo "=== 验证环境 ===" && \
    deno --version && \
    uname -m && \
    echo "环境验证完成"

# 6. 设置工作目录
WORKDIR /app

# 7. 复制项目配置文件
COPY deno.json .
COPY drizzle.config.ts .

# 8. 复制项目核心文件
COPY drizzle/ ./drizzle/
COPY src/ ./src/
COPY examples/ ./examples/
COPY scripts/ ./scripts/

# 9. 创建必要的目录
RUN mkdir -p /app/export /app/output /app/logs

# 10. 预缓存 Deno 依赖（修复语法错误）
RUN echo "=== 缓存 Deno 依赖 ===" && \
    deno cache --reload src/index.ts && \
    deno cache --reload src/server.ts && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/zlib.wasm && \
    deno cache --reload https://deno.land/x/imagescript@1.2.17/utils/wasm/jpeg.wasm && \
    deno cache --reload https://deno.land/x/sapling_markdown@v1.0.0/mod.ts && \
    echo "依赖缓存完成"

# 验证WASM文件是否成功缓存
RUN find /root/.deno -name "*.wasm" 2>/dev/null | head -3 && \
    echo "WASM文件缓存验证完成"

# 11. 验证项目结构
RUN echo "=== 验证项目文件 ===" && \
    ls -la && \
    echo "源码文件:" && ls -la src/ && \
    echo "项目验证完成"

# 12. 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 暴露端口
EXPOSE 8000

# 设置启动命令
CMD ["deno", "run", "-A", "src/index.ts"]

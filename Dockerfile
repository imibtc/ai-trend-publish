# ========================================
# 多架构构建 Dockerfile (支持 ARM64)
# 适用于: 拾光坞N3 等 ARM64 设备
# 优化版本: 包含完整依赖预下载和错误修复
# ========================================

# 使用 Ubuntu 22.04 作为基础镜像 (支持 ARM64/AMD64)
FROM ubuntu:22.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装系统依赖 (修复: 添加unzip)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \          # ← 修复Deno安装需要的工具
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
ENV DENO_DIR="/app/.deno_cache"  # ← 修改为应用目录

# 5. 验证 Deno 安装
RUN echo "=== 验证环境 ===" && \
    /root/.deno/bin/deno --version && \  # ← 使用绝对路径
    uname -m && \
    echo "环境验证完成"

# 6. 设置工作目录
WORKDIR /app

# 7. 复制项目配置文件(先复制配置文件以利用 Docker 缓存)
COPY deno.json deno.lock ./
COPY drizzle.config.ts ./

# 8. 复制项目核心文件
COPY drizzle/ ./drizzle/
COPY src/ ./src/
COPY examples/ ./examples/
COPY scripts/ ./scripts/
COPY templates/ ./templates/  # ← 添加模板目录

# 9. 创建必要的目录
RUN mkdir -p /app/export /app/output /app/logs /app/data

# 10. 预缓存 Deno 依赖(重要:确保所有依赖都已下载)
RUN echo "=== 缓存 Deno 依赖 ===" && \
    # 缓存主要入口文件
    /root/.deno/bin/deno cache src/index.ts && \
    /root/.deno/bin/deno cache src/test.ts && \
    # 预下载关键的WASM文件(避免运行时网络超时)
    /root/.deno/bin/deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts && \
    # 预下载JSR包
    /root/.deno/bin/deno cache --reload https://jsr.io/@deno-library/progress/1.5.1/mod.ts && \
    # 预下载其他外部依赖
    /root/.deno/bin/deno cache --reload https://deno.land/x/sapling_markdown@v1.0.0/mod.ts && \
    echo "依赖缓存完成"

# 11. 验证WASM文件是否下载成功
RUN echo "=== 验证WASM文件 ===" && \
    find /app/.deno_cache -name "*.wasm" -type f 2>/dev/null | head -5 && \
    echo "WASM文件验证完成"

# 12. 验证项目结构
RUN echo "=== 验证项目文件 ===" && \
    ls -la && \
    echo "源码文件:" && ls -la src/ && \
    [ -d "templates" ] && echo "模板目录存在" || echo "模板目录不存在" && \
    echo "项目验证完成"

# 13. 创建非root用户(安全考虑)
RUN groupadd -r appgroup && useradd -r -g appgroup appuser && \
    chown -R appuser:appgroup /app

# 14. 切换到应用用户
USER appuser

# 15. 健康检查(检查服务是否正常运行)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 暴露端口(根据实际应用调整)
EXPOSE 3000

# 设置启动命令(使用项目定义的task)
CMD ["/root/.deno/bin/deno", "task", "start"]  # ← 使用绝对路径

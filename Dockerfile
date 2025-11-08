# ========================================
# 多架构构建 Dockerfile (支持 ARM64)
# 适用于: 拾光坞N3 等 ARM64 设备
# ========================================

# 阶段1: 基础环境 (Ubuntu 22.04 支持多架构)
FROM ubuntu:22.04 AS base

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    python3 \
    python3-pip \
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

# 5. 验证 Deno 安装
RUN echo "=== 验证环境 ===" && \
    python3 --version && \
    deno --version && \
    uname -m && \
    echo "环境验证完成"

WORKDIR /app

# 6. 安装 Python 依赖
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 阶段2: 应用构建
FROM base AS app

# 7. 复制项目文件
COPY config/ ./config/
COPY src/ ./src/
COPY run.py .
COPY test_local.py .
COPY entrypoint.sh .

# 8. 创建必要的目录
RUN mkdir -p /app/export /app/output /app/logs

# 9. 设置执行权限
RUN chmod +x entrypoint.sh

# 10. 设置 Deno 缓存目录
ENV DENO_DIR=/app/.deno_cache

# 11. 验证项目结构
RUN echo "=== 验证项目文件 ===" && \
    ls -la && \
    echo "配置文件:" && ls -la config/ && \
    echo "源码文件:" && ls -la src/ && \
    echo "项目验证完成"

# 12. 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python3 -c "import sys; sys.exit(0)"

# 暴露端口
EXPOSE 8000

# 设置启动命令
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]

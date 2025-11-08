FROM ubuntu:22.04

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y curl

# 2. 安装Deno并设置权限
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
RUN chmod +x /root/.deno/bin/deno

# 3. 设置环境变量
ENV DENO_INSTALL="/root/.deno"
ENV PATH="/root/.deno/bin:${PATH}"

# 4. 验证安装
RUN /root/.deno/bin/deno --version

WORKDIR /app

# 5. 复制项目文件
COPY . .

# 6. 设置缓存目录
ENV DENO_DIR=/app/.deno_cache

# 7. 预下载所有依赖（关键步骤）
RUN echo "开始预下载所有依赖..." && \
    # 缓存主要入口文件（触发依赖下载）
    /root/.deno/bin/deno cache src/index.ts && \
    /root/.deno/bin/deno cache src/test.ts && \
    # 强制预下载关键的外部WASM依赖
    /root/.deno/bin/deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts && \
    # 预下载JSR包
    /root/.deno/bin/deno cache --reload https://jsr.io/@deno-library/progress/1.5.1/mod.ts && \
    # 预下载其他外部依赖
    /root/.deno/bin/deno cache --reload https://deno.land/x/sapling_markdown@v1.0.0/mod.ts && \
    echo "所有依赖预下载完成！"

# 8. 验证依赖是否完整下载
RUN echo "验证依赖缓存..." && \
    find /app/.deno_cache -name "*.wasm" | head -3 && \
    find /app/.deno_cache -name "*.ts" | head -5 && \
    echo "依赖验证完成"

# 9. 创建用户
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 3000

# 10. 启动命令
CMD ["/root/.deno/bin/deno", "task", "start"]

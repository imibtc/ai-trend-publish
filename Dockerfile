FROM --platform=$BUILDPLATFORM denoland/deno:alpine-2.0.0

WORKDIR /app

# 1. 复制基础配置文件
COPY deno.json deno.lock ./

# 2. 复制源码目录
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY drizzle/ ./drizzle/

# 3. 检查并复制templates目录（如果存在）
RUN if [ -d "templates" ]; then cp -r templates/ ./templates/; else echo "templates目录不存在，跳过"; fi

# 4. 预缓存依赖
RUN deno cache deps.ts && \
    deno cache src/index.ts && \
    deno cache src/test.ts

# 5. 创建非root用户
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000
CMD ["deno", "task", "start"]

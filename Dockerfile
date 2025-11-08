FROM --platform=$BUILDPLATFORM denoland/deno:alpine-2.0.0

WORKDIR /app

# 1. 复制基础配置文件
COPY deno.json deno.lock ./

# 2. 复制源码（确保目录存在）
COPY src/ ./src/
COPY scripts/ ./scripts/


# 3. 预缓存依赖
RUN deno cache src/index.ts && \
    deno cache src/test.ts

# 4. 创建用户和设置
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000
CMD ["deno", "task", "start"]

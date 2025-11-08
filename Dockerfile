# 使用多架构支持的Deno镜像
FROM --platform=$BUILDPLATFORM denoland/deno:alpine-2.0.0

WORKDIR /app

# 复制项目文件（分步复制以利用Docker缓存）
COPY deno.json deno.lock ./
COPY src/ ./src/
COPY templates/ ./templates/
COPY scripts/ ./scripts/

# 预下载所有依赖（构建时完成）
RUN deno cache deps.ts && \
    deno cache src/main.ts && \
    deno cache src/controllers/cron.ts

# 创建非root用户（ARM设备安全要求）
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 暴露端口
EXPOSE 3000

# 启动命令（所有依赖已预下载）
CMD ["deno", "task", "start"]

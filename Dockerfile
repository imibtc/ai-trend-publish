# 使用Ubuntu基础镜像，ARM64兼容性更好
FROM --platform=linux/arm64 ubuntu:22.04

# 安装依赖和Deno
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 安装Deno
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

WORKDIR /app

# 复制项目文件
COPY . .

# 预缓存依赖
RUN deno cache src/index.ts

# 创建非root用户
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 3000
CMD ["deno", "task", "start"]

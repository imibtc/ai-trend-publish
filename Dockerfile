FROM --platform=linux/arm64 ubuntu:22.04

# 安装依赖
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 安装Deno并明确设置PATH
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="${DENO_INSTALL}/bin:${PATH}"

# 验证Deno安装
RUN deno --version

WORKDIR /app
COPY . .
RUN deno cache src/index.ts

EXPOSE 3000
CMD ["deno", "task", "start"]

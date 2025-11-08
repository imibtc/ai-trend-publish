FROM ubuntu:22.04

# 1. 安装系统依赖（包含unzip）
RUN apt-get update && apt-get install -y curl unzip

# 2. 安装Deno
RUN curl -fsSL https://deno.land/x/install/install.sh | sh

# 3. 设置环境变量
ENV DENO_INSTALL="/root/.deno"
ENV PATH="/root/.deno/bin:${PATH}"

# 4. 验证安装
RUN /root/.deno/bin/deno --version

WORKDIR /app

# 5. 复制项目文件
COPY . .

# 6. 预下载所有依赖
RUN /root/.deno/bin/deno cache src/index.ts
RUN /root/.deno/bin/deno cache src/test.ts
RUN /root/.deno/bin/deno cache --reload https://deno.land/x/imagescript@1.2.17/mod.ts

# 7. 创建用户
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 3000
CMD ["/root/.deno/bin/deno", "task", "start"]

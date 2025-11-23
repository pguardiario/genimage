FROM node:20-slim

WORKDIR /app

# 1. Install Build Tools (C++ Compiler)
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    wget \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone stable-diffusion.cpp (The C++ Engine)
# We clone a specific commit to ensure this script works forever
RUN git clone https://github.com/leejet/stable-diffusion.cpp.git
WORKDIR /app/stable-diffusion.cpp

# 3. Build the binary
RUN mkdir build && cd build && cmake .. && cmake --build . --config Release

# 4. Download a Lightweight Model (SD 1.5 Quantized - Only ~2GB file size)
# This model is pre-compressed for CPU usage.
WORKDIR /app/models
RUN wget -O sd-v1-5-q5.gguf https://huggingface.co/leejet/stable-diffusion.cpp-quantized/resolve/main/sd-v1-5-pruned-q5_0.gguf

# 5. Setup Node Server
WORKDIR /app
COPY package.json .
RUN npm install

COPY server.js .

# 6. Run
EXPOSE 8000
CMD ["node", "server.js"]
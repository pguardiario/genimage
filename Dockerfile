FROM node:20-slim

WORKDIR /app

# 1. Install Build Tools
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    wget \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone stable-diffusion.cpp with SUBMODULES
# FIX: Added --recursive so it downloads the 'ggml' folder
RUN git clone --recursive https://github.com/leejet/stable-diffusion.cpp.git
WORKDIR /app/stable-diffusion.cpp

# 3. Build the binary
RUN mkdir build && cd build && cmake .. && cmake --build . --config Release

# 4. Download Model (Using a reliable mirror)
WORKDIR /app/models
# FIX: Switched to second-state mirror which is more reliable for automated downloads
RUN wget -O sd-v1-5-q5.gguf https://huggingface.co/second-state/stable-diffusion-v1-5-GGUF/resolve/main/stable-diffusion-v1-5-pruned-emaonly-Q5_0.gguf

# 5. Setup Node Server
WORKDIR /app
COPY package.json .
RUN npm install

COPY server.js .

# 6. Run
EXPOSE 8000
CMD ["node", "server.js"]
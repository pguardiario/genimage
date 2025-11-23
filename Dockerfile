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

# 4. Download LCM Model (Optimized for 4-step generation)
WORKDIR /app/models
# We use the Q4_K_M quantized version (~2.4GB) which is fast and low RAM
RUN wget -O lcm-dreamshaper-v7-q4.gguf https://huggingface.co/tensorblock/LCM_Dreamshaper_v7-GGUF/resolve/main/LCM_Dreamshaper_v7.Q4_K_M.gguf

# 5. Setup Node Server
WORKDIR /app
COPY package.json .
RUN npm install

COPY server.js .

# 6. Run
EXPOSE 8000
CMD ["node", "server.js"]
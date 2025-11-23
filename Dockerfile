FROM node:20-slim

WORKDIR /app

# 1. Install Build Tools & Curl (Added curl explicitly)
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    curl \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone stable-diffusion.cpp with SUBMODULES
RUN git clone --recursive https://github.com/leejet/stable-diffusion.cpp.git
WORKDIR /app/stable-diffusion.cpp

# 3. Build the binary
RUN mkdir build && cd build && cmake .. && cmake --build . --config Release

# 4. Download LCM Model (Using CURL with Browser Headers to bypass 401 error)
WORKDIR /app/models
RUN curl -L -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o lcm-dreamshaper-v7-q4.gguf https://huggingface.co/tensorblock/LCM_Dreamshaper_v7-GGUF/resolve/main/LCM_Dreamshaper_v7.Q4_K_M.gguf

# 5. Setup Node Server
WORKDIR /app
COPY package.json .
RUN npm install

COPY server.js .

# 6. Run
EXPOSE 8000
CMD ["node", "server.js"]
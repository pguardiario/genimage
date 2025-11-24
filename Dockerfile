FROM node:20-slim

WORKDIR /app

# 1. Install Build Tools
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone stable-diffusion.cpp
RUN git clone --recursive https://github.com/leejet/stable-diffusion.cpp.git
WORKDIR /app/stable-diffusion.cpp

# 3. Build the binary
RUN mkdir build && cd build && cmake .. && cmake --build . --config Release

# 4. Setup Node Server (Note: We skipped the download step!)
WORKDIR /app
COPY package.json .
RUN npm install

COPY server.js .

# 5. Run
EXPOSE 8000
CMD ["node", "server.js"]
FROM python:3.10-slim

# 1. Setup the environment
WORKDIR /app

# 2. Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 3. Clone into a specific subfolder to keep paths clean
RUN git clone https://github.com/rupeshs/fastsdcpu.git fastsdcpu

# 4. Set the working directory TO that folder
WORKDIR /app/fastsdcpu

# 5. CRITICAL: Tell Python that this folder is the root for imports
ENV PYTHONPATH=/app/fastsdcpu

# 6. Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir fastapi uvicorn

# 7. Copy our server script into this folder
COPY server.py .

# 8. Run the server
EXPOSE 8000
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
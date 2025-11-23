FROM python:3.10-slim

WORKDIR /app

# Install system dependencies for OpenCV and Git
RUN apt-get update && apt-get install -y \
    git \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Clone FastSD CPU (Pinning to a specific commit helps stability, but main is usually fine)
RUN git clone https://github.com/rupeshs/fastsdcpu.git .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir fastapi uvicorn

# Copy our custom API server file
COPY server.py .

# Expose the port
EXPOSE 8000

# Run the API server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]


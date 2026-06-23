FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Deno with proper PATH
ENV DENO_INSTALL=/usr/local
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
ENV PATH="${DENO_INSTALL}/bin:${PATH}"

# Verify Deno is in PATH
RUN deno --version && which deno

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir --upgrade yt-dlp yt-dlp-ejs

COPY . .

EXPOSE 10000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "10000"]

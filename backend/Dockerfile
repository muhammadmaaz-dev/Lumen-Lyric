FROM python:3.11-slim

# Install ffmpeg, curl (for deno install), and unzip
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Deno (required for yt-dlp YouTube extraction)
RUN curl -fsSL https://deno.land/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies with no cache to get latest versions
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Force upgrade yt-dlp to absolute latest
RUN pip install --no-cache-dir --upgrade yt-dlp

COPY . .

EXPOSE 10000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "10000"]

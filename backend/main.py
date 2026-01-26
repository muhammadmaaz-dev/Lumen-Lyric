from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yt_dlp
import os
import uuid
import shutil
import logging
from pathlib import Path

app = FastAPI(title="YT-DLP MP3 API")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DOWNLOAD_DIR = os.getenv("DOWNLOAD_DIR", "/tmp/downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)


class DownloadRequest(BaseModel):
    url: str
    include_metadata: bool = True


class MetadataRequest(BaseModel):
    url: str


def get_ydl_opts():
    return {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'source_address': '0.0.0.0',
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-us,en;q=0.5',
        },
        'retries': 3,
        'socket_timeout': 30,
        'extractor_args': {
            'youtube': {
                'player_client': ['android', 'web'],
            }
        },
    }


@app.get("/")
def root():
    return {"status": "YT-DLP MP3 API is running"}


@app.get("/health")
def health():
    return {
        "status": "running",
        "yt_dlp_version": yt_dlp.version.__version__,
    }


@app.post("/metadata")
def get_metadata(request: MetadataRequest):
    """Extract metadata without downloading"""
    ydl_opts = get_ydl_opts()

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=False)

            return {
                "title": info.get("title"),
                "artist": info.get("artist") or info.get("uploader") or info.get("channel"),
                "album": info.get("album"),
                "duration": info.get("duration"),
                "thumbnail": info.get("thumbnail"),
                "thumbnails": info.get("thumbnails", []),
                "description": info.get("description"),
                "upload_date": info.get("upload_date"),
                "view_count": info.get("view_count"),
                "like_count": info.get("like_count"),
                "channel": info.get("channel"),
                "channel_url": info.get("channel_url"),
                "tags": info.get("tags", []),
                "categories": info.get("categories", []),
            }
    except Exception as e:
        logger.error(f"Metadata extraction failed: {str(e)}")
        raise HTTPException(status_code=400, detail="Failed to extract metadata from the provided URL")


@app.post("/download")
def download_audio(request: DownloadRequest):
    """Download audio as MP3 with embedded metadata"""

    download_id = str(uuid.uuid4())
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    os.makedirs(download_path, exist_ok=True)

    # Use a safe filename to prevent path traversal via video title
    safe_filename = "audio"
    output_template = os.path.join(download_path, f"{safe_filename}.%(ext)s")

    ydl_opts = get_ydl_opts()
    ydl_opts.update({
        'format': 'bestaudio/best',
        'outtmpl': output_template,
        'postprocessors': [
            {
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            },
        ],
    })

    if request.include_metadata:
        ydl_opts['postprocessors'].extend([
            {
                'key': 'FFmpegMetadata',
                'add_metadata': True,
            },
            {
                'key': 'EmbedThumbnail',
            },
        ])
        ydl_opts['writethumbnail'] = True

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=True)

            # Find the MP3 file with safe filename
            mp3_file = os.path.join(download_path, f"{safe_filename}.mp3")
            if not os.path.exists(mp3_file):
                # Fallback: find any MP3 file in the directory
                mp3_files = [f for f in os.listdir(download_path) if f.endswith('.mp3')]
                if mp3_files:
                    mp3_file = os.path.join(download_path, mp3_files[0])
                else:
                    raise HTTPException(status_code=500, detail="MP3 file not created")

            return {
                "success": True,
                "download_id": download_id,
                "filename": os.path.basename(mp3_file),
                "metadata": {
                    "title": info.get("title"),
                    "artist": info.get("artist") or info.get("uploader"),
                    "album": info.get("album"),
                    "duration": info.get("duration"),
                    "thumbnail": info.get("thumbnail"),
                }
            }
    except Exception as e:
        logger.error(f"Download failed: {str(e)}")
        shutil.rmtree(download_path, ignore_errors=True)
        raise HTTPException(status_code=400, detail="Failed to download and convert the video")


@app.get("/file/{download_id}/{filename}")
def get_file(download_id: str, filename: str):
    """Serve the downloaded MP3 file"""
    # Validate download_id and filename to prevent path traversal
    if ".." in download_id or "/" in download_id or "\\" in download_id:
        raise HTTPException(status_code=400, detail="Invalid download ID")
    if ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Invalid filename")
    
    file_path = os.path.join(DOWNLOAD_DIR, download_id, filename)
    
    # Ensure the resolved path is still within DOWNLOAD_DIR
    try:
        real_path = Path(file_path).resolve()
        real_download_dir = Path(DOWNLOAD_DIR).resolve()
        if not str(real_path).startswith(str(real_download_dir)):
            raise HTTPException(status_code=400, detail="Invalid file path")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid file path")

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(
        file_path,
        media_type="audio/mpeg",
        filename=filename
    )


@app.delete("/cleanup/{download_id}")
def cleanup(download_id: str):
    """Clean up downloaded files"""
    # Validate download_id to prevent path traversal
    if ".." in download_id or "/" in download_id or "\\" in download_id:
        raise HTTPException(status_code=400, detail="Invalid download ID")
    
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    
    # Ensure the resolved path is still within DOWNLOAD_DIR
    try:
        real_path = Path(download_path).resolve()
        real_download_dir = Path(DOWNLOAD_DIR).resolve()
        if not str(real_path).startswith(str(real_download_dir)):
            raise HTTPException(status_code=400, detail="Invalid download ID")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid download ID")
    
    if os.path.exists(download_path):
        shutil.rmtree(download_path)
        return {"success": True}
    return {"success": False, "detail": "Not found"}

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yt_dlp
import os
import uuid
import shutil
import logging
import subprocess

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="YT-DLP MP3 API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOWNLOAD_DIR = "/tmp/downloads"
COOKIES_FILE = os.path.join(BASE_DIR, "cookies.txt")

os.makedirs(DOWNLOAD_DIR, exist_ok=True)


class DownloadRequest(BaseModel):
    url: str
    include_metadata: bool = True


class MetadataRequest(BaseModel):
    url: str


def check_deno():
    """Check if Deno is available"""
    try:
        result = subprocess.run(['deno', '--version'], capture_output=True, text=True)
        return result.returncode == 0, result.stdout.split('\n')[0] if result.returncode == 0 else None
    except:
        return False, None


def get_ydl_opts():
    """Get yt-dlp options"""
    opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'geo_bypass': True,
        'nocheckcertificate': True,
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
        },
    }
    
    if os.path.exists(COOKIES_FILE):
        opts['cookiefile'] = COOKIES_FILE
        logger.info(f"✅ Using cookies from: {COOKIES_FILE}")
    
    return opts


@app.get("/")
def root():
    deno_ok, deno_ver = check_deno()
    return {
        "status": "YT-DLP MP3 API is running",
        "deno_installed": deno_ok,
        "deno_version": deno_ver,
        "cookies_exists": os.path.exists(COOKIES_FILE),
    }


@app.get("/health")
def health():
    deno_ok, deno_ver = check_deno()
    return {
        "status": "running",
        "yt_dlp_version": yt_dlp.version.__version__,
        "deno_installed": deno_ok,
        "deno_version": deno_ver,
        "cookies_file_exists": os.path.exists(COOKIES_FILE),
    }


@app.post("/metadata")
def get_metadata(request: MetadataRequest):
    """Extract video metadata"""
    logger.info(f"📡 Fetching metadata for: {request.url}")
    
    try:
        ydl_opts = get_ydl_opts()
        ydl_opts['skip_download'] = True
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=False)
        
        if info is None:
            raise HTTPException(status_code=400, detail="Could not extract video info")

        thumbnail = info.get("thumbnail")
        if not thumbnail and info.get("thumbnails"):
            thumbnails = info.get("thumbnails", [])
            if thumbnails:
                thumbnail = thumbnails[-1].get("url") if isinstance(thumbnails[-1], dict) else thumbnails[-1]

        logger.info(f"✅ Metadata extracted: {info.get('title')}")

        return {
            "title": info.get("title", "Unknown"),
            "artist": info.get("artist") or info.get("uploader") or info.get("channel") or "Unknown",
            "album": info.get("album"),
            "duration": info.get("duration", 0),
            "thumbnail": thumbnail,
            "description": (info.get("description") or "")[:500],
            "view_count": info.get("view_count", 0),
            "channel": info.get("channel") or info.get("uploader"),
            "video_id": info.get("id"),
        }
    except yt_dlp.utils.DownloadError as e:
        logger.error(f"❌ yt-dlp error: {str(e)[:200]}")
        raise HTTPException(status_code=400, detail=str(e)[:200])
    except Exception as e:
        logger.error(f"❌ Error: {str(e)[:200]}")
        raise HTTPException(status_code=400, detail=str(e)[:200])


@app.post("/download")
def download_audio(request: DownloadRequest):
    """Download audio as MP3"""
    logger.info(f"📥 Starting download for: {request.url}")

    download_id = str(uuid.uuid4())
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    os.makedirs(download_path, exist_ok=True)

    try:
        output_template = os.path.join(download_path, "%(title)s.%(ext)s")

        ydl_opts = get_ydl_opts()
        ydl_opts.update({
            'format': 'bestaudio[ext=m4a]/bestaudio/best',
            'outtmpl': output_template,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
        })

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=True)

        mp3_file = None
        for file in os.listdir(download_path):
            if file.endswith('.mp3'):
                mp3_file = os.path.join(download_path, file)
                break

        if not mp3_file:
            raise HTTPException(status_code=500, detail="MP3 not created")

        logger.info(f"✅ Download complete: {os.path.basename(mp3_file)}")

        return {
            "success": True,
            "download_id": download_id,
            "filename": os.path.basename(mp3_file),
            "metadata": {
                "title": info.get("title"),
                "artist": info.get("artist") or info.get("uploader"),
                "duration": info.get("duration", 0),
            }
        }
    except Exception as e:
        shutil.rmtree(download_path, ignore_errors=True)
        logger.error(f"❌ Download error: {str(e)[:200]}")
        raise HTTPException(status_code=400, detail=str(e)[:200])


@app.get("/file/{download_id}/{filename}")
def get_file(download_id: str, filename: str):
    file_path = os.path.join(DOWNLOAD_DIR, download_id, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path, media_type="audio/mpeg", filename=filename)


@app.delete("/cleanup/{download_id}")
def cleanup(download_id: str):
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    if os.path.exists(download_path):
        shutil.rmtree(download_path)
        return {"success": True}
    return {"success": False}

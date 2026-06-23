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


def check_js_runtime():
    """Check for Node.js or Deno"""
    runtimes = []
    
    # Check Node.js
    try:
        result = subprocess.run(['node', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            runtimes.append({"name": "node", "version": result.stdout.strip()})
    except Exception:
        pass
    
    # Check Deno
    try:
        result = subprocess.run(['deno', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            runtimes.append({"name": "deno", "version": result.stdout.split('\n')[0]})
    except Exception:
        pass
    
    return runtimes


def get_ydl_opts():
    """Get yt-dlp options"""
    opts = {
        'quiet': False,
        'no_warnings': False,
        'extract_flat': False,
        'geo_bypass': True,
        'nocheckcertificate': True,
        # ✅ CRITICAL FIX 1: Tell yt-dlp to use Node.js instead of Deno
        'js_runtimes': ['node'], 
    }

    if os.path.exists(COOKIES_FILE):
        opts['cookiefile'] = COOKIES_FILE
        logger.info(f"Using cookies from: {COOKIES_FILE}")

    return opts


@app.get("/")
def root():
    runtimes = check_js_runtime()
    return {
        "status": "YT-DLP MP3 API is running",
        "js_runtimes": runtimes,
        "js_runtime_available": len(runtimes) > 0,
        "cookies_exists": os.path.exists(COOKIES_FILE),
        "yt_dlp_version": yt_dlp.version.__version__,
    }


@app.get("/health")
def health():
    runtimes = check_js_runtime()
    return {
        "status": "running" if runtimes else "degraded",
        "yt_dlp_version": yt_dlp.version.__version__,
        "js_runtimes": runtimes,
        "js_runtime_available": len(runtimes) > 0,
        "cookies_file_exists": os.path.exists(COOKIES_FILE),
    }


@app.post("/metadata")
def get_metadata(request: dict):
    """Extract video metadata"""
    url = request.get("url")
    logger.info(f"📡 Fetching metadata for: {url}")
    
    try:
        ydl_opts = get_ydl_opts()
        ydl_opts['skip_download'] = True
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
        
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
def download_audio(request: dict):
    """Download audio as MP3"""
    url = request.get("url")
    include_metadata = request.get("include_metadata", True)
    logger.info(f"📥 Starting download for: {url}")

    download_id = str(uuid.uuid4())
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    os.makedirs(download_path, exist_ok=True)

    try:
        output_template = os.path.join(download_path, "audio.%(ext)s")

        ydl_opts = get_ydl_opts()
        ydl_opts.update({
            'format': 'bestaudio/best',
            'outtmpl': output_template,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
            'ignoreerrors': False,
            'no_warnings': False,
            'age_limit': None,
            'retries': 3,
            'fragment_retries': 3,
        })

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)

        mp3_file = None
        for file in os.listdir(download_path):
            if file.endswith('.mp3'):
                mp3_file = os.path.join(download_path, file)
                break

        if not mp3_file:
            raise HTTPException(status_code=500, detail="MP3 not created - conversion failed")

        if os.path.getsize(mp3_file) == 0:
            shutil.rmtree(download_path, ignore_errors=True)
            raise HTTPException(status_code=500, detail="Download failed - video may be unavailable or age-restricted")

        logger.info(f"✅ Download complete: {os.path.basename(mp3_file)} ({os.path.getsize(mp3_file)} bytes)")

        response = {
            "success": True,
            "download_id": download_id,
            "filename": os.path.basename(mp3_file),
        }

        if include_metadata:
            response["metadata"] = {
                "title": info.get("title"),
                "artist": info.get("artist") or info.get("uploader"),
                "duration": info.get("duration", 0),
                "thumbnail": info.get("thumbnail")
            }

        return response
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

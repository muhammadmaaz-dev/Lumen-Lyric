from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yt_dlp
import os
import uuid
import shutil
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="YT-DLP MP3 API")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOWNLOAD_DIR = "/tmp/downloads"
COOKIES_FILE = os.path.join(BASE_DIR, "cookies.txt")

os.makedirs(DOWNLOAD_DIR, exist_ok=True)


class DownloadRequest(BaseModel):
    url: str
    include_metadata: bool = True


class MetadataRequest(BaseModel):
    url: str


def get_ydl_opts():
    """Enhanced yt-dlp options with cookies support"""
    opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'geo_bypass': True,
        'nocheckcertificate': True,
        # Force IPv4
        'source_address': '0.0.0.0',
        # Browser-like headers
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Sec-Ch-Ua': '"Chromium";v="123", "Google Chrome";v="123"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"Windows"',
        },
        'retries': 10,
        'fragment_retries': 10,
        'socket_timeout': 60,
        'extractor_args': {
            'youtube': {
                'player_client': ['ios', 'android', 'web'],
                'player_skip': ['webpage', 'configs'],
            }
        },
        'youtube_include_dash_manifest': False,
        'youtube_include_hls_manifest': False,
    }
    
    # ✅ Add cookies if file exists
    if os.path.exists(COOKIES_FILE):
        opts['cookiefile'] = COOKIES_FILE
        logger.info(f"✅ Using cookies from: {COOKIES_FILE}")
    else:
        logger.warning(f"⚠️ Cookies file not found at: {COOKIES_FILE}")
    
    return opts


@app.get("/")
def root():
    cookies_status = "found" if os.path.exists(COOKIES_FILE) else "NOT FOUND"
    return {
        "status": "YT-DLP MP3 API is running",
        "cookies": cookies_status
    }


@app.get("/health")
def health():
    return {
        "status": "running",
        "yt_dlp_version": yt_dlp.version.__version__,
        "cookies_file_exists": os.path.exists(COOKIES_FILE),
        "cookies_path": COOKIES_FILE,
    }


@app.post("/metadata")
def get_metadata(request: MetadataRequest):
    """Extract metadata without downloading"""
    logger.info(f"📡 Fetching metadata for: {request.url}")
    
    ydl_opts = get_ydl_opts()
    ydl_opts['skip_download'] = True

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=False)
            
            if info is None:
                raise HTTPException(status_code=400, detail="Could not extract video information")

            logger.info(f"✅ Metadata extracted: {info.get('title')}")

            # Get best thumbnail
            thumbnail = info.get("thumbnail")
            if not thumbnail and info.get("thumbnails"):
                thumbnails = info.get("thumbnails", [])
                if thumbnails:
                    thumbnail = thumbnails[-1].get("url")

            return {
                "title": info.get("title", "Unknown Title"),
                "artist": info.get("artist") or info.get("uploader") or info.get("channel") or "Unknown Artist",
                "album": info.get("album"),
                "duration": info.get("duration", 0),
                "thumbnail": thumbnail,
                "thumbnails": info.get("thumbnails", []),
                "description": (info.get("description") or "")[:500],  # Limit description length
                "upload_date": info.get("upload_date"),
                "view_count": info.get("view_count", 0),
                "like_count": info.get("like_count", 0),
                "channel": info.get("channel") or info.get("uploader"),
                "channel_url": info.get("channel_url") or info.get("uploader_url"),
                "tags": (info.get("tags") or [])[:10],  # Limit tags
                "categories": info.get("categories", []),
                "video_id": info.get("id"),
            }
    except yt_dlp.utils.DownloadError as e:
        error_str = str(e)
        logger.error(f"❌ yt-dlp error: {error_str}")
        
        if "Sign in to confirm" in error_str or "bot" in error_str.lower():
            raise HTTPException(
                status_code=403, 
                detail="YouTube requires authentication. Please check that cookies.txt is valid and not expired."
            )
        elif "Video unavailable" in error_str:
            raise HTTPException(status_code=404, detail="Video is unavailable or private")
        elif "age" in error_str.lower():
            raise HTTPException(status_code=403, detail="Age-restricted video")
        else:
            raise HTTPException(status_code=400, detail=f"Error: {error_str[:200]}")
    except Exception as e:
        logger.error(f"❌ Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)[:200]}")


@app.post("/download")
def download_audio(request: DownloadRequest):
    """Download audio as MP3 with embedded metadata"""
    logger.info(f"📥 Starting download for: {request.url}")

    download_id = str(uuid.uuid4())
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    os.makedirs(download_path, exist_ok=True)

    output_template = os.path.join(download_path, "%(title)s.%(ext)s")

    ydl_opts = get_ydl_opts()
    ydl_opts.update({
        'format': 'bestaudio[ext=m4a]/bestaudio/best',
        'outtmpl': output_template,
        'postprocessors': [
            {
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            },
        ],
        'prefer_ffmpeg': True,
        'keepvideo': False,
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

            if info is None:
                raise HTTPException(status_code=400, detail="Could not extract video information")

            # Find the downloaded MP3 file
            mp3_file = None
            for file in os.listdir(download_path):
                if file.endswith('.mp3'):
                    mp3_file = os.path.join(download_path, file)
                    break

            if not mp3_file:
                files = os.listdir(download_path)
                logger.error(f"❌ MP3 not found. Files in folder: {files}")
                raise HTTPException(
                    status_code=500, 
                    detail=f"MP3 file not created. Files found: {files}"
                )

            logger.info(f"✅ Download complete: {os.path.basename(mp3_file)}")

            return {
                "success": True,
                "download_id": download_id,
                "filename": os.path.basename(mp3_file),
                "metadata": {
                    "title": info.get("title", "Unknown"),
                    "artist": info.get("artist") or info.get("uploader") or info.get("channel"),
                    "album": info.get("album"),
                    "duration": info.get("duration", 0),
                    "thumbnail": info.get("thumbnail"),
                }
            }
    except yt_dlp.utils.DownloadError as e:
        shutil.rmtree(download_path, ignore_errors=True)
        error_str = str(e)
        logger.error(f"❌ Download error: {error_str}")
        
        if "Sign in to confirm" in error_str or "bot" in error_str.lower():
            raise HTTPException(
                status_code=403, 
                detail="YouTube requires authentication. Please update cookies.txt"
            )
        raise HTTPException(status_code=400, detail=f"Download error: {error_str[:200]}")
    except HTTPException:
        shutil.rmtree(download_path, ignore_errors=True)
        raise
    except Exception as e:
        shutil.rmtree(download_path, ignore_errors=True)
        logger.error(f"❌ Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error: {str(e)[:200]}")


@app.get("/file/{download_id}/{filename}")
def get_file(download_id: str, filename: str):
    """Serve the downloaded MP3 file"""
    file_path = os.path.join(DOWNLOAD_DIR, download_id, filename)

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found or expired")

    logger.info(f"📤 Serving file: {filename}")

    return FileResponse(
        file_path,
        media_type="audio/mpeg",
        filename=filename
    )


@app.delete("/cleanup/{download_id}")
def cleanup(download_id: str):
    """Clean up downloaded files"""
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    if os.path.exists(download_path):
        shutil.rmtree(download_path)
        logger.info(f"🧹 Cleaned up: {download_id}")
        return {"success": True}
    return {"success": False, "detail": "Not found"}


# Startup message
@app.on_event("startup")
async def startup_event():
    logger.info("🚀 YT-DLP MP3 API starting...")
    logger.info(f"📁 Download directory: {DOWNLOAD_DIR}")
    logger.info(f"🍪 Cookies file: {COOKIES_FILE}")
    if os.path.exists(COOKIES_FILE):
        logger.info("✅ Cookies file found!")
    else:
        logger.warning("⚠️ Cookies file NOT found - YouTube may block requests!")

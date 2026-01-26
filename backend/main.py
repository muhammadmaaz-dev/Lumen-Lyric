from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yt_dlp
import os
import uuid
import shutil
import logging
import json

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
    """Enhanced yt-dlp options with multiple bypass methods"""
    opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'geo_bypass': True,
        'nocheckcertificate': True,
        'source_address': '0.0.0.0',
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Sec-Ch-Ua': '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"Windows"',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Upgrade-Insecure-Requests': '1',
        },
        'retries': 10,
        'fragment_retries': 10,
        'socket_timeout': 60,
        # Try different player clients
        'extractor_args': {
            'youtube': {
                'player_client': ['tv', 'tv_embedded', 'mediaconnect'],
            }
        },
    }
    
    # Add cookies if file exists
    if os.path.exists(COOKIES_FILE):
        opts['cookiefile'] = COOKIES_FILE
        logger.info(f"✅ Using cookies from: {COOKIES_FILE}")
    
    return opts


def try_extract_info(url: str, download: bool = False):
    """Try multiple methods to extract video info"""
    
    # Method 1: Try with TV client (most reliable for servers)
    clients_to_try = [
        ['tv', 'tv_embedded'],
        ['mediaconnect'],
        ['android', 'ios'],
        ['web'],
    ]
    
    last_error = None
    
    for clients in clients_to_try:
        try:
            opts = get_ydl_opts()
            opts['extractor_args'] = {
                'youtube': {
                    'player_client': clients,
                }
            }
            if not download:
                opts['skip_download'] = True
            
            logger.info(f"🔄 Trying with player clients: {clients}")
            
            with yt_dlp.YoutubeDL(opts) as ydl:
                info = ydl.extract_info(url, download=download)
                if info:
                    logger.info(f"✅ Success with clients: {clients}")
                    return info
        except Exception as e:
            last_error = str(e)
            logger.warning(f"⚠️ Failed with {clients}: {str(e)[:100]}")
            continue
    
    # Method 2: Try with Piped/Invidious as fallback
    try:
        video_id = extract_video_id(url)
        if video_id:
            logger.info(f"🔄 Trying Piped API fallback for: {video_id}")
            return fetch_from_piped(video_id)
    except Exception as e:
        logger.warning(f"⚠️ Piped fallback failed: {str(e)[:100]}")
    
    raise Exception(last_error or "All extraction methods failed")


def extract_video_id(url: str) -> str:
    """Extract video ID from YouTube URL"""
    import re
    patterns = [
        r'(?:v=|/)([0-9A-Za-z_-]{11}).*',
        r'(?:youtu\.be/)([0-9A-Za-z_-]{11})',
        r'(?:shorts/)([0-9A-Za-z_-]{11})',
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def fetch_from_piped(video_id: str) -> dict:
    """Fetch video info from Piped API (YouTube frontend)"""
    import urllib.request
    
    # List of Piped instances to try
    piped_instances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.adminforge.de',
        'https://api.piped.yt',
    ]
    
    for instance in piped_instances:
        try:
            api_url = f"{instance}/streams/{video_id}"
            req = urllib.request.Request(api_url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0.0.0'
            })
            with urllib.request.urlopen(req, timeout=15) as response:
                data = json.loads(response.read().decode())
                
                if data.get('title'):
                    logger.info(f"✅ Got info from Piped: {instance}")
                    return {
                        'title': data.get('title', 'Unknown'),
                        'uploader': data.get('uploader', 'Unknown'),
                        'channel': data.get('uploader', 'Unknown'),
                        'duration': data.get('duration', 0),
                        'thumbnail': data.get('thumbnailUrl'),
                        'thumbnails': [{'url': data.get('thumbnailUrl')}] if data.get('thumbnailUrl') else [],
                        'description': data.get('description', ''),
                        'view_count': data.get('views', 0),
                        'like_count': data.get('likes', 0),
                        'id': video_id,
                        '_piped_source': instance,
                        'audioStreams': data.get('audioStreams', []),
                    }
        except Exception as e:
            logger.warning(f"⚠️ Piped instance {instance} failed: {str(e)[:50]}")
            continue
    
    raise Exception("All Piped instances failed")


@app.get("/")
def root():
    cookies_status = "found" if os.path.exists(COOKIES_FILE) else "NOT FOUND"
    return {
        "status": "YT-DLP MP3 API is running",
        "cookies": cookies_status,
        "version": "2.0-with-fallback"
    }


@app.get("/health")
def health():
    return {
        "status": "running",
        "yt_dlp_version": yt_dlp.version.__version__,
        "cookies_file_exists": os.path.exists(COOKIES_FILE),
        "cookies_path": COOKIES_FILE,
        "fallback_enabled": True,
    }


@app.post("/metadata")
def get_metadata(request: MetadataRequest):
    """Extract metadata with multiple fallback methods"""
    logger.info(f"📡 Fetching metadata for: {request.url}")
    
    try:
        info = try_extract_info(request.url, download=False)
        
        if info is None:
            raise HTTPException(status_code=400, detail="Could not extract video information")

        # Get best thumbnail
        thumbnail = info.get("thumbnail")
        if not thumbnail and info.get("thumbnails"):
            thumbnails = info.get("thumbnails", [])
            if thumbnails:
                thumbnail = thumbnails[-1].get("url") if isinstance(thumbnails[-1], dict) else thumbnails[-1]

        logger.info(f"✅ Metadata extracted: {info.get('title')}")

        return {
            "title": info.get("title", "Unknown Title"),
            "artist": info.get("artist") or info.get("uploader") or info.get("channel") or "Unknown Artist",
            "album": info.get("album"),
            "duration": info.get("duration", 0),
            "thumbnail": thumbnail,
            "thumbnails": info.get("thumbnails", []),
            "description": (info.get("description") or "")[:500],
            "upload_date": info.get("upload_date"),
            "view_count": info.get("view_count", 0),
            "like_count": info.get("like_count", 0),
            "channel": info.get("channel") or info.get("uploader"),
            "channel_url": info.get("channel_url") or info.get("uploader_url"),
            "tags": (info.get("tags") or [])[:10],
            "categories": info.get("categories", []),
            "video_id": info.get("id"),
            "source": "piped" if info.get("_piped_source") else "youtube",
        }
    except yt_dlp.utils.DownloadError as e:
        error_str = str(e)
        logger.error(f"❌ yt-dlp error: {error_str[:200]}")
        raise HTTPException(status_code=400, detail=f"Error: {error_str[:200]}")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error: {str(e)[:200]}")
        raise HTTPException(status_code=400, detail=f"Error: {str(e)[:200]}")


@app.post("/download")
def download_audio(request: DownloadRequest):
    """Download audio as MP3"""
    logger.info(f"📥 Starting download for: {request.url}")

    download_id = str(uuid.uuid4())
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    os.makedirs(download_path, exist_ok=True)

    try:
        # First try to get info
        info = try_extract_info(request.url, download=False)
        
        if info is None:
            raise HTTPException(status_code=400, detail="Could not extract video information")
        
        # Check if we got audio streams from Piped
        if info.get('_piped_source') and info.get('audioStreams'):
            # Download using Piped audio stream
            return download_from_piped(info, download_id, download_path)
        
        # Otherwise try yt-dlp download
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

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([request.url])

        # Find the downloaded MP3 file
        mp3_file = None
        for file in os.listdir(download_path):
            if file.endswith('.mp3'):
                mp3_file = os.path.join(download_path, file)
                break

        if not mp3_file:
            files = os.listdir(download_path)
            raise HTTPException(status_code=500, detail=f"MP3 file not created. Files: {files}")

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
    except HTTPException:
        shutil.rmtree(download_path, ignore_errors=True)
        raise
    except Exception as e:
        shutil.rmtree(download_path, ignore_errors=True)
        logger.error(f"❌ Download error: {str(e)[:200]}")
        raise HTTPException(status_code=400, detail=f"Error: {str(e)[:200]}")


def download_from_piped(info: dict, download_id: str, download_path: str):
    """Download audio from Piped stream"""
    import urllib.request
    import subprocess
    
    audio_streams = info.get('audioStreams', [])
    if not audio_streams:
        raise HTTPException(status_code=400, detail="No audio streams available")
    
    # Get best audio stream (highest bitrate)
    best_audio = max(audio_streams, key=lambda x: x.get('bitrate', 0))
    audio_url = best_audio.get('url')
    
    if not audio_url:
        raise HTTPException(status_code=400, detail="No audio URL found")
    
    # Safe filename
    safe_title = "".join(c for c in info.get('title', 'audio') if c.isalnum() or c in ' -_').strip()[:100]
    temp_file = os.path.join(download_path, f"{safe_title}.m4a")
    mp3_file = os.path.join(download_path, f"{safe_title}.mp3")
    
    # Download audio
    logger.info(f"📥 Downloading from Piped: {audio_url[:50]}...")
    req = urllib.request.Request(audio_url, headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0.0.0'
    })
    
    with urllib.request.urlopen(req, timeout=120) as response:
        with open(temp_file, 'wb') as f:
            f.write(response.read())
    
    # Convert to MP3 using ffmpeg
    logger.info("🔄 Converting to MP3...")
    subprocess.run([
        'ffmpeg', '-i', temp_file, '-vn', '-ab', '192k', '-ar', '44100', '-y', mp3_file
    ], capture_output=True, check=True)
    
    # Clean up temp file
    os.remove(temp_file)
    
    logger.info(f"✅ Piped download complete: {os.path.basename(mp3_file)}")
    
    return {
        "success": True,
        "download_id": download_id,
        "filename": os.path.basename(mp3_file),
        "source": "piped",
        "metadata": {
            "title": info.get("title", "Unknown"),
            "artist": info.get("uploader", "Unknown"),
            "duration": info.get("duration", 0),
            "thumbnail": info.get("thumbnail"),
        }
    }


@app.get("/file/{download_id}/{filename}")
def get_file(download_id: str, filename: str):
    """Serve the downloaded MP3 file"""
    file_path = os.path.join(DOWNLOAD_DIR, download_id, filename)

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found or expired")

    return FileResponse(file_path, media_type="audio/mpeg", filename=filename)


@app.delete("/cleanup/{download_id}")
def cleanup(download_id: str):
    """Clean up downloaded files"""
    download_path = os.path.join(DOWNLOAD_DIR, download_id)
    if os.path.exists(download_path):
        shutil.rmtree(download_path)
        return {"success": True}
    return {"success": False, "detail": "Not found"}


@app.on_event("startup")
async def startup_event():
    logger.info("🚀 YT-DLP MP3 API v2.0 starting...")
    logger.info("📌 Fallback to Piped API enabled")

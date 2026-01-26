# YT-DLP MP3 API Backend

A FastAPI backend for downloading YouTube videos as MP3 files with embedded metadata.

## Deployment on Render.com

1. Go to [Render.com](https://render.com)
2. Create a new **Web Service**
3. Connect this repository
4. Set **Root Directory** to `backend`
5. Set **Runtime** to `Docker`
6. Choose **Free** instance type
7. Click **Create Web Service**

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/health` | GET | Extended health check |
| `/metadata` | POST | Get video metadata |
| `/download` | POST | Download as MP3 |
| `/file/{id}/{filename}` | GET | Get downloaded file |
| `/cleanup/{id}` | DELETE | Clean up files |

## Example Usage

### Get Metadata
```bash
curl -X POST "https://your-api.onrender.com/metadata" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://youtu.be/VIDEO_ID"}'
```

### Download MP3
```bash
curl -X POST "https://your-api.onrender.com/download" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://youtu.be/VIDEO_ID", "include_metadata": true}'
```

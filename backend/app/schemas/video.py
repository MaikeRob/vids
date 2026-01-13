from pydantic import BaseModel
from typing import Optional

class VideoQuality(BaseModel):
    height: int
    filesize: Optional[int] = 0 # Bytes estimate
    format_id: str

class VideoInfo(BaseModel):
    title: str
    thumbnail: str
    duration: int
    uploader: str
    view_count: int
    webpage_url: str
    qualities: list[VideoQuality] = []
    audio_filesize: Optional[int] = 0 # Bytes estimate for best audio

class DownloadRequest(BaseModel):
    url: str
    format: str = "best"
    quality: Optional[int] = None


class StreamRequest(BaseModel):
    url: str
    mode: str = "video" # 'video' or 'audio'
    quality: Optional[int] = None # Only for video

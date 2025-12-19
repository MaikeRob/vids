from pydantic import BaseModel
from typing import Optional

class VideoInfo(BaseModel):
    title: str
    thumbnail: str
    duration: int
    uploader: str
    view_count: int
    webpage_url: str

class DownloadRequest(BaseModel):
    url: str
    format: str = "best"

class DownloadResponse(BaseModel):
    task_id: str
    status: str
    message: str

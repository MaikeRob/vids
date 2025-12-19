import pytest
from unittest.mock import MagicMock, patch
from app.services.ytdlp_service import YtDlpService
import asyncio

@pytest.mark.asyncio
async def test_get_info():
    mock_info = {
        'title': 'Test Video',
        'thumbnail': 'http://thumb.jpg',
        'duration': 100,
        'uploader': 'Tester',
        'view_count': 1000,
        'webpage_url': 'http://youtube.com/watch?v=123'
    }

    with patch('yt_dlp.YoutubeDL') as mock_ydl:
        instance = mock_ydl.return_value
        instance.__enter__.return_value.extract_info.return_value = mock_info

        info = YtDlpService.get_info("http://youtube.com/watch?v=123")
        assert info['title'] == 'Test Video'

@pytest.mark.asyncio
async def test_download_video_success():
    with patch('yt_dlp.YoutubeDL') as mock_ydl:
        instance = mock_ydl.return_value
        instance.__enter__.return_value = instance
        # Mock download returning None (success)
        instance.download.return_value = None

        # Mock websocket manager
        with patch('app.services.websocket_manager.manager.send_personal_message', new_callable=MagicMock) as mock_send:
             # Retorna future para await
            f = asyncio.Future()
            f.set_result(None)
            mock_send.return_value = f

            result = await YtDlpService.download_video("http://youtube.com/watch?v=123", "client_1")
            assert result is True

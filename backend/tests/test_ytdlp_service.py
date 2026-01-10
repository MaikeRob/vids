import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import os
from app.services.ytdlp_service import YtDlpService
from app.core.config import get_settings
from yt_dlp.networking.impersonate import ImpersonateTarget

# Mock settings
settings = get_settings()

@pytest.fixture
def mock_ydl():
    with patch('yt_dlp.YoutubeDL') as mock:
        yield mock

class TestYtDlpService:

    def test_get_info_success(self, mock_ydl):
        # Setup mock
        instance = mock_ydl.return_value
        instance.__enter__.return_value = instance
        
        # Mock data return
        mock_info = {
            'title': 'Test Video',
            'formats': [
                {'height': 1080, 'ext': 'mp4', 'vcodec': 'avc1'},
                {'height': 720, 'ext': 'mp4', 'vcodec': 'avc1'},
                {'height': None, 'ext': 'm4a', 'vcodec': 'none'}, # Audio only
                {'height': 0, 'ext': 'mp4', 'vcodec': 'avc1'}, # Invalid
            ]
        }
        instance.extract_info.return_value = mock_info

        # Execute
        result = YtDlpService.get_info("http://test.com")

        # Assert
        assert result['title'] == 'Test Video'
        assert 1080 in result['qualities']
        assert 720 in result['qualities']
        assert len(result['qualities']) == 2
        
        # Verify call
        instance.extract_info.assert_called_with("http://test.com", download=False)
        
        args, _ = mock_ydl.call_args
        opts = args[0]
        assert opts.get('impersonate').client == 'chrome'
        assert isinstance(opts.get('impersonate'), ImpersonateTarget)

    def test_get_info_error(self, mock_ydl):
        instance = mock_ydl.return_value
        instance.__enter__.return_value = instance
        instance.extract_info.side_effect = Exception("Download Error")

        with pytest.raises(Exception):
            YtDlpService.get_info("http://test.com")

    @pytest.mark.asyncio
    async def test_download_video_format_string(self):
        # Test if format string is constructed correctly
        with patch('app.services.ytdlp_service._run_download') as mock_run:
            with patch('app.services.ytdlp_service.manager') as mock_manager:
                mock_manager.send_personal_message = AsyncMock()
                
                # Mock _run_download to return a filename
                mock_run.return_value = "/path/to/video.mp4"
                
                # Test with Quality
                await YtDlpService.download_video("http://test.com", "client1", quality=1080)
                
                # Verify "finished" message was sent with correct filename
                mock_manager.send_personal_message.assert_called_with({
                    "status": "finished",
                    "filename": "video.mp4"
                }, "client1")
                
                # Get the args passed to _run_download
                args, _ = mock_run.call_args
                opts = args[0]
                
                expected_format = "bestvideo[height=1080]+bestaudio[ext=m4a]/best[height=1080]"
                assert opts['format'] == expected_format
                assert opts['impersonate'].client == 'chrome'
                assert isinstance(opts['impersonate'], ImpersonateTarget)

    @pytest.mark.asyncio
    async def test_download_video_default_format(self):
         with patch('app.services.ytdlp_service._run_download') as mock_run:
            with patch('app.services.ytdlp_service.manager') as mock_manager:
                mock_manager.send_personal_message = AsyncMock()
                
                # Mock _run_download to return a filename
                mock_run.return_value = "/path/to/video.mp4"
                
                # Test WITHOUT Quality
                await YtDlpService.download_video("http://test.com", "client1", quality=None)
                
                # Verify finished message
                mock_manager.send_personal_message.assert_called_with({
                    "status": "finished",
                    "filename": "video.mp4"
                }, "client1")
                
                args, _ = mock_run.call_args
                opts = args[0]
                
                # Should use default from settings (assuming it's formatted somewhere or passed directly)
                # In the code: format_str = f"{settings.YTDLP_FORMAT}"
                assert opts['format'] == settings.YTDLP_FORMAT

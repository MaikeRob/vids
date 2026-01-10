
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from app.main import app

client = TestClient(app)

# Must mock YtDlpService where it is IMPORTED in the endpoint file
SERVICE_MOCK_PATH = "app.api.v1.endpoints.download.YtDlpService"

def test_get_info_success():
    mock_data = {
        'title': 'Test Video', 
        'thumbnail': 'http://thumb',
        'duration': 100,
        'uploader': 'Tester',
        'view_count': 500,
        'webpage_url': 'http://youtube.com/v/123',
        'qualities': [1080, 720]
    }
    
    with patch(f"{SERVICE_MOCK_PATH}.get_info") as mock_get_info:
        mock_get_info.return_value = mock_data
        
        response = client.post(
            "/api/v1/download/info",
            json={"url": "http://youtube.com/v/123"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Test Video"
        assert data["qualities"] == [1080, 720]

def test_start_download_success():
    with patch(f"{SERVICE_MOCK_PATH}.download_video", new_callable=AsyncMock) as mock_download:
        mock_download.return_value = True
        
        response = client.post(
            "/api/v1/download/start",
            json={"url": "http://youtube.com/v/123", "quality": 1080}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "task_id" in data
        assert data["status"] == "pending"
        
        # Verify download_video was called (asyncio.create_task scheduled it)
        # Since it runs in loop, we expect it to be called.
        # TestClient runs in same thread/loop context often? 
        # Actually starlette TestClient runs sync.
        # But app uses asyncio.create_task.
        # We might not be able to easy assert 'called' immediately if loop is not advanced?
        # But usually in tests mocks record call immediately if create_task executes coroutine creation.
        
        # Verify scheduled
        # mock_download.assert_called_once() 
        # CAUTION: create_task might theoretically schedule for later. 
        # But usually we can assert correct args were passed.
        
        # We pass task_id from response to args
        task_id = data["task_id"]
        mock_download.assert_called_with("http://youtube.com/v/123", task_id, 1080)


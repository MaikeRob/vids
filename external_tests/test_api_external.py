import requests
import sys
import os
import shutil
from typing import Dict, Any, Optional

BASE_URL = "http://localhost:8000"
DOWNLOAD_DIR = "test_downloads"

def log_result(test_name: str, passed: bool, details: str = ""):
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"{status} - {test_name}")
    if details:
        print(f"   Details: {details}")
    if not passed:
        print("   Stopping tests due to failure.")
        sys.exit(1)

def ensure_download_dir():
    if not os.path.exists(DOWNLOAD_DIR):
        os.makedirs(DOWNLOAD_DIR)

def download_with_progress(url: str, payload: dict, filename: str, total_size_estimate: int = 0):
    print(f"\n⬇️  Downloading {filename}...")
    try:
        with requests.post(url, json=payload, stream=True) as response:
            if response.status_code != 200:
                print(f"Failed to start download: {response.status_code} - {response.text}")
                return False

            file_path = os.path.join(DOWNLOAD_DIR, filename)
            downloaded = 0

            with open(file_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)

                        if total_size_estimate > 0:
                            percent = (downloaded / total_size_estimate) * 100
                            # Clamp to 100% just in case estimate was low
                            percent = min(percent, 100.0)
                            bar_len = 30
                            filled_len = int(bar_len * percent / 100)
                            bar = '█' * filled_len + '-' * (bar_len - filled_len)
                            sys.stdout.write(f'\r[{bar}] {percent:.1f}% ({downloaded/(1024*1024):.2f} MB)')
                            sys.stdout.flush()
                        else:
                             sys.stdout.write(f'\rDownloaded: {downloaded/(1024*1024):.2f} MB')
                             sys.stdout.flush()

            print() # Newline after progress
            return True

    except Exception as e:
        print(f"\nError downloading: {e}")
        return False

def test_health() -> None:
    url = f"{BASE_URL}/health"
    try:
        response = requests.get(url)
        passed = response.status_code == 200 and response.json().get("status") == "ok"
        log_result("Health Check", passed, f"Status: {response.status_code}")
    except requests.RequestException as e:
        log_result("Health Check", False, f"Connection failed: {e}")

def get_video_info_data(video_url: str) -> dict:
    url = f"{BASE_URL}/api/v1/download/info"
    payload = {"url": video_url}
    try:
        response = requests.post(url, json=payload)
        if response.status_code != 200:
            log_result("Get Video Info", False, f"Status: {response.status_code}, Error: {response.text}")
            return {}
        return response.json()
    except requests.RequestException as e:
        log_result("Get Video Info", False, f"Connection failed: {e}")
        return {}

def main():
    print(f"Starting API Tests against {BASE_URL}...\n")
    ensure_download_dir()

    test_health()

    # Read from links.txt
    try:
        with open('links.txt', 'r') as f:
            lines = [line.strip() for line in f if line.strip()]
            if lines:
                SAMPLE_VIDEO_URL = lines[0]
                print(f"Using video URL from links.txt: {SAMPLE_VIDEO_URL}")
            else:
                print("links.txt is empty. Using fallback.")
                SAMPLE_VIDEO_URL = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
    except FileNotFoundError:
         print("links.txt not found. Using fallback.")
         SAMPLE_VIDEO_URL = "https://www.youtube.com/watch?v=jNQXAC9IVRw"

    info_data = get_video_info_data(SAMPLE_VIDEO_URL)
    qualities = info_data.get('qualities', [])
    audio_size = info_data.get('audio_filesize', 0)

    if not qualities:
        print("No qualities found in info. Skipping download tests.")
        return

    log_result("Get Video Info", True, f"Found {len(qualities)} qualities and Audio Size: {audio_size/(1024*1024):.2f} MB")

    # Select Low, Mid, High
    # qualities is sorted descending by height (High to Low)
    high = qualities[0]
    low = qualities[-1]
    mid = qualities[len(qualities) // 2]

    selected_tests = [
        ("High", high),
        ("Mid", mid),
        ("Low", low)
    ]

    # Remove duplicates if list is small
    unique_tests = {}
    for label, q in selected_tests:
        unique_tests[q['height']] = (label, q)

    for height, (label, q) in unique_tests.items():
        print(f"\n--- Testing {label} Quality ({height}p) ---")
        print(f"Estimated Size: {q.get('filesize', 0)/(1024*1024):.2f} MB")

        success = download_with_progress(
            f"{BASE_URL}/api/v1/download/stream",
            {"url": SAMPLE_VIDEO_URL, "mode": "video", "quality": height},
            f"video_{height}p.mp4",
            q.get('filesize', 0)
        )

        log_result(f"Download {label} ({height}p)", success)

    # Test Audio Download
    print("\n--- Testing Audio Only (m4a) ---")
    print(f"Estimated Size: {audio_size/(1024*1024):.2f} MB")

    success = download_with_progress(
        f"{BASE_URL}/api/v1/download/stream",
        {"url": SAMPLE_VIDEO_URL, "mode": "audio"},
        "audio.m4a",
        audio_size
    )
    log_result("Download Audio (m4a)", success)

    # Clean up (optional, maybe user wants to see files)
    # shutil.rmtree(DOWNLOAD_DIR)
    print(f"\n🎉 All tests passed! Files saved in '{DOWNLOAD_DIR}'")

if __name__ == "__main__":
    main()

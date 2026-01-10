
import yt_dlp
import json

def dump_info(url):
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            print(f"Extracting info for {url}...")
            info = ydl.extract_info(url, download=False)
            formats = info.get('formats', [])
            
            print(f"Found {len(formats)} formats.")
            
            video_formats = []
            for f in formats:
                height = f.get('height')
                vcodec = f.get('vcodec')
                acodec = f.get('acodec')
                ext = f.get('ext')
                format_id = f.get('format_id')
                note = f.get('format_note')
                
                # Print all formats to see what's available
                # print(f"ID: {format_id} | Ext: {ext} | Height: {height} | Vcodec: {vcodec} | Acodec: {acodec} | Note: {note}")
                
                if height and isinstance(height, int) and height > 0:
                     if vcodec and vcodec != 'none':
                        video_formats.append({
                            'id': format_id,
                            'ext': ext,
                            'height': height,
                            'vcodec': vcodec,
                            'acodec': acodec,
                            'note': note
                        })

            print("\n--- Valid Video Formats Detected by Current Logic ---")
            unique_heights = set()
            for vf in video_formats:
                print(vf)
                unique_heights.add(vf['height'])
            
            print(f"\nUnique Heights identified: {sorted(list(unique_heights), reverse=True)}")
            
            # Check what happens with strict Format String for 1080p if available
            if 1080 in unique_heights:
                print("\nChecking format selection for 1080p...")
                # Simulating selection
                # strict mode: bestvideo[height=1080]+bestaudio[ext=m4a]/best[height=1080]
                pass 

        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    url = "https://www.youtube.com/watch?v=UyA6tAZ5PAo" # One of the links
    dump_info(url)

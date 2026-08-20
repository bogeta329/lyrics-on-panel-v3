import json
import re
import base64
import threading
import hashlib
from pathlib import Path
import urllib.request
from urllib.parse import quote, unquote, urlencode, urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from mpris_prober import find_players, find_playing_players
from mpris_player import MprisPlayer, PlaybackStatus

class LyricsManager:
    """
    Core Controller: Manages player selection, tracking, and lyrics fetching.

    Note: ms here == microseconds, not miliseconds.
    """
    def __init__(self):
        self.lyrics_cache = {}
        self.players_cache = {}
        self._fetch_id = 0
        self.lock = threading.Lock()
        self.setup()
    
    def get_player(self, playername):
        player = self.players_cache.get(playername)
        if not player or not player.obj:
            player = MprisPlayer(playername)
            self.players_cache[playername] = player
        return player
    
    
    def setup(self, playername=None, playerobj=None, title=None, artist=None, album=None,
              duration=0, identity=None, lyrics=None, current_lyric=None,
              playback_status=PlaybackStatus.STOPPED, position_ms=0, available_players=None,
              next_lyric=None, current_lyric_duration_ms=0, time_remaining_ms=0, art_url=""):
        self.playername = playername
        self.playerobj = playerobj
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.identity = identity
        self.lyrics = lyrics
        self.current_lyric = current_lyric
        self.playback_status = playback_status
        self.position_ms = position_ms
        self.available_players = available_players or []
        self.next_lyric = next_lyric
        self.current_lyric_duration_ms = current_lyric_duration_ms
        self.time_remaining_ms = time_remaining_ms
        self.art_url = art_url
    
    
    def poll_status(self, requested_playername=None):
        """
        Polls for player changes and state updates.
        
        requested_playername == None => Global Mode
                        == 'org.mpris.MediaPlayer2.spotify' => Spotify Mode
                        == 'org.mpris.MediaPlayer2.yesplaymusic' => YesPlayMusic Mode
        
        Args:
            requested_playername (str, optional): The specific DBus name to track (e.g. 'org.mpris.MediaPlayer2.spotify').
                                             If None, defaults to the first available player.
        """
        with self.lock:
            playernames = find_players()
            # Clean up cached players that are no longer running
            for name in list(self.players_cache.keys()):
                if name not in playernames:
                    self.players_cache.pop(name, None)

            # Selection Logic:
                # 1. If there is no avaiable mpris complaint player, return empty State.
                # 2. If a specific target is requested:
                    # 2.1 If the requested target exists in the mpris2 dbus interface: pick it.
                    # 2.2 Otherwise, return empty state as the requested player is not playing.
                # 3. If no target requested, and then we enter the multiplexing mode. 
                    # 3.1 If there is a player with playing status, pick it.
                    # 3.2 If there is no player with playing status, fallback to the first player(paused/stopped) exists in mpris dbus.
                        # 3.2.1 If there is no player exists in the mpris dbus, return empty state.
            def set_free():
                self.setup()
                return self._get_empty_state()
            
            if not playernames:
                return set_free()
            current_playername = self.playername
            current_playerobj = None
            if requested_playername:
                 if requested_playername in playernames:
                     current_playername = requested_playername
                 else:
                    return self._get_empty_state()
            else:
                # Global mode: find the best player
                # If we have a current player, check if it's still valid
                if self.playername and self.playername in playernames:
                    try:
                        player = self.get_player(self.playername)
                        if player.obj:
                            if player.playback_status == PlaybackStatus.PLAYING:
                                # Current player is playing, use it
                                current_playername = self.playername
                                current_playerobj = player
                            else:
                                # Current player paused/stopped, check for other playing players
                                playing_playernames = find_playing_players(playernames)
                                if playing_playernames:
                                    current_playername = playing_playernames[0]
                                else:
                                    # No playing player, keep current one
                                    current_playername = self.playername
                                    current_playerobj = player
                    except Exception:
                        pass
                # No valid current player, find one
                if not current_playerobj:
                    playing_playernames = find_playing_players(playernames)
                    if playing_playernames:
                        current_playername = playing_playernames[0]
                    elif playernames:
                        current_playername = playernames[0]
                    else:
                        return set_free()
                    current_playerobj = self.get_player(current_playername)
            if not current_playerobj:
                current_playerobj = self.get_player(current_playername)
            if not current_playerobj.obj:
                return set_free()
            # Cache DBus properties to avoid repeated calls
            try:
                track_info = current_playerobj.track_info
                playback_status = current_playerobj.playback_status
                position = current_playerobj.position
                identity = current_playerobj.identity
            except Exception:
                return set_free()
            if identity == "Unknown":
                self.players_cache.pop(current_playername, None)
                return set_free()
            track_changed = (self.title != track_info['title']
                    or self.artist != track_info['artist']
                    or self.album != track_info['album'])
            if track_changed:
                self.title = track_info['title']
                self.artist = track_info['artist']
                self.album = track_info['album']
                self._fetch_id += 1
                # Check if this track has cached lyrics
                artists_str = ", ".join(track_info['artist']) if track_info['artist'] else ""
                cache_key = f"{artists_str} - {track_info['title']}"
                cached_lyrics = self._get_cached_lyrics(cache_key)
                if cached_lyrics:
                    self.lyrics = cached_lyrics
                else:
                    self.lyrics = None
                    threading.Thread(target=self._fetch_lyrics, args=(current_playername, track_info, self._fetch_id), daemon=True).start()
            self.position_ms = position
            lyrics_info = self._get_lyrics_info()
            self.setup(
                playername=current_playername,
                playerobj=current_playerobj,
                title=track_info['title'],
                artist=track_info['artist'],
                album=track_info['album'],
                duration=track_info['length'],
                identity=identity,
                lyrics=self.lyrics,
                current_lyric=lyrics_info["current_lyric"],
                playback_status=playback_status,
                position_ms=position,
                available_players=playernames,
                next_lyric=lyrics_info["next_lyric"],
                current_lyric_duration_ms=lyrics_info["current_lyric_duration_ms"],
                time_remaining_ms=lyrics_info["time_remaining_ms"],
                art_url=track_info.get('art_url', '')
            )
            return self.get_state()


    def _clean_title(self, title):
        if not title:
            return ""
        cleaned = title
        cleaned = re.sub(r'[\(\[]feat\..*?[\)\]]', '', cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r'[\(\[](official|lyric|video|audio|remastered|live|deluxe|version|edit|explicit).*?[\)\]]', '', cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r'\s*-\s*(remastered|live|deluxe|bonus|radio edit|\d{4} remaster).*$', '', cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        return cleaned if cleaned else title

    def _clean_artist(self, artist):
        if isinstance(artist, list):
            artist = artist[0] if artist else ""
        if not artist:
            return ""
        return re.sub(r'\s*(feat\.|ft\.).*$', '', artist, flags=re.IGNORECASE).strip()

    def _fetch_lyrics(self, playername, track_info, fetch_id):
        # Check if this fetch is still current
        if self._fetch_id != fetch_id:
            return
        title = track_info['title']
        artists = track_info['artist']
        artist = artists[0] if artists else ''
        album = track_info['album']
        length = track_info['length']
        url = track_info['url']
        if not title or not artists:
            return
        try:
            lyrics = None
            if playername == 'org.mpris.MediaPlayer2.yesplaymusic':
                lyrics = self._fetch_lyrics_ypm(title)
            elif playername == 'org.mpris.MediaPlayer2.lx-music-desktop':
                lyrics = self._fetch_lyrics_lxmusic()
            else:
                lyrics = self._fetch_lyrics_local(url)
                if lyrics is None:
                    # Check again before expensive HTTP calls
                    if self._fetch_id != fetch_id:
                        return
                    # Try LRCLIB first
                    lyrics = self._fetch_lyrics_lrclib(title, artist, album, length, 8)
                    # If LRCLIB is missing or only has estimated plain lyrics, try Kugou for real synced LRC
                    is_estimated = (lyrics and len(lyrics) > 0 and lyrics[0].get('is_estimated', False))
                    if lyrics is None or is_estimated:
                        if self._fetch_id != fetch_id:
                            return
                        k_lyrics = self._fetch_lyrics_kugou(title, artist, 8)
                        if k_lyrics:
                            lyrics = k_lyrics
            # Only write if this fetch is still current
            with self.lock:
                if self._fetch_id == fetch_id:
                    self.lyrics = lyrics
                    if lyrics:
                        artists_str = ", ".join(artists) if artists else ""
                        cache_key = f"{artists_str} - {title}"
                        self.lyrics_cache[cache_key] = lyrics
                        self._save_cached_lyrics(cache_key, lyrics)
        except Exception as e:
            with self.lock:
                if self._fetch_id == fetch_id:
                    self.lyrics = None


    def _http_get(self, url, timeout=10):
        """Simple HTTP GET using urllib with custom User-Agent. Returns (status_code, data) tuple."""
        try:
            req = urllib.request.Request(
                url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                }
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.status, resp.read().decode('utf-8')
        except Exception:
            return None, None

    def _fetch_lyrics_ypm(self, title):
        """Fetch lyrics from YesPlayMusic localhost API. Returns parsed lyrics or None."""
        ypm_base_url = "http://localhost:27232"
        status, text = self._http_get(f"{ypm_base_url}/player")
        if status != 200:
            return None
        data = json.loads(text)
        if not data or not data.get('currentTrack') or data['currentTrack'].get('name') != title:
            return None
        track_id = data['currentTrack']['id']
        status, text = self._http_get(f"{ypm_base_url}/api/lyric?id={track_id}")
        if status != 200:
            return None
        data = json.loads(text)
        if data and data.get('lrc') and data['lrc'].get('lyric'):
            return self._parse_lrc(data['lrc']['lyric'])
        return None

    def _fetch_lyrics_lxmusic(self, port=23330):
        """Fetch lyrics from LX Music localhost API. Returns parsed lyrics or None."""
        lxmusic_base_url = f"http://localhost:{port}"
        status, text = self._http_get(f"{lxmusic_base_url}/lyric")
        if status == 200 and text:
            return self._parse_lrc(text)
        return None

    def _fetch_lyrics_local(self, song_path):
        """Fetch lyrics from disk."""
        if not song_path.startswith('file://'):
            return None
        lrc_path = Path(unquote(urlparse(song_path).path)).with_suffix('.lrc')
        try:
            content = lrc_path.read_text(encoding='utf-8')
        except (FileNotFoundError, PermissionError, OSError):
            return None
        return self._parse_lrc(content)

    def _fetch_lyrics_lrclib(self, title, artist, album, length, timeout=5):
        """Fetch lyrics from lrclib.net (compatible mode). Returns parsed lyrics or None."""
        duration_sec = length // 1000000 if length else None
        c_title = self._clean_title(title)
        c_artist = self._clean_artist(artist)

        params = urlencode({
            'track_name': c_title,
            'artist_name': c_artist,
            'album_name': album
        })

        def fetch_exact():
            if not duration_sec:
                return (None, None)
            url = f"https://lrclib.net/api/get?{params}&duration={duration_sec}"
            status, text = self._http_get(url, timeout)
            if status == 200 and text:
                data = json.loads(text)
                return (data.get('syncedLyrics'), data.get('plainLyrics'))
            return (None, None)

        def fetch_search():
            q_str = f"{c_artist} {c_title}"
            url = f"https://lrclib.net/api/search?q={quote(q_str)}"
            status, text = self._http_get(url, timeout)
            if status == 200 and text:
                data = json.loads(text)
                synced_m, plain_m = None, None
                for result in data:
                    res_artist = result.get('artistName', '').lower()
                    if c_artist.lower() in res_artist or res_artist in c_artist.lower() or not c_artist:
                        if result.get('syncedLyrics') and not synced_m:
                            synced_m = result['syncedLyrics']
                        if result.get('plainLyrics') and not plain_m:
                            plain_m = result['plainLyrics']
                return (synced_m, plain_m)
            return (None, None)

        def fetch_fuzzy():
            url = f"https://lrclib.net/api/search?q={quote(c_title)}"
            status, text = self._http_get(url, timeout)
            if status == 200 and text:
                data = json.loads(text)
                synced_m, plain_m = None, None
                for result in data:
                    res_artist = result.get('artistName', '').lower()
                    if c_artist.lower() in res_artist or res_artist in c_artist.lower() or not c_artist:
                        if result.get('syncedLyrics') and not synced_m:
                            synced_m = result['syncedLyrics']
                        if result.get('plainLyrics') and not plain_m:
                            plain_m = result['plainLyrics']
                return (synced_m, plain_m)
            return (None, None)

        # Run all fetches in parallel
        with ThreadPoolExecutor(max_workers=3) as executor:
            futures = {
                executor.submit(fetch_exact): 0,
                executor.submit(fetch_search): 1,
                executor.submit(fetch_fuzzy): 2,
            }
            results = [(None, None), (None, None), (None, None)]
            for future in as_completed(futures):
                priority = futures[future]
                try:
                    results[priority] = future.result()
                except Exception:
                    pass

        # 1. Prefer synced lyrics
        for synced, plain in results:
            if synced:
                return self._parse_lrc(synced)

        # 2. Fallback to plain lyrics candidate
        for synced, plain in results:
            if plain:
                parsed = self._parse_plain_lrc(plain, length)
                if parsed:
                    return parsed
        return None

    def _parse_plain_lrc(self, plain_text, length):
        if not plain_text:
            return None
        raw_lines = [line.strip() for line in plain_text.splitlines() if line.strip()]
        if not raw_lines:
            return None
        total = len(raw_lines)
        lines = []
        if length and length > 0:
            intro_us = int(length * 0.05)  # 5% intro offset to account for instrumental intro
            vocal_duration_us = int(length * 0.88)  # 88% vocal window
            step_us = vocal_duration_us // max(1, total - 1)
            for i, line in enumerate(raw_lines):
                time_ms = intro_us + (i * step_us)
                lines.append({"time_ms": time_ms, "lyric": line, "is_estimated": True})
        else:
            step_us = 4000000
            for i, line in enumerate(raw_lines):
                lines.append({"time_ms": i * step_us, "lyric": line, "is_estimated": True})
        return lines

    def _fetch_lyrics_kugou(self, title, artist, timeout=5):
        """Fetch lyrics from Kugou Music API (fallback synced lyrics). Returns parsed lyrics or None."""
        c_title = self._clean_title(title)
        c_artist = self._clean_artist(artist)
        q = f"{c_title} {c_artist}".strip()
        if not q:
            return None
        url = f"http://mobilecdn.kugou.com/api/v3/search/song?keyword={quote(q)}&page=1&pagesize=5"
        status, text = self._http_get(url, timeout)
        if status != 200 or not text:
            return None
        try:
            data = json.loads(text)
            info = data.get('data', {}).get('info', [])
            if not info:
                return None
            hash_val = info[0]['hash']
            l_url = f"http://krcs.kugou.com/search?ver=1&man=yes&client=mobi&keyword={quote(q)}&hash={hash_val}"
            l_status, l_text = self._http_get(l_url, timeout)
            if l_status != 200 or not l_text:
                return None
            l_data = json.loads(l_text)
            cands = l_data.get('candidates', [])
            if not cands:
                return None
            cand_id = cands[0]['id']
            accesskey = cands[0]['accesskey']
            d_url = f"http://krcs.kugou.com/download?ver=1&client=mobi&id={cand_id}&accesskey={accesskey}&fmt=lrc"
            d_status, d_text = self._http_get(d_url, timeout)
            if d_status != 200 or not d_text:
                return None
            d_data = json.loads(d_text)
            b64 = d_data.get('content', '')
            if b64:
                lrc = base64.b64decode(b64).decode('utf-8', errors='ignore')
                return self._parse_lrc(lrc)
        except Exception as e:
            print(f"[DEBUG] Kugou lyrics fetch error: {e}")
        return None


    def _parse_lrc(self, lrc_text):
        lines = []
        for line in lrc_text.splitlines():
            parts = line.split(']')
            if len(parts) > 1:
                time_str = parts[0].replace('[', '').strip()
                lyric = parts[1].strip()
                try:
                    m, s = time_str.split(':')
                    time_ms = int((float(m) * 60 + float(s)) * 1000000)
                    lines.append({"time_ms": time_ms, "lyric": lyric})
                except Exception:
                    continue
        lines.sort(key=lambda x: x['time_ms'])
        return lines


    def _get_current_lyric(self):
        if not self.lyrics:
            return None
        lyrics_line_num = len(self.lyrics)
        start = 0
        end = lyrics_line_num - 1
        while start <= end:
            mid = (start + end) >> 1
            if self.position_ms == self.lyrics[mid]['time_ms']:
                end = mid
                break
            if self.position_ms > self.lyrics[mid]['time_ms']:
                start = mid + 1
            else:
                end = mid - 1
        if end < 0:
            return None
        # If current lyric is empty, find the previous non-empty one
        while end >= 0 and not self.lyrics[end]['lyric']:
            end -= 1
        if end < 0:
            return None
        return self.lyrics[end]['lyric']       
        
        
    def get_state(self):
        if not self.playerobj:
            return self._get_empty_state()
        return {
            "playback_status": self.playback_status.value.lower(),
            "player": {
                "identity": self.identity,
                "bus_name": self.playername
            },
            "track": {
                "title": self.title,
                "artist": ", ".join(self.artist) if self.artist else "",
                "album": self.album,
                "duration": self.duration,
                "art_url": getattr(self, 'art_url', '') or ""
            },
            "position_ms": self.position_ms,
            "lyrics": {
                'current_lyric': self.current_lyric,
                'next_lyric': getattr(self, 'next_lyric', '') or '',
                'current_lyric_duration_ms': getattr(self, 'current_lyric_duration_ms', 0) or 0,
                'time_remaining_ms': getattr(self, 'time_remaining_ms', 0) or 0,
            },
            "available_players": self.available_players
        }


    def _get_empty_state(self):
        return {
            "playback_status": PlaybackStatus.STOPPED.value.lower(),
            "player": None,
            "track": None,
            "position_ms": 0,
            "lyrics": None,
            "available_players": None
        }

    def _get_cached_lyrics(self, cache_key):
        # 1. Check in-memory cache
        if cache_key in self.lyrics_cache:
            return self.lyrics_cache[cache_key]
        
        # 2. Check disk cache
        try:
            h = hashlib.sha256(cache_key.encode('utf-8')).hexdigest()
            cache_file = Path("/tmp/lyrics-on-panel-cache") / f"{h}.json"
            if cache_file.exists():
                lyrics = json.loads(cache_file.read_text(encoding='utf-8'))
                self.lyrics_cache[cache_key] = lyrics
                return lyrics
        except Exception as e:
            print(f"[DEBUG] Error reading disk cache: {e}")
        return None

    def _save_cached_lyrics(self, cache_key, lyrics):
        try:
            cache_dir = Path("/tmp/lyrics-on-panel-cache")
            cache_dir.mkdir(parents=True, exist_ok=True)
            h = hashlib.sha256(cache_key.encode('utf-8')).hexdigest()
            cache_file = cache_dir / f"{h}.json"
            cache_file.write_text(json.dumps(lyrics), encoding='utf-8')
        except Exception as e:
            print(f"[DEBUG] Error writing disk cache: {e}")

    def _get_lyrics_info(self):
        if not self.lyrics:
            return {
                "current_lyric": "",
                "next_lyric": "",
                "current_lyric_duration_ms": 0,
                "time_remaining_ms": 0
            }
        
        lyrics_line_num = len(self.lyrics)
        start = 0
        end = lyrics_line_num - 1
        while start <= end:
            mid = (start + end) >> 1
            if self.position_ms == self.lyrics[mid]['time_ms']:
                end = mid
                break
            if self.position_ms > self.lyrics[mid]['time_ms']:
                start = mid + 1
            else:
                end = mid - 1
        
        # If before first lyric
        if end < 0:
            next_lyric = self.lyrics[0]['lyric'] if lyrics_line_num > 0 else ""
            next_time = self.lyrics[0]['time_ms'] if lyrics_line_num > 0 else 0
            remaining_us = max(0, next_time - self.position_ms)
            return {
                "current_lyric": "",
                "next_lyric": next_lyric,
                "current_lyric_duration_ms": remaining_us // 1000,
                "time_remaining_ms": remaining_us // 1000
            }
        
        # Find current lyric text
        curr_idx = end
        while curr_idx >= 0 and not self.lyrics[curr_idx]['lyric']:
            curr_idx -= 1
        current_lyric = self.lyrics[curr_idx]['lyric'] if curr_idx >= 0 else ""
        
        # Find next non-empty lyric text
        next_lyric = ""
        next_time = 0
        next_idx = end + 1
        while next_idx < lyrics_line_num:
            if self.lyrics[next_idx]['lyric']:
                next_lyric = self.lyrics[next_idx]['lyric']
                next_time = self.lyrics[next_idx]['time_ms']
                break
            next_idx += 1
            
        # Compute durations
        if not next_lyric:
            if self.duration > 0 and self.duration > self.lyrics[end]['time_ms']:
                duration_us = self.duration - self.lyrics[end]['time_ms']
                remaining_us = max(0, self.duration - self.position_ms)
            else:
                duration_us = 10000000
                remaining_us = max(0, duration_us - (self.position_ms - self.lyrics[end]['time_ms']))
        else:
            duration_us = next_time - self.lyrics[end]['time_ms']
            remaining_us = max(0, next_time - self.position_ms)
            
        return {
            "current_lyric": current_lyric,
            "next_lyric": next_lyric,
            "current_lyric_duration_ms": duration_us // 1000,
            "time_remaining_ms": remaining_us // 1000
        }
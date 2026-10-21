# SKYSPACE Windows aircraft feed

The GitHub Pages website draws real FAA airspace. This Python helper retrieves ADS-B aircraft positions *from Windows instead of from the browser*, so it is not affected by aircraft API CORS restrictions.

## Installation

1. Install Python 3.9+ from python.org, if necessary.
2. Download or clone this repository. Open the skyspace folder.
3. Double-click START_SKYSPACE_FEED.bat.
4. Choose 1 for near-live aircraft on this PC, updating approximately every 20 seconds.
5. Keep the black window running. Open https://qcox90.github.io/ATC-Role-Survivor/skyspace/ in Edge/Chrome **on this same PC**.
6. If Edge/Chrome asks to allow local-network/loopback access, choose Allow.

No pip modules or API key required for local mode. Python fetches from adsb.fi or ADSB.lol. Local API: http://127.0.0.1:8766/aircraft.

## Optional GitHub snapshot mode for other devices

Choose 2 to additionally publish an aircraft snapshot to the special skyspace-live branch every five minutes. The main branch and Godot game are not rebuilt for each snapshot.

Mode 2 needs a *fine-grained personal access token* from GitHub Settings > Developer settings > Personal access tokens > Fine-grained tokens. Limit access to this repository only, with Repository permissions > Contents: Read and write. Enter it at the hidden prompt when the script starts. The script does not save it to disk. Do not put the token in any repository file.

Remote devices can view **delayed snapshots only**. GitHub Pages is static, and GitHub raw/API caching plus an upload every five minutes prevent true live streaming. Data displays as SNAPSHOT, with an age indicator. Repeated snapshot commits grow repository history and are meant as a short-term experiment, not a permanent continuous service.

For near-live aircraft on phones/remote devices, a separate HTTPS backend/secure tunnel is required. This is not an FAA-certified ATC or navigation tool.

Sources and terms: https://github.com/adsbfi/opendata and https://api.adsb.lol/docs (personal noncommercial/ODbL as applicable).

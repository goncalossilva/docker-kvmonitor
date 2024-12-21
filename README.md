# docker-kvmonitor

[Kento's baby monitor](https://github.com/kentonv/kvmonitor), dockerized.

## Run

```bash
docker run ghcr.io/goncalossilva/kvmonitor:latest
```

## Build

```bash
docker buildx build --platform linux/amd64,linux/arm64 --push -t ghcr.io/goncalossilva/kvmonitor:latest .
```

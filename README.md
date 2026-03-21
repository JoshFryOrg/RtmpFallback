# RTMP Fallback
This project prevents a livestream dying and instead will display a fallback image.

For example:
1) We stream to channel 1 over a mobile hotspot to a dedicated server running datarhei's Restreamer.
2) Channel 1 would be our `INPUT_URL` RTMP stream.
3) We have our `OUTPUT_URL` RTMP stream pointed to channel 2.
4) Then we can restream channel 2.
5) If our mobile hotspot dies, our livestream to Facebook will auto recover when we do rather than ending.

## Docker Compose
VA-API with Intel iGPU Example:

```
services:
  rtmp-fallback:
    image: 'joshfryup/rtmp-fallback:latest'
    container_name: RtmpFallback
    restart: unless-stopped
    volumes:
      - '/yourDirectory:/app:ro'
    environment:
      - INPUT_URL=rtmp://
      - OUTPUT_URL=rtmp://
      - LIBVA_DRIVER_NAME=iHD
    devices:
      - /dev/dri:/dev/dri
```

You can remove `LIBVA_DRIVER_NAME` and the `devices` section if you're not on an iGPU, and use the standard `entrypoint.sh` in your mounted `/app` volume.

If you are, you need to rename `entrypoint-vaapi.sh` to `entrypoint.sh` and place it in your volume.

## Note
On first start before you start streaming, the fallback image can look squished rather than 1920x1080. This goes away when you start streaming.
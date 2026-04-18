#!/bin/bash

VIDEO_CAPS="video/x-raw,width=1920,height=1080,framerate=60/1,format=NV12"
AUDIO_CAPS="audio/x-raw,rate=48000,channels=2,format=F32LE"
BUFFER_NS=3000000000

exec gst-launch-1.0 -e \
  fallbacksrc name=fs \
    uri="$INPUT_URL" \
    fallback-uri="file:///app/fallback.jpg" \
    restart-on-eos=true \
  \
  flvmux name=mux streamable=true ! rtmpsink location="$OUTPUT_URL" \
  \
  vacompositor name=vmix ! \
    vapostproc ! $VIDEO_CAPS ! \
    vah264enc bitrate=10000 key-int-max=30 b-frames=3 ref-frames=4 cpb-size=30000 target-usage=1 ! \
    h264parse config-interval=1 ! queue ! mux.video \
  \
  audiomixer name=amix start-time-selection=0 latency=$BUFFER_NS ! $AUDIO_CAPS ! \
    avenc_aac bitrate=320000 ! \
    aacparse ! queue ! mux.audio \
  \
  fs.video_0 ! videoconvert ! videoscale ! videorate ! $VIDEO_CAPS ! \
    queue max-size-buffers=0 max-size-time=$BUFFER_NS leaky=downstream ! vmix. \
  \
  fs.audio_0 ! audioconvert ! audioresample ! \
    audiorate skip-to-first=true ! $AUDIO_CAPS ! \
    queue max-size-buffers=0 max-size-time=$BUFFER_NS leaky=downstream ! amix.
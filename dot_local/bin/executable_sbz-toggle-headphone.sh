#!/bin/bash
CARD=Creative
CARD_ID="alsa_card.pci-0000_04_00.0"

if [[ $(pactl get-default-sink) == *analog* ]]; then
    # 音箱 -> 光纤耳机
    pactl set-card-profile "$CARD_ID" output:iec958-stereo+input:analog-stereo
    sleep 0.3
    pactl set-default-sink "alsa_output.pci-0000_04_00.0.iec958-stereo"
    amixer -c "$CARD" sset 'IEC958' on
    amixer -c "$CARD" sset Master mute
    amixer -c "$CARD" sset PCM 0%
    amixer -c "$CARD" sset Front mute
    amixer -c "$CARD" sset Surround mute
    amixer -c "$CARD" sset Center mute
    amixer -c "$CARD" sset LFE mute
    amixer -c "$CARD" sset 'Full-Range Front Speakers' off
    amixer -c "$CARD" sset 'Full-Range Rear Speakers' off
    amixer -c "$CARD" sset 'Enable OutFX' off
    amixer -c "$CARD" sset 'FX: X-Bass' off
    notify-send --app-name="音频模式" "已切至：光纤耳机 (纯净)" --icon=audio-headphones
else
    # 光纤/其他 -> 音箱 (复用 startup 脚本)
    ~/.local/bin/sbz-speaker.sh
    notify-send --app-name="音频模式" "已切至：Soundbar (35Hz 音效)" --icon=audio-speakers
fi


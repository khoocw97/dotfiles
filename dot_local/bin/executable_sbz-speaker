#!/bin/bash
CARD=Creative
CARD_ID="alsa_card.pci-0000_04_00.0"

pactl set-card-profile "$CARD_ID" output:analog-stereo+input:analog-stereo
sleep 0.3
pactl set-default-sink "alsa_output.pci-0000_04_00.0.analog-stereo"
amixer -c "$CARD" sset 'PCM' 100%
amixer -c "$CARD" sset Front 9dB unmute
amixer -c "$CARD" -M sset Master 29%
amixer -c "$CARD" sset 'Enable OutFX' unmute
amixer -c "$CARD" sset 'HP/Speaker Auto Detect' off
amixer -c "$CARD" sset 'Full-Range Front Speakers' unmute
amixer -c "$CARD" sset 'Output Select' Speakers
amixer -c "$CARD" sset 'FX: X-Bass' 20
amixer -c "$CARD" sset 'FX: X-Bass Crossover' 30


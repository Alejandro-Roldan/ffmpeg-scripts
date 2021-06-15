# ffmpeg-scripts
A bunch of ffmpeg scripts

## flactomp3
A script to paralelly convert flac from a source directory into mp3 in an output directory. Also copies mp3s from source directory into output directory. Uses the AutoImageCover.py to workaround a ffmpeg bug.

## ApeToFlac
A script to split music albums (either with input .ape or .flac) into the songs, in .flac using a .cue file

## PlaylistUpdater
Loops through the directories inside a directory and uses youtube-dl to download playlists and new items that haven't been downloaded previously specified in a .url text file inside each directory.

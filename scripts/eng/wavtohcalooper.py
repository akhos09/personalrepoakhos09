import os
import subprocess
import shutil
import yt_dlp
import re
import tkinter
from tkinter import filedialog as fd
from tkinter import Tk
from scipy.io import wavfile

# Function to validate YouTube URL
def is_valid_youtube_url(url):
    youtube_regex = r'^(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]{11}$'
    return re.match(youtube_regex, url) is not None

# Function to download music in .wav format from YouTube using yt_dlp and ffmpeg
def download_music_from_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Directory where the downloaded WAV files will be stored
    downloaded_wav_dir = 'wav_files'
    os.makedirs(downloaded_wav_dir, exist_ok=True)

    for line in lines:
        # Split each line into URL, WAV name, and HCA name
        url, wav_name, hca_name = line.strip().split(',')

        # Validate the URL
        if not is_valid_youtube_url(url):
            print(f"Invalid YouTube URL: {url}. Skipping.")
            continue

        # Download Options
        ydl_opts = {
            'format': 'bestaudio/best',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'wav',
                'preferredquality': '192',
            }],
            'outtmpl': f'{wav_name}',
        }

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])

            # Move the downloaded WAV file to the specified directory
            wav_file_path = f"{wav_name}.wav"
            shutil.move(wav_file_path, os.path.join(downloaded_wav_dir, wav_file_path))
            print(f'Music downloaded successfully as {wav_file_path} and moved to {downloaded_wav_dir}.')
        except Exception as e:
            print(f"Error downloading or moving music for {url}: {e}")

# Function to select multiple WAV files and perform necessary calculations to loop the music
def select_files_wav_and_calc(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Create the output directory for HCA files
    os.makedirs('./hca_converted', exist_ok=True)

    for line in lines:
        url, wav_name, hca_name = line.strip().split(',')

        wav_file = os.path.abspath(f'./wav_files/{wav_name}.wav')

        fs, data = wavfile.read(wav_file)
        
        # Calculate song duration in seconds
        duration_seconds = data.shape[0] / fs
        
        # Calculate loop number to loop the song
        loop_number = fs * duration_seconds
        
        # Form the command to run VGAudiocli.exe
        command = f'VGAudiocli.exe -l 0-{int(loop_number)} -i "{wav_file}" ./hca_converted/{hca_name}'
        
        try:
            # Execute the command in the terminal
            result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
            print(f"Script executed successfully for {wav_name}:\n{result.stdout}")
            
        except subprocess.CalledProcessError as e:
            print(f"Error occurred executing the script for {wav_name}:\n{e.stderr}")

def select_file():
    print('Please, select the file where the URLs, WAV names, and HCA names are: ')
    root = Tk()
    root.withdraw() 
    root.attributes('-topmost', True)   # Dialog above other applications
    filetypes = [("txt files", "*.txt")]
    file_path = fd.askopenfilename(filetypes=filetypes)
    root.destroy()  
    return file_path


tip = tkinter.messagebox.showinfo(title='TIP', message='There is an extractor of URLs made for the Youtube playlists located at the tools directory.')
first_question = tkinter.messagebox.askyesno(title='WARNING', message='Did you executed the script in the directory that contains the script?')
second_question = tkinter.messagebox.askyesno(title='WARNING', message='Did you downloaded and pasted the ffmpeg.exe into the directory that contains the script?')

if first_question:
    if second_question:
        file_path = select_file()
    else:
        print('Please select a .txt file')
        file_path = select_file()
        print('No .txt file selected. Exiting...')
    if file_path:
            download_music_from_file(file_path)
            select_files_wav_and_calc(file_path)
    else:
        tkinter.messagebox.showerror(title='ERROR', message='Paste the ffmpeg.exe into the directory of the script. Download: https://github.com/BtbN/FFmpeg-Builds/releases')
else:
    tkinter.messagebox.showerror(title='ERROR', message='Execute the script in the directory of the script.')

    


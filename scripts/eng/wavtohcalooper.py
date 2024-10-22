from tkinter import filedialog as fd
from scipy.io import wavfile
import os
import subprocess

# Function to select multiple WAV files and perform necessary calculations
def select_files_wav_and_calc():

    filetypes = [("wav files", "*.wav")]
    wav_files = fd.askopenfilenames(filetypes=filetypes)
    
    # Loop through each selected file
    for wav_file in wav_files:
        route = os.path.abspath(wav_file)  # Get absolute path of the file
        
        # Get WAV file metadata
        fs, data = wavfile.read(route)
        
        # Calculate song duration in seconds
        duration_seconds = data.shape[0] / fs
        
        loop_number = fs * duration_seconds
        
        # Get the output .hca file name for each wav file
        hca_name = input(f"Output file name for {os.path.basename(route)} (.hca): ")
        
        # Form the command to run VGAudiocli.exe
        command = f'VGAudiocli.exe -l 0-{int(loop_number)} -i "{route}" {hca_name}'    
        try:
            # Execute the command in the terminal
            result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
            print(f"Script executed successfully for {os.path.basename(route)}:\n", result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Error occurred executing the script for {os.path.basename(route)}:\n", e.stderr)

# Call the function to select WAV files and perform the conversion
select_files_wav_and_calc()

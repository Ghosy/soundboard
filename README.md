# Soundboard
A utility that allows the user to play and control sound clips in a fashion like a soundboard.

## Installing

### Prerequisities
* Mpv or Mplayer

### Process
1. Clone or download contents of git repository  
`git clone https://github.com/Ghosy/soundboard.git`

2. Navigate to the cloned repository  
`cd soundboard`

3. Run install.sh as root  
`./install.sh`  
or  
`bash install.sh`

4. Run soundboard  
`soundboard -cf /path/to/file`

## Usage Example
`soundboard -of /path/to/file.wav`  
This example uses the overlap flag, so if the command was run again, file.wav would play again even if the other instance is still running.

`soundboard -cf /path/to/file.wav`  
This example uses the cancel flag. If the same command runs again, while file.wav is playing, the playing of file.wav will stop. To start playing file.wav you must run the command again.

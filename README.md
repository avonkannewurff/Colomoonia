# Colomoonia!

Build your moon colony and protect it from those pesky moon creatures!

This is game is a simple colony defense-like game where you place buildings on the moon to colonize it, and shoot lasers to protect your buildings from moon creatures that you've angered with your expansions:

![image](/demos/colomoonia_demo_04122025.gif)

This game was made during [PlayJam 7](https://itch.io/jam/playjam-7), a fun, weekend-long game jam for the playdate. You can find the itch.io page for the game [here](https://atomvk.itch.io/colomoonia).

# How to Play

If you have a Playdate, simply download the pdx.zip file from the [itch.io](https://atomvk.itch.io/colomoonia) page, and use the Panic website to sideload the game onto your device.

If you do not have a Playdate, or wish to build the game from this source, follow the steps below to download the Playdate SDK, Playdate simulator, and build the game via VSCode.

# Setup

1. Download and install the Playdate SDK at [https://play.date/dev/](https://play.date/dev/)
   - **Linux:**
     - Extract the zipped SDK folder and rename the folder to `PlaydateSDK`
     - Move the `PlaydateSDK` folder to your "Documents" folder (or any other desired location)
     - Right-click the folder and select "Open in Terminal"
     - Type `sudo ./setup.sh` and press enter to run the setup script
     - Keep terminal window open for the next step
2. **Windows and Linux:** Set your environment variable

   - **Windows**

     - Open the "Windows Powershell" application, copy and paste the following into the terminal, and then press enter:

       ```sh
       [Environment]::SetEnvironmentVariable("PLAYDATE_SDK_PATH", "$env:USERPROFILE\Documents\PlaydateSDK", "User")
       ```

     - If you installed the Playdate SDK at a different path, change the `$env:USERPROFILE\Documents\PlaydateSDK` part of the command to where you installed it
     - To check if it worked correctly, close and reopen Powershell, type `$env:PLAYDATE_SDK_PATH`, and press enter. It should print the path to your `PlaydateSDK` folder

   - **Linux**

     - In a terminal window, type the following command to open your `.bashrc` file located in your Home directory using the nano text editor (replace `.bashrc` with `.zshrc` if your distro uses zsh instead of bash)
       ```
       nano ~/.bashrc
       ```
     - Scroll to the bottom of the file and copy and paste the following command (if you put your folder in a different location, change `$HOME/Documents/PlaydateSDK` to the path of your `PlaydateSDK` folder)

       ```sh
       export PLAYDATE_SDK_PATH=$HOME/Documents/PlaydateSDK
       ```

     - Press `Ctrl + X` to exit, `Y` to save, and then `Enter` to confirm the file name
     - If `nano` is not installed, you can manually edit/create your `.bashrc` file which you can find by navigating to your Home folder (make sure hidden files are shown)

3. Clone this repository to your local machine, and then open it in VSCode
4. A popup should appear on the bottom right of your VSCode window asking you to install recommended extensions - go ahead and click install
   - If the popup does not appear, you can install the extensions manually with the `Extensions` icon (tetris block looking thing) on the left side and searching `@recommended`
   - The extensions are "Lua" by sumneko and "Playdate Debug" by midouest
5. Press `ctrl + shift + b` (`cmd + shift + b` for Mac), or go to `Terminal -> Run Build Task...` at the top of your VSCode window to build your project
6. The Playdate Simulator should launch automatically with the game loaded

# Troubleshooting

- If you opened VSCode before you set your environment variable, VSCode hasn't picked up on the new environment variable yet - first try closing and reopening VSCode
- `Task configuration failed: Could not read Playdate SDK version at <path>`
  - This means that the PlaydateSDK folder was not found at the path that you set your `PLAYDATE_SDK_PATH` environment variable to. It likely means that your PlaydateSDK folder was not installed in the default documents folder (`C:\Users\<Username>\Documents\PlaydateSDK` for Windows). Double-check your Documents folder and look for a `PlaydateSDK` folder. If it's there, try setting it again. Otherwise, it got installed somewhere else, so you'll need to set the environment variable to that path, or reinstall the SDK at your normal documents folder
  - Sometimes, for Windows, your PlaydateSDK gets installed in the OneDrive documents folder instead by default. In that case, you'll need to change the environment variable path to your OneDrive path instead (something like `"C:\Users\<Username>\OneDrive\Documents\PlaydateSDK"`), or reinstall the Playdate SDK in your normal documents folder
  - Another possible Windows issue is the Playdate SDK gets installed on another drive (e.g. `D:\`, `E:\`, etc.)
  - If you set a custom path, it's possible that you made a typo when setting your environment variable path - try setting it again
  - After every change to your environment variable, you'll need to close and re-open VSCode for it to pickup the change
- `Task configuration failed: Could not find the Playdate SDK. Please ensure that the PlaydateSDK is installed and the PLAYDATE_SDK_PATH environment variable is set`
  - This means that your `PLAYDATE_SDK_PATH` environment variable does not exist. Try setting it again, or look up how to set environment variables another way ("set environment variable windows" or "set permanent environment variable [Linux distro]")
- `No build task to run found` when trying to run the build task
  - Likely that you've opened the wrong folder - the folder should be the one containing the `.vscode`, `builds`, and `source` folders, not a parent to that folder
- `SDK Path Not Set` error on simulator
  - Your SDK installation might be on a different drive than your project. If your SDK was installed on your D:/ drive and your project is in your C:/ drive, try re-installing the SDK on your C:/ drive instead.
- Seeing system "Settings" page instead of demo app
  - Sometimes happens when running the first time when there's no configuration folder - closing the Simulator and building again should solve the issue most of the time
- `Task configuration failed` on Linux
  - It's possible your default shell is zsh instead of bash - check by going to VSCode, click "Terminal" -> "New Terminal" at the top, and typing and running `echo $0`. If it says `zsh`, then you need to add your environment variable to `.zshrc` instead of `.bashrc`

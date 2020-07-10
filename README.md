# FLOURISH
A custom tool for Renoise, used to create strums, flourishes, ripples, arpeggios, etc

![Flourish](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/flourishwindow.jpg)

# HOW TO USE
## Selecting a Line/Revealing the Flourish Window
+ Flourish uses the pattern edit cursor's position to select a line for processing (it does not use the box selection or playback position to specify lines/notes)\
![Processing](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/processing.jpg)


+ Use the keyboard shortcut or menu entries to select a line and open the Flourish window (there is also a "Reveal Window" menu entry/keyboard shortcut that will allow you to open the Flourish window without setting a new line to edit, allowing you to continue editing your currently selected line)\
![Tools Menu](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/toolsmenu.jpg)\
![Right Click Menu](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/rightclick.jpg)\
![Keyboard Shortcut](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/keyshort.jpg)\\

## Controls

![Flourish Window](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/flourish.jpg)
+ Move the Time slider (indicated by the ![clock](https://raw.githubusercontent.com/M-O-Marmalade/com.MOMarmalade.Flourish.xrnx/master/Bitmaps/clock.bmp) icon) to spread the notes over time
+ Move the Tension slider (indicated by the ![curve](https://raw.githubusercontent.com/M-O-Marmalade/com.MOMarmalade.Flourish.xrnx/master/Bitmaps/curve.bmp) icon) to change the distribution of the notes [NOT YET IMPLEMENTED]
+ Click the Non-Destructive button (indicated by the ![stilts](https://raw.githubusercontent.com/M-O-Marmalade/com.MOMarmalade.Flourish.xrnx/master/Bitmaps/stilts.bmp)/![steamroller](https://raw.githubusercontent.com/M-O-Marmalade/com.MOMarmalade.Flourish.xrnx/master/Bitmaps/steamroller.bmp) icon) to toggle Non-Destructive Mode on/off
+ Use the Quantization drop-down (indicated by the ![magnet](https://raw.githubusercontent.com/M-O-Marmalade/com.MOMarmalade.Flourish.xrnx/master/Bitmaps/magnet.bmp) icon) to set the snap/quantization amount [NOT YET IMPLEMENTED]
+ Use the "Set Line" button (or the keyboard shortcut/menu entries) to set a new line to be edited by Flourish
+ While the Flourish window is in focus, you can hold the [SPACEBAR] to preview the currently edited selection


# HOW TO INSTALL
1. **Download** the tool from this repository\
![Download](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/flourish1.jpg)


2. **Extract** the *"com.MOMarmalade.Flourish.xrnx-master"* folder from the .zip file\
![Extract](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/extract.jpg)


3. **Rename** the extracted folder to remove the *"-master"* from the end of the name\
![Rename](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/renameit.jpg)


4. **Drag and Drop** the renamed folder onto an open Renoise window to install the tool\
![Drag n' Drop](https://raw.githubusercontent.com/M-O-Marmalade/Pix/master/dragndrop.jpg)


...and it's ready to use! (The installation files can now be deleted)

## TO_DO
- Implement tension in strums (logarithmic distribution of notes)
- Add ability to strum to/from the first/last note in the line interchangeably
- Add quantization/snap functionality

# Augment-IT-for-Shot-Put
This is a project I made in collaboration with Maria Pérez , Ieva Seglina and Noah Pereira for the medical engineering project course in KTH Stockholm.
# Description
The technologies currently on the market for evaluating the quality of shot puts are expensive, hard to use and not intuitive. Therefore, the object of this study has been measuring the performance of shot put athletes, especially the acceleration and the gyroscope, in order to improve their training and make it more efficient and professional. Our solution is developing a Matlab application that uses an inertial measurement unit (IMU) placed in the dorsal hand as a method of detecting acceleration and rotation. The athletes will ideally record themselves with their own smartphones and the video will afterwards be visualized, processed and synchronized in Matlab together with the graphs obtained from the sensor data. Developing an application with accurate data and intuitive video during the shot put performance can help athletes improve and correct their flaws. 

Our final paper with detailed information of the project, a screen video running the App, the Matlab code and two example files to try out the App will be also attached. 
# Instructions
First, the shot put athlete user records simultaneously a video of the performance with a smartphone and an IMU sensor placed on the back of the hand. The data of  the sensor has to be recorded using the SmartGym app (https://github.com/MariahSabioni/SmartGym) and the video needs to be in mp4 format.
If you only want to try out the App, you can use the video (NOMBRE) and the sensor data (NOMBRE) that we already recorded from a Swedish male professional athlete in order to develop our project. 
When the user opens the Shot Put app, 5 windows will be displayed: introduction, variables, graphs, video and slider: 

-The first window only shows an introduction to the app and describes some basic instructions on how to use it.  

-In the second window, the user should firstly upload the file in json with the data. Then, he has to introduce by hand the ball weight (in kilograms) and then      click   the button “calculate variables” to get displayed the fourth parameters (peak force, impulse, peak rotation speed and peak velocity). 

-The third window shows some graphs. If the user clicks the “plot” button,  the combination of accelerometer and gyroscope values will be displayed together, as      well as the values of the velocity vs time. On the last plot the user has several buttons to select if he or she wants to plot the raw data of the accelerometer   values, the filtered data or both in the same graph.

-In the fourth window the user has to load the video recorded from the smartphone and then it will be reproduced simultaneously with the acceleration graph.          Therefore, the user will visualize at the same time the video and the data recorded by the sensor correlated in every second with the video. A red dot will be      moving throughout the acceleration graph at the same time the video is being displayed. 

-In the last window, the user can choose through a slider the exact frame of the video that he wants to observe on the acceleration graph and the frame will also    be displayed as an image of it.  
# Further work
Further data collection to other professional athletes is required to determine exactly how acceleration and gyroscope values affect the results of the calculated parameters (impulse, peak force, peak velocity, peak rotation speed). 

It was not possible to implement the Kalman filter although the data recorded is partially cleaned by applying an Exponentially-Weighted Moving Average (EWMA). Therefore, further work on how other filters clean the data should be done.

Another major improvement that could be made is modifying the code so that the application that is now only useful for shot put athletes is also effective for other sports like sledge hammer, discus and javelin throw.
In addition, other upgrades that can be made are to allow the user to choose the speed of the video displayed in the fourth window. 
Also, in our code we manually cut the start and end of the throw by finding the maximum acceleration peak and  assume that the video starts 2 seconds before the peak and ends 0.7 seconds after. Therefore, further work needs to be done to develop a code that synchronizes the video and the data automatically.

# Autors
Ihona Maria Correa de Cabo: github |
Noah Pereira:  github |
Maria Pérez Rodríguez:  github |
Ieva Seglina:  github |


classdef ShotPutAppFinal_v1 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        TabGroup                      matlab.ui.container.TabGroup
        IntroductionTab               matlab.ui.container.Tab
        AuthorsLabel                  matlab.ui.control.Label
        Autumnsemester2022Label       matlab.ui.control.Label
        MedicalengineeringprojectcourseLabel  matlab.ui.control.Label
        TextArea                      matlab.ui.control.TextArea
        AUGMENTITFORSHOTPUTLabel      matlab.ui.control.Label
        Image                         matlab.ui.control.Image
        VariablesTab                  matlab.ui.container.Tab
        PeakVelocity                  matlab.ui.control.NumericEditField
        PeakVelocitymsLabel           matlab.ui.control.Label
        PeakRotationalSpeed           matlab.ui.control.NumericEditField
        PeakRotationalSpeeddegsLabel  matlab.ui.control.Label
        Impulse                       matlab.ui.control.NumericEditField
        ImpulsekNsLabel               matlab.ui.control.Label
        PeakForce                     matlab.ui.control.NumericEditField
        PeakforceNLabel               matlab.ui.control.Label
        calculateButton               matlab.ui.control.Button
        FileNameEditField             matlab.ui.control.EditField
        FileNameEditFieldLabel        matlab.ui.control.Label
        LoadButton1                   matlab.ui.control.StateButton
        ball                          matlab.ui.control.NumericEditField
        BallweightkgEditFieldLabel    matlab.ui.control.Label
        GraphsTab                     matlab.ui.container.Tab
        PlotbothButton                matlab.ui.control.Button
        PlotfiltereddataButton        matlab.ui.control.Button
        PlotrawdataButton             matlab.ui.control.Button
        PlotButton                    matlab.ui.control.Button
        TotalAcceleration             matlab.ui.control.UIAxes
        LinearVelocity                matlab.ui.control.UIAxes
        TotAccAndTotAngVel            matlab.ui.control.UIAxes
        VideoTab                      matlab.ui.container.Tab
        VideoNameEditField            matlab.ui.control.EditField
        VideoNameEditFieldLabel       matlab.ui.control.Label
        LoadVideoButton               matlab.ui.control.Button
        Graph                         matlab.ui.control.UIAxes
        video                         matlab.ui.control.UIAxes
        SliderTab                     matlab.ui.container.Tab
        FrameSlider                   matlab.ui.control.Slider
        FrameSliderLabel              matlab.ui.control.Label
        graph2                        matlab.ui.control.UIAxes
        video2                        matlab.ui.control.UIAxes
        ContextMenu                   matlab.ui.container.ContextMenu
        Menu                          matlab.ui.container.Menu
        Menu2                         matlab.ui.container.Menu
    end

    
    properties (Access = private)
        file;
        Data;
        AccTotFiltDisplay;
        GyrTotDisplay;
        TotAccDisplay;
        AccTot;
        MOV;
        Acc4Video;
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: LoadButton1
        function LoadButton1ValueChanged(app, ~)

            % Allows user to load the .json data files
            
            app.file = uigetfile('*.json');
            app.FileNameEditField.Value = app.file;
            
            fid=fopen(app.file);
            raw=fread(fid,inf);
            str=char(raw');
            fclose(fid);
            app.Data=jsondecode(str);
            
            
            
            
        end

        % Button pushed function: calculateButton
        function calculateButtonButtonPushed(app, ~)
            %CALCULATE INTERESTING PARAMETERS:
            
            
            Frequency = 416; % Data was recorded at 416 Hz
            
            %The recorded data from the smart gym app has to be divided by 4 and 1000
            Acc_div = 4; 
            Gyr_div = 1000; 
            
            Acc = app.Data.imu.measurements.Acc; %Access the acceleration data
            Gyr = app.Data.imu.measurements.Gyr; %Access the gyroscope data
            
            AccData = (struct2cell(Acc));

            XAcc = cell2mat(AccData(8,1:end))';
            YAcc = cell2mat(AccData(9,1:end))';
            ZAcc = cell2mat(AccData(10,1:end))';

            AccX = XAcc/Acc_div; 
            AccY = YAcc/Acc_div;
            AccZ = ZAcc/Acc_div;


            GyrData = (struct2cell(Gyr));

            XGyr = cell2mat(GyrData(8,1:end))';
            YGyr = cell2mat(GyrData(9,1:end))';
            ZGyr = cell2mat(GyrData(10,1:end))';

            GyrX = XGyr/Gyr_div; 
            GyrY = YGyr/Gyr_div;
            GyrZ = ZGyr/Gyr_div;


            % To synchronise the video with the data the hand with the
            % sensor is hit to the leg to get peak acceleration value in Z
            % direction, this is defined as the starting point, and video
            % is manualy cut to this point.
            [~, PeakAccIndxZ] = max(AccZ); 

            Start = PeakAccIndxZ + 14; %Start is defined as the next frame from the video.

            AccX = AccX(Start:end);
            AccY = AccY(Start:end);
            AccZ = AccZ(Start:end);

            GyrX = GyrX(Start:end);
            GyrY = GyrY(Start:end);
            GyrZ = GyrZ(Start:end);

            
            % Total Acceleration and angular velocity values.
            app.AccTot = sqrt((AccX.^2)+(AccY.^2)+(AccZ.^2))-9.81;
            GyrTot = sqrt((GyrX.^2)+(GyrY.^2)+(GyrZ.^2));
            
            
            %Raw data is filtered with exponentially weighted moving average filter
            alpha = 0.75;
            AccEWMA = filter(alpha, [1 alpha-1], app.AccTot);
            
           
            %Actuall displayed data and calculated values are acquired. The
            %total peak acceleration is found and start time is set as 2
            %seconds before peak acceleration, end - 0.7 seconds after.
            %These times were found to be reliable across multiple shotput
            %throws.
            

            [PeakAcc, PeakAccIndx] = max(app.AccTot); %Peak acceleration

            DisplayTimeStart = 2 * Frequency;
            DisplayTimeEnd = 0.7 * Frequency;


            % Get data to display
            app.AccTotFiltDisplay = AccEWMA(PeakAccIndx-DisplayTimeStart:PeakAccIndx+DisplayTimeEnd);
            app.GyrTotDisplay = GyrTot(PeakAccIndx-DisplayTimeStart:PeakAccIndx+DisplayTimeEnd);
            app.TotAccDisplay = app.AccTot(PeakAccIndx-DisplayTimeStart:PeakAccIndx+DisplayTimeEnd);
      
            BallWeight = app.ball.Value;
            Force = app.AccTotFiltDisplay * BallWeight; % f = ma
            
            app.Impulse.Value = trapz(Force)/1000; %Integrate to get the impulse (force in kN*time)
         
            app.PeakForce.Value = BallWeight * PeakAcc; %Peak Force athlete produces
            
            
            GyrMaxCalc = GyrTot(PeakAccIndx-DisplayTimeStart:PeakAccIndx); %Assume that after the peak acceleration ball is thrown away 
            app.PeakRotationalSpeed.Value = max(GyrMaxCalc) * 180/pi; %Peak rotational speed
            
            
            Velocity = (cumtrapz(app.AccTotFiltDisplay)) * 0.001; % Velocity of the throw
            app.PeakVelocity.Value = max(Velocity); %Peak Velocity
            
        end

        % Button pushed function: PlotButton
        function PlotButtonPushed(app, ~)

           TimeInGraph = linspace(0,2.7,1124);
           app.AccTotFiltDisplay = transpose(app.AccTotFiltDisplay);
           app.GyrTotDisplay = transpose(app.GyrTotDisplay);
            
           hold(app.TotAccAndTotAngVel,'on')
            
           plot(app.TotAccAndTotAngVel,TimeInGraph,app.AccTotFiltDisplay)
           plot(app.TotAccAndTotAngVel,TimeInGraph,app.GyrTotDisplay)
           legend(app.TotAccAndTotAngVel,'Total acceleration (m/s^2)','Total angular velocity (rad/s)')
           hold(app.TotAccAndTotAngVel,'off')
            
           Velocity = (cumtrapz(app.AccTotFiltDisplay))*0.001; %Velocity of the movement
           plot(app.LinearVelocity,TimeInGraph,Velocity)
          
            
          
            
        end


        % Button pushed function: LoadVideoButton
        function LoadVideoButtonPushed2(app, ~)

            %Load the video file
            [file, path] = uigetfile('.mp4','Select Video File');
            app.VideoNameEditField.Value = [file,path];
            if isequal(file, 0)
                disp('User selected cancel');
            else
                videopath = fullfile(path, file);
                app.MOV = VideoReader(videopath);

            end


            Frequency = 416; 
            FrameRate = 30;
            [~, PeakAccIndx] = max(app.AccTot);
            PeakAccTime = PeakAccIndx / Frequency;

            DisplayTime = 2 * Frequency;
            FinDisplayTime = 0.7 * Frequency;

            app.AccTotFiltDisplay = app.AccTot(PeakAccIndx-DisplayTime:PeakAccIndx+FinDisplayTime,:);


            PeakVideoFrame = round(PeakAccTime * FrameRate);
            StartVideoFrame = PeakVideoFrame - (2 * FrameRate);
            EndVideoFrame = PeakVideoFrame + (0.7 * FrameRate);
            
            %% Play the video and data simultaneously


            %The code bellow either each 3rd or 4th data point to represent
            %the acceleration at the same time as the video is playing

            
            % Acceleration data is downsampled to 104Hz for better user
            % interface

            app.Acc4Video = downsample(app.AccTotFiltDisplay,4);


            TimeInGraph = linspace(0,2.7,281);
            
            plot(app.Graph,TimeInGraph,app.Acc4Video);
            hold (app.Graph,'on')
            h = scatter(TimeInGraph(1), app.Acc4Video(1),'parent',app.Graph,'red','filled'); 
            xlim(app.Graph,[0, 2.7])
            ylim(app.Graph,[min(app.Acc4Video), max(app.Acc4Video)])

            k = 2;
            a = true;
            b = false;

            for i = StartVideoFrame:EndVideoFrame
                img = read(app.MOV,i);
                image(img,'parent',app.video); 
                app.video.XLim = [0 width(img)];
                app.video.YLim = [0 height(img)];
                pause(0.01);
                h.XData = TimeInGraph(k);
                h.YData = app.Acc4Video(k);

                if a == true
                    k = k+3;
                    a = false;
                    b = true;

                elseif b == true
                    k = k+4;
                    a = true;
                    b = false;
                end
            end
        end



        % Button pushed function: PlotrawdataButton
        % Plots raw accelerometer values

        function PlotrawdataButtonPushed(app, ~)
            
           TimeInGraph = linspace(0,2.7,1124);
           app.TotAccDisplay = transpose(app.TotAccDisplay);
           
           plot(app.TotalAcceleration,TimeInGraph,app.TotAccDisplay)
           
        end

        % Button pushed function: PlotfiltereddataButton
        % Plots filtered accelerometer values with EWMA filter

        function PlotfiltereddataButtonPushed(app, ~)

           TimeInGraph = linspace(0,2.7,1124);
          app.AccTotFiltDisplay = transpose(app.AccTotFiltDisplay);
           
           plot(app.TotalAcceleration,TimeInGraph,app.AccTotFiltDisplay)

        end

        % Button pushed function: PlotbothButton
        % Plots both previous acceleration values

        function PlotbothButtonPushed(app, ~)

           TimeInGraph = linspace(0,2.7,1124);
           app.AccTotFiltDisplay = transpose(app.AccTotFiltDisplay);
           app.TotAccDisplay = transpose(app.TotAccDisplay);
            
           hold(app.TotalAcceleration,'on')
            
           plot(app.TotalAcceleration,TimeInGraph,app.AccTotFiltDisplay)
           plot(app.TotalAcceleration,TimeInGraph,app.TotAccDisplay)
           legend(app.TotalAcceleration,'Filtered data acceleration (m/s^2)','Raw data acceleration (m/s^2)')
           hold(app.TotalAcceleration,'off')

        end


        % Value changed function: FrameSlider

        function FrameSliderValueChanged(app, ~)

            % Cretate a slider, that allow the user to see chosen time
            % frame and the representing acceleration value in the graph
            % simoltaneously.
            
            value = round(app.FrameSlider.Value); % User chooses the video frame
            
            Frequency=416; 
            FrameRate=30;
            [~, PeakAccIndx] = max(app.AccTot);
            PeakAccTime = PeakAccIndx / Frequency;

            DisplayTime = 2 * Frequency;
            FinDisplayTime = 0.7 * Frequency;

            app.AccTotFiltDisplay = app.AccTot(PeakAccIndx-DisplayTime:PeakAccIndx+FinDisplayTime,:);


            PeakVideoFrame = round(PeakAccTime * FrameRate);
            StartVideoFrame = PeakVideoFrame - (2 * FrameRate);
            vidFrame = value + StartVideoFrame; % Actual video frame to represent 
            
            img = read(app.MOV,vidFrame);
            image(img,'parent',app.video2);
            app.video2.XLim = [0 width(img)];
            app.video2.YLim = [0 height(img)];
           
             % The acceleration data and video does not have the same
             % frequency, so it is multiplied by 3.48, to represent the
             % accceleration value corresponding to the video frame.
            AccValue = round(3.48 * value);
            
            
            AccelerationInThisTime=app.Acc4Video(AccValue);
            
            
            plot(app.graph2,app.Acc4Video);
            hold(app.graph2,'on')
            scatter(app.graph2,AccValue,AccelerationInThisTime,'filled');
            xlim(app.graph2,[0, length(app.Acc4Video)])
            ylim(app.graph2,[min(app.Acc4Video), max(app.Acc4Video)])
            
            
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 627 480];

            % Create IntroductionTab
            app.IntroductionTab = uitab(app.TabGroup);
            app.IntroductionTab.Title = 'Introduction';
            app.IntroductionTab.BackgroundColor = [0.702 0.7686 0.9098];

            % Create Image
            app.Image = uiimage(app.IntroductionTab);
            app.Image.Position = [252 199 135 163];
            app.Image.ImageSource = 'pngwing.com.png';

            % Create AUGMENTITFORSHOTPUTLabel
            app.AUGMENTITFORSHOTPUTLabel = uilabel(app.IntroductionTab);
            app.AUGMENTITFORSHOTPUTLabel.HorizontalAlignment = 'center';
            app.AUGMENTITFORSHOTPUTLabel.FontName = 'Palatino Linotype';
            app.AUGMENTITFORSHOTPUTLabel.FontSize = 30;
            app.AUGMENTITFORSHOTPUTLabel.FontWeight = 'bold';
            app.AUGMENTITFORSHOTPUTLabel.Position = [75 310 453 84];
            app.AUGMENTITFORSHOTPUTLabel.Text = 'AUGMENT IT FOR SHOT PUT';

            % Create TextArea
            app.TextArea = uitextarea(app.IntroductionTab);
            app.TextArea.FontName = 'Arial';
            app.TextArea.FontSize = 11;
            app.TextArea.BackgroundColor = [0.902 0.9059 0.9882];
            app.TextArea.Position = [75 87 476 124];
            app.TextArea.Value = {['The aim of this App is to provide ' ...
                'a useful tool for shot put athletes in order to help them improve ' ...
                'their skills in this sport.' ...
                ' Our solution uses an inertial measurement unit (IMU) ' ...
                'placed on the back of the athlete''s hand as a method of detecting ' ...
                'acceleration and rotation. ']; ''; ['The athlete has to record himself' ...
                ' with his smartphone and upload both the data of the sensor' ...
                ' and the video (in mp4 format) in the App.']; ''; ['Let the' ...
                ' improvement begin!']};

            % Create MedicalengineeringprojectcourseLabel
            app.MedicalengineeringprojectcourseLabel = uilabel(app.IntroductionTab);
            app.MedicalengineeringprojectcourseLabel.FontName = 'Arial';
            app.MedicalengineeringprojectcourseLabel.FontSize = 10;
            app.MedicalengineeringprojectcourseLabel.Position = [449 414 160 22];
            app.MedicalengineeringprojectcourseLabel.Text = 'Medical engineering project course';

            % Create Autumnsemester2022Label
            app.Autumnsemester2022Label = uilabel(app.IntroductionTab);
            app.Autumnsemester2022Label.FontName = 'Arial';
            app.Autumnsemester2022Label.FontSize = 10;
            app.Autumnsemester2022Label.Position = [500 393 109 22];
            app.Autumnsemester2022Label.Text = 'Autumn semester 2022';

            % Create AuthorsLabel
            app.AuthorsLabel = uilabel(app.IntroductionTab);
            app.AuthorsLabel.FontSize = 9;
            app.AuthorsLabel.Position = [79 43 371 22];
            app.AuthorsLabel.Text = {'Authors: Ieva Seglina, Ihona Maria Correa de Cabo, Maria Pérez Rodriguez, Noah Pereira'; ''};

            % Create VariablesTab
            app.VariablesTab = uitab(app.TabGroup);
            app.VariablesTab.Title = 'Variables';
            app.VariablesTab.BackgroundColor = [0.702 0.7686 0.9098];

            % Create BallweightkgEditFieldLabel
            app.BallweightkgEditFieldLabel = uilabel(app.VariablesTab);
            app.BallweightkgEditFieldLabel.HorizontalAlignment = 'right';
            app.BallweightkgEditFieldLabel.Position = [63 324 88 22];
            app.BallweightkgEditFieldLabel.Text = 'Ball weight (kg)';

            % Create ball
            app.ball = uieditfield(app.VariablesTab, 'numeric');
            app.ball.ValueChangedFcn = createCallbackFcn(app, @ballValueChanged, true);
            app.ball.Position = [166 321 42 27];

            % Create LoadButton1
            app.LoadButton1 = uibutton(app.VariablesTab, 'state');
            app.LoadButton1.ValueChangedFcn = createCallbackFcn(app, @LoadButton1ValueChanged, true);
            app.LoadButton1.Text = 'Load';
            app.LoadButton1.Position = [62 380 113 35];

            % Create FileNameEditFieldLabel
            app.FileNameEditFieldLabel = uilabel(app.VariablesTab);
            app.FileNameEditFieldLabel.HorizontalAlignment = 'right';
            app.FileNameEditFieldLabel.Position = [344 386 60 22];
            app.FileNameEditFieldLabel.Text = 'File Name';

            % Create FileNameEditField
            app.FileNameEditField = uieditfield(app.VariablesTab, 'text');
            app.FileNameEditField.Position = [419 372 147 50];

            % Create calculateButton
            app.calculateButton = uibutton(app.VariablesTab, 'push');
            app.calculateButton.ButtonPushedFcn = createCallbackFcn(app, @calculateButtonButtonPushed, true);
            app.calculateButton.Position = [75 257 121 22];
            app.calculateButton.Text = 'Calculate Variables ';

            % Create PeakforceNLabel
            app.PeakforceNLabel = uilabel(app.VariablesTab);
            app.PeakforceNLabel.HorizontalAlignment = 'right';
            app.PeakforceNLabel.Position = [249 257 83 22];
            app.PeakforceNLabel.Text = 'Peak force (N)';

            % Create PeakForce
            app.PeakForce = uieditfield(app.VariablesTab, 'numeric');
            app.PeakForce.Position = [347 257 100 22];

            % Create ImpulsekNsLabel
            app.ImpulsekNsLabel = uilabel(app.VariablesTab);
            app.ImpulsekNsLabel.HorizontalAlignment = 'right';
            app.ImpulsekNsLabel.Position = [246 217 84 22];
            app.ImpulsekNsLabel.Text = 'Impulse (kN*s)';

            % Create Impulse
            app.Impulse = uieditfield(app.VariablesTab, 'numeric');
            app.Impulse.Position = [345 217 100 22];

            % Create PeakRotationalSpeeddegsLabel
            app.PeakRotationalSpeeddegsLabel = uilabel(app.VariablesTab);
            app.PeakRotationalSpeeddegsLabel.HorizontalAlignment = 'right';
            app.PeakRotationalSpeeddegsLabel.Position = [164 178 169 22];
            app.PeakRotationalSpeeddegsLabel.Text = 'Peak Rotational Speed (deg/s)';

            % Create PeakRotationalSpeed
            app.PeakRotationalSpeed = uieditfield(app.VariablesTab, 'numeric');
            app.PeakRotationalSpeed.Position = [348 178 100 22];

            % Create PeakVelocitymsLabel
            app.PeakVelocitymsLabel = uilabel(app.VariablesTab);
            app.PeakVelocitymsLabel.HorizontalAlignment = 'right';
            app.PeakVelocitymsLabel.Position = [224 138 108 22];
            app.PeakVelocitymsLabel.Text = 'Peak Velocity (m/s)';

            % Create PeakVelocity
            app.PeakVelocity = uieditfield(app.VariablesTab, 'numeric');
            app.PeakVelocity.Position = [347 138 100 22];

            % Create GraphsTab
            app.GraphsTab = uitab(app.TabGroup);
            app.GraphsTab.Title = 'Graphs';
            app.GraphsTab.BackgroundColor = [0.702 0.7686 0.9098];

            % Create TotAccAndTotAngVel
            app.TotAccAndTotAngVel = uiaxes(app.GraphsTab);
            title(app.TotAccAndTotAngVel, 'Total Acceleration and Angular Velocity')
            xlabel(app.TotAccAndTotAngVel, 'Time (s)')
            ylabel(app.TotAccAndTotAngVel, '')
            zlabel(app.TotAccAndTotAngVel, 'Z')
            app.TotAccAndTotAngVel.XLim = [0 2.7];
            app.TotAccAndTotAngVel.Position = [23 257 291 179];

            % Create LinearVelocity
            app.LinearVelocity = uiaxes(app.GraphsTab);
            title(app.LinearVelocity, 'Linear Velocity')
            xlabel(app.LinearVelocity, 'Time (s)')
            ylabel(app.LinearVelocity, 'Velocity (m/s)')
            zlabel(app.LinearVelocity, 'Z')
            app.LinearVelocity.XLim = [0 2.7];
            app.LinearVelocity.Position = [345 264 261 165];

            % Create TotalAcceleration
            app.TotalAcceleration = uiaxes(app.GraphsTab);
            title(app.TotalAcceleration, 'Total Acceleration')
            xlabel(app.TotalAcceleration, 'Time (s)')
            ylabel(app.TotalAcceleration, 'Acceleration (m/s^2)')
            zlabel(app.TotalAcceleration, 'Z')
            app.TotalAcceleration.XLim = [0 2.7];
            app.TotalAcceleration.Position = [37 15 300 185];

            % Create PlotButton
            app.PlotButton = uibutton(app.GraphsTab, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Position = [288 230 80 21];
            app.PlotButton.Text = 'Plot';

            % Create PlotrawdataButton
            app.PlotrawdataButton = uibutton(app.GraphsTab, 'push');
            app.PlotrawdataButton.ButtonPushedFcn = createCallbackFcn(app, @PlotrawdataButtonPushed, true);
            app.PlotrawdataButton.Position = [383 138 100 22];
            app.PlotrawdataButton.Text = 'Plot Raw data';

            % Create PlotfiltereddataButton
            app.PlotfiltereddataButton = uibutton(app.GraphsTab, 'push');
            app.PlotfiltereddataButton.ButtonPushedFcn = createCallbackFcn(app, @PlotfiltereddataButtonPushed, true);
            app.PlotfiltereddataButton.Position = [383 105 102 22];
            app.PlotfiltereddataButton.Text = 'Plot Filtered data';

            % Create PlotbothButton
            app.PlotbothButton = uibutton(app.GraphsTab, 'push');
            app.PlotbothButton.ButtonPushedFcn = createCallbackFcn(app, @PlotbothButtonPushed, true);
            app.PlotbothButton.Position = [386 74 100 22];
            app.PlotbothButton.Text = 'Plot Both';

            % Create VideoTab
            app.VideoTab = uitab(app.TabGroup);
            app.VideoTab.Title = 'Video';
            app.VideoTab.BackgroundColor = [0.702 0.7686 0.9098];


            % Create video
            app.video = uiaxes(app.VideoTab);
            title(app.video, 'Video')
            zlabel(app.video, 'Z')
            app.video.XTick = [];
            app.video.YTick = [];
            app.video.YTickLabel = '';
            app.video.ButtonDownFcn = createCallbackFcn(app, @videoButtonDown, true);
            app.video.Position = [63 238 249 198];


            % Create Graph
            app.Graph = uiaxes(app.VideoTab);
            title(app.Graph, 'Total Acceleration')
            xlabel(app.Graph, 'Time (s)')
            ylabel(app.Graph, 'Acceleration (m/s^2)')
            zlabel(app.Graph, 'Z')
            app.Graph.ButtonDownFcn = createCallbackFcn(app, @GraphButtonDown, true);
            app.Graph.Position = [27 9 310 196];

            % Create LoadVideoButton
            app.LoadVideoButton = uibutton(app.VideoTab, 'push');
            app.LoadVideoButton.ButtonPushedFcn = createCallbackFcn(app, @LoadVideoButtonPushed2, true);
            app.LoadVideoButton.Position = [485 236 100 22];
            app.LoadVideoButton.Text = 'Load Video';

            % Create VideoNameEditFieldLabel
            app.VideoNameEditFieldLabel = uilabel(app.VideoTab);
            app.VideoNameEditFieldLabel.HorizontalAlignment = 'right';
            app.VideoNameEditFieldLabel.Position = [400 189 71 22];
            app.VideoNameEditFieldLabel.Text = 'Video Name';

            % Create VideoNameEditField
            app.VideoNameEditField = uieditfield(app.VideoTab, 'text');
            app.VideoNameEditField.Position = [486 189 100 22];

            % Create SliderTab
            app.SliderTab = uitab(app.TabGroup);
            app.SliderTab.Title = 'Slider';
            app.SliderTab.BackgroundColor = [0.702 0.7686 0.9098];

            % Create video2
            app.video2 = uiaxes(app.SliderTab);
            title(app.video2, 'Video')
            zlabel(app.video2, 'Z')
            app.video2.XTick = [];
            app.video2.XTickLabel = '';
            app.video2.YTick = [];
            app.video2.Position = [79 257 271 185];


            % Create graph2
            app.graph2 = uiaxes(app.SliderTab);
            title(app.graph2, 'Total Acceleration')
            xlabel(app.graph2, '')
            ylabel(app.graph2, 'Acceleration data (m/s^2)')
            zlabel(app.graph2, 'Z')
            app.graph2.Position = [62 46 300 185];

            % Create FrameSliderLabel
            app.FrameSliderLabel = uilabel(app.SliderTab);
            app.FrameSliderLabel.HorizontalAlignment = 'right';
            app.FrameSliderLabel.Position = [385 147 40 22];
            app.FrameSliderLabel.Text = ' Video Frame';

            % Create FrameSlider
            app.FrameSlider = uislider(app.SliderTab);
            app.FrameSlider.Limits = [0 75];
            app.FrameSlider.ValueChangedFcn = createCallbackFcn(app, @FrameSliderValueChanged, true);
            app.FrameSlider.Position = [446 156 150 3];

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create Menu
            app.Menu = uimenu(app.ContextMenu);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.ContextMenu);
            app.Menu2.Text = 'Menu2';
            
            % Assign app.ContextMenu
            app.TotAccAndTotAngVel.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ShotPutAppFinal_v1

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
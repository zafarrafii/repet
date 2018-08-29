function repet_gui
% REPET_GUI REpeating Pattern Extraction Technique (REPET) graphical user interface (GUI).
%
%   Toolbar:
%       Open Mixture:               Open mixture file (.wav or .mp3)
%       Play Mixture:               Play/stop selected mixture audio
%       Select:                     Select/deselect on signal axes (left/right mouse click)
%       Zoom:                       Zoom in/out on any axes (left/right mouse click)
%       Pan:                        Pan on any axes
%       REPET:                      Process selected mixture using REPET
%       Save Background:            Save background estimate of selected mixture in WAVE file
%       Play Background:            Play/stop background audio of selected mixture
%       Save Foreground:            Save foreground estimate of selected mixture in WAVE file
%       Play Foreground:            Play/stop foreground audio of selected mixture
%   Mixture axes:
%       Mixture signal axes:        Display mixture signal
%       Mixture spectrogram axes:   Display mixture spectrogram
%       Beat spectrum axes:         Display beat spectrum of selected mixture
%       
%       Period slider/edit:     Modify repeating period (in seconds)
%       Hardness slider/edit:   Modify masking hardness (in [0,1])
%           Turns soft time-frequency mask into binary time-frequency mask
%           The closer to 0, the softer the mask, the less separation artifacts (0 = original soft mask)
%           The closer to 1, the harder the mask, the less source interference (1 = full binary mask)
%       Threshold slider/edit:  Modify masking threshold (in [0,1])
%           Defines pivot value around which the energy will be spread apart (when hardness > 0)
%           The closer to 0, the more energy for the background, the less interference in the foreground
%           The closer to 1, the less energy for the background, the less interference from the foreground
%
%   Background and foreground axes:
%       Background signal axes:         Display background signal of selected mixture
%       Background spectrogram axes:    Display background spectrogram of selected mixture
%       Foreground signal axes:         Display foreground signal of selected mixture
%       Foreground spectrogram axes:    Display foreground spectrogram of selected mixture
%
%   See also http://zafarrafii.com/#REPET
% 
%   References:
%       Zafar Rafii, Antoine Liutkus, and Bryan Pardo. "REPET for 
%       Background/Foreground Separation in Audio," Blind Source 
%       Separation, chapter 14, pages 395-411, Springer Berlin Heidelberg, 
%       2014.
%       
%       Zafar Rafii and Bryan Pardo. "Audio Separation System and Method," 
%       US 20130064379 A1, March 2013.
%   
%       Zafar Rafii and Bryan Pardo. "REpeating Pattern Extraction 
%       Technique (REPET): A Simple Method for Music/Voice Separation," 
%       IEEE Transactions on Audio, Speech, and Language Processing, volume 
%       21, number 1, pages 71-82, January, 2013.
%       
%       Zafar Rafii and Bryan Pardo. "A Simple Music/Voice Separation 
%       Method based on the Extraction of the Repeating Musical Structure," 
%       36th International Conference on Acoustics, Speech and Signal 
%       Processing, Prague, Czech Republic, May 22-27, 2011.
%   
%   Author:
%       Zafar Rafii
%       zafarrafii@gmail.com
%       http://zafarrafii.com
%       https://github.com/zafarrafii
%       https://www.linkedin.com/in/zafarrafii/
%       08/28/18

% Get screen size
screen_size = get(0,'ScreenSize');

% Create figure window
figure_object = figure( ...
    'Visible','off', ...
    'Position',[screen_size(3:4)/4+1,screen_size(3:4)/2], ...
    'Name','REPET GUI', ...
    'NumberTitle','off', ...
    'MenuBar','none');

% Create toolbar on figure
toolbar_object = uitoolbar(figure_object);

% Create open and play toggle buttons on toolbar
openmixture_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open Mixture', ...
    'Enable','on', ...
    'ClickedCallback',@openmixtureclickedcallback);
playmixture_toggle = uitoggletool(toolbar_object, ...
    'CData',playicon, ...
    'TooltipString','Play Mixture', ...
    'Enable','off');

% Create pointer, zoom, and hand toggle buttons on toolbar
select_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off', ...
    'ClickedCallBack',@selectclickedcallback);
zoom_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off',...
    'ClickedCallBack',@zoomclickedcallback);
pan_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off',...
    'ClickedCallBack',@panclickedcallback);

% Create repet toggle button on toolbar
repet_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',repeticon, ...
    'TooltipString','REPET', ...
    'Enable','off');

% Create save and play background toggle buttons on toolbar
savebackground_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save Background', ...
    'Enable','off');
playbackground_toggle = uitoggletool(toolbar_object, ...
    'CData',playicon, ...
    'TooltipString','Play Background', ...
    'Enable','off');

% Create save and play foreground toggle buttons on toolbar
saveforeground_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('file_save.png'), ...
    'TooltipString','Save Foreground', ...
    'Enable','off');
playforeground_toggle = uitoggletool(toolbar_object, ...
    'CData',playicon, ...
    'TooltipString','Play Foreground', ...
    'Enable','off');

% Create mixture signal, mixture spectrogram, and beat spectrum axes
mixturesignal_axes = axes( ...
    'OuterPosition',[0,0.9,0.5,0.1], ...
    'Visible','off');
mixturespectrogram_axes = axes( ...
    'OuterPosition',[0,0.5,0.5,0.4], ...
    'Visible','off');
beatspectrum_axes = axes( ...
    'OuterPosition',[0,0.3,0.5,0.2], ...
    'Visible','off');

% Create background signal and spectrogram axes
backgroundsignal_axes = axes( ...
    'OuterPosition',[0.5,0.9,0.5,0.1], ...
    'Visible','off');
backgroundspectrogram_axes = axes( ...
    'OuterPosition',[0.5,0.5,0.5,0.4], ...
    'Visible','off');

% Create foreground wave and spectrogram axes
foregroundsignal_axes = axes( ...
    'OuterPosition',[0.5,0.4,0.5,0.1], ...
    'Visible','off');
foregroundspectrogram_axes = axes( ...
    'OuterPosition',[0.5,0,0.5,0.4], ...
    'Visible','off');

% Synchronize the x-axis limits of all the axes but beatspectrum_axes
linkaxes([mixturesignal_axes,mixturespectrogram_axes,...
    backgroundsignal_axes,backgroundspectrogram_axes, ...
    foregroundsignal_axes,foregroundspectrogram_axes],'x')

% Change the pointer when the mouse moves over an audio signal or beat 
% spectrum axes
enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
iptSetPointerBehavior(mixturesignal_axes,enterFcn);
iptSetPointerBehavior(beatspectrum_axes,enterFcn);
iptSetPointerBehavior(backgroundsignal_axes,enterFcn);
iptSetPointerBehavior(foregroundsignal_axes,enterFcn);
iptPointerManager(figure_object);

% Make the figure visible
figure_object.Visible = 'on';
    
    % Clicked callback function for the open mixture toggle button
    function openmixtureclickedcallback(~,~)
        
        % Change toggle button state to off
        openmixture_toggle.State = 'off';
        
        % Open file selection dialog box; return if cancel
        [mixture_name,mixture_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(mixture_name,0)
            return
        end
        
        % Build full file name
        mixture_file = fullfile(mixture_path,mixture_name);

        % Read audio file and return sample rate in Hz
        [mixture_signal,sample_rate] = audioread(mixture_file);
        
        % Number of samples and channels
        [number_samples,number_channels] = size(mixture_signal);

        % Window length in samples (audio stationary around 40 ms and power 
        % of 2 for fast FFT and constant overlap-add)
        window_length = 2.^nextpow2(0.04*sample_rate);

        % Window function ('periodic' Hamming window for constant 
        % overlap-add)
        window_function = hamming(window_length,'periodic');

        % Step length (half the (even) window length for constant 
        % overlap-add)
        step_length = window_length/2;

        % Number of time frames
        number_times = ceil((window_length-step_length+number_samples)/step_length);

        % Short-time Fourier transform STFT) for every channel
        mixture_stft = zeros(window_length,number_times,number_channels);
        for channel_index = 1:number_channels
            mixture_stft(:,:,channel_index) ...
                = stft(mixture_signal(:,channel_index),window_function,step_length);
        end
        
        % Magnitude spectrogram (with DC component and without mirrored
        % frequencies)
        mixture_spectrogram = abs(mixture_stft(1:window_length/2+1,:,:));
        
        % Plot the mixture signal and make it unable to capture mouse
        % clicks
        plot(mixturesignal_axes, ...
            1/sample_rate:1/sample_rate:number_samples/sample_rate,mixture_signal, ...
            'PickableParts','none');
        
        % Update the mixture signal axes properties
        mixturesignal_axes.XLim = [1,number_samples]/sample_rate;
        mixturesignal_axes.YLim = [-1,1];
        mixturesignal_axes.XGrid = 'on';
        mixturesignal_axes.Title.String = mixture_name;
        mixturesignal_axes.Title.Interpreter = 'None';
        mixturesignal_axes.XLabel.String = 'Time (s)';
        mixturesignal_axes.Layer = 'top';
        
        % Display the mixture spectrogram (in dB, averaged over the 
        % channels)
        imagesc(mixturespectrogram_axes, ...
            [1,number_times]/number_times*number_samples/sample_rate, ...
            [1,window_length/2]/window_length*sample_rate, ...
            db(mean(mixture_spectrogram(2:end,:),3)))
        
        % Update the mixture spectrogram axes properties
        mixturespectrogram_axes.Colormap = jet;
        mixturespectrogram_axes.YDir = 'normal';
        mixturespectrogram_axes.XGrid = 'on';
        mixturespectrogram_axes.Title.String = 'Audio Spectrogram';
        mixturespectrogram_axes.XLabel.String = 'Time (s)';
        mixturespectrogram_axes.YLabel.String = 'Frequency (Hz)';
        
        % Create object for playing audio
        mixture_player = audioplayer(mixture_signal,sample_rate);
        
        % Store the sample range in the user data of the audio player
        mixture_player.UserData = [1,number_samples];
        
        % Add close request callback function to the figure object
        figure_object.CloseRequestFcn = {@figurecloserequestfcn,mixture_player};
        
        % Add clicked callback function to the play mixture toogle button
        playmixture_toggle.ClickedCallback = {@playaudioclickedcallback,mixture_player};
        
        % Set a play line and a select line on the mixture signal axes 
        % using the mixture player
        playline(mixturesignal_axes,mixture_player,playmixture_toggle);
        selectline(mixturesignal_axes,mixture_player)
        
        % Add clicked callback function to the repet toogle button
        repet_toggle.ClickedCallback = @repetclickedcallback;
        
        % Enable the play mixture, select, zoom, pan, and repet toggle 
        % buttons
        playmixture_toggle.Enable = 'on';
        select_toggle.Enable = 'on';
        zoom_toggle.Enable = 'on';
        pan_toggle.Enable = 'on';
        repet_toggle.Enable = 'on';
        
        % Change the select toggle button states to on
        select_toggle.State = 'on';
        
        % Clicked callback function for the repet toggle button
        function repetclickedcallback(~,~)
            
            % Change the repet toggle button state to off
            repet_toggle.State = 'off';
            
            % Get the sample range of the mixture player from its user data
            sample_range = mixture_player.UserData;
            
            % Time range in time frames
            time_range = [floor((window_length-step_length+sample_range)/step_length), ...
                ceil((window_length-step_length+sample_range)/step_length)];
            
            % Beat spectrum of the spectrograms averaged over the channels
            % (squared to emphasize peaks of periodicitiy)
            beat_spectrum = beatspectrum(mean(mixture_spectrogram(:,time_range(1):time_range(2)),3).^2);
            
            % Normalize the beat spectrum by lag 0
            beat_spectrum = beat_spectrum/beat_spectrum(1);
            
            % Period range in seconds for the beat spectrum (can be
            % changed)
            period_range = [1,10];
            
            % Period range in time frames
            period_range = round(period_range*sample_rate/step_length);
            
            % Repeating period in time frames given the period range
            repeating_period = periods(beat_spectrum,period_range);
            
            % Plot the beat spectrum and make it unable to capture mouse
            % clicks
            plot(beatspectrum_axes, ...
                (0:1/number_times*number_samples/sample_rate:(time_range(2)-time_range(1))/number_times*number_samples/sample_rate), ...
                beat_spectrum,'PickableParts','none')
            
            % Update the beat spectrum axes properties
            beatspectrum_axes.XLim = [0,sample_range(2)-sample_range(1)]/sample_rate;
            beatspectrum_axes.YLim = [0,1];
            beatspectrum_axes.XGrid = 'on';
            beatspectrum_axes.XMinorGrid = 'on';
            beatspectrum_axes.Title.String = 'Beat Spectrum';
            beatspectrum_axes.XLabel.String = 'Lag (s)';
            beatspectrum_axes.Layer = 'top';
            
            %HERE!!!
            
            %             % Create the beat lines on the beat spectrum axes
            %             beatlines((repeating_period-1)/number_times*number_samples/sample_rate, ...
            %                 length(beat_spectrum)/number_times*number_samples/sample_rate,beatspectrum_axes);
            
            
            % Beat spectrum length
            beatspectrum_length = length(beat_spectrum)
            number_samples
            
            % Initialize the beat lines as an array for graphic objects
            number_lines = floor(beatspectrum_length/(repeating_period-1));
            beat_lines = gobjects(number_lines,1);
            
            
%             % Set the beat lines on the beat spectrum axes
%             function beat_lines = beatlines
%                 
%                 % Beat spectrum length
%                 beatspectrum_length = length(beat_spectrum);
%                 
%                 % Initialize the beat lines as an array for graphic objects
%                 number_lines = floor(beatspectrum_length/(repeating_period-1));
%                 beat_lines = gobjects(number_lines,1);
%                 
%                 % Create the main beat line and the other dotted lines on 
%                 % the beat spectrum axes
%                 beat_lines(1) = line(beatspectrum_axes, ...
%                     (repeating_period-1)/number_times*number_samples/sample_rate*[1,1],[-1,1], ...
%                     'Color','r');
%                 for line_index = 2:number_lines
%                     beat_lines(line_index) = line(beatspectrum_axes, ...
%                         (repeating_period-1)/number_times*number_samples/sample_rate*line_index*[1,1],[-1,1], ...
%                         'Color','r','LineStyle',':');
%                 end
%                 
%                 % Current figure handle
%                 figure_object = gcf;
%                 
%                 % Change the pointer to a hand when the mouse moves over the main line
%                 enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
%                 iptSetPointerBehavior(beat_lines(1),enterFcn);
%                 iptPointerManager(figure_object);
%                 
%                 % Period range for the beat spectrum in seconds
%                 beat_range = [1,floor(beatspectrum_length/3)]/number_times*number_samples/sample_rate;
%                 
%                 % Add mouse-click callback functions to the main line
%                 beat_lines(1).ButtonDownFcn = @beatlinebuttondownfcn;
%                 
%                 % Mouse-click callback function for the main line
%                 function beatlinebuttondownfcn(~,~)
%                     
%                     % Mouse selection type
%                     selection_type = figure_object.SelectionType;
%                     
%                     % If not click left mouse button, return
%                     if ~strcmp(selection_type,'normal')
%                         return
%                     end
%                     
%                     % Change the pointer to a hand when the mouse moves 
%                     % over the beat spectrum axes and the figure object
%                     enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
%                     iptSetPointerBehavior(beatspectrum_axes,enterFcn);
%                     iptSetPointerBehavior(figure_object,enterFcn);
%                     iptPointerManager(figure_object);
%                     
%                     % Add window button motion and up callback functions to the figure
%                     figure_object.WindowButtonMotionFcn = @figurewindowbuttonmotionfcn;
%                     figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
%                     
%                 end
%                 
%                 % Window button motion callback function for the figure
%                 function figurewindowbuttonmotionfcn(~,~)
%                     
%                     % Location of the mouse pointer
%                     current_point = beatspectrum_axes.CurrentPoint;
%                     
%                     % If the current point is out of the beat spectrum x-axis limits,
%                     % change it into the x-axis limits
%                     if current_point(1,1) < period_range(1)
%                         current_point(1,1) = period_range(1);
%                     elseif current_point(1,1) > period_range(2)
%                         current_point(1,1) = period_range(2);
%                     end
%                     
%                     % Delete the beat lines
%                     delete(beat_lines)
%                     
%                     % Create the main beat line and the other dotted lines 
%                     % on the beat spectrum axes
%                     beat_lines(1) = line(beatspectrum_axes, ...
%                         current_point(1,1)*[1,1],[-1,1], ...
%                         'Color','r');
%                     for line_index = 2:number_lines %#ok<*FXUP>
%                         beat_lines(line_index) = line(beatspectrum_axes, ...
%                             current_point(1,1)*line_index*[1,1],[-1,1], ...
%                             'Color','r','LineStyle',':');
%                     end
%                     
%                 end
%                 
%                 % Window button up callback function for the figure
%                 function figurewindowbuttonupfcn(~,~)
%                     
%                     % Change the pointer to a hand, an ibeam, and an arrow when the
%                     % mouse moves over the main line, the beat spectrum axes and the
%                     % figure object, respectively
%                     enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
%                     iptSetPointerBehavior(beat_lines(1),enterFcn);
%                     iptPointerManager(figure_object);
%                     enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
%                     iptSetPointerBehavior(beatspectrum_axes,enterFcn);
%                     iptPointerManager(figure_object);
%                     enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','arrow');
%                     iptSetPointerBehavior(figure_object,enterFcn);
%                     iptPointerManager(figure_object);
%                     
%                     % Add mouse-click callback functions to the main line
%                     beat_lines(1).ButtonDownFcn = @beatlinebuttondownfcn;
%                     
%                     % Remove the window button motion and up callback functions of
%                     % the figure
%                     figure_object.WindowButtonMotionFcn = '';
%                     figure_object.WindowButtonUpFcn = '';
%                     
%                 end
%                 
%             end

        end
        
    end

    % Clicked callback function for the select toggle button
    function selectclickedcallback(~,~)
        
        % Keep the select toggle button state to on and change the zoom and 
        % pan toggle button states to off
        select_toggle.State = 'on';
        zoom_toggle.State = 'off';
        pan_toggle.State = 'off';
        
        % Turn the zoom off
        zoom off
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the zoom toggle button
    function zoomclickedcallback(~,~)
        
        % Keep the zoom toggle button state to on and change the select and 
        % pan toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'on';
        pan_toggle.State = 'off';
        
        % Make the zoom enable on the current figure
        zoom_object = zoom(gcf);
        zoom_object.Enable = 'on';
        
        % Set the zoom for the x-axis only in the mixture, background, and 
        % foreground signal axes
        setAxesZoomConstraint(zoom_object,mixturesignal_axes,'x');
        setAxesZoomConstraint(zoom_object,backgroundsignal_axes,'x');
        setAxesZoomConstraint(zoom_object,foregroundsignal_axes,'x');
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the pan toggle button
    function panclickedcallback(~,~)
        
        % Keep the pan toggle button state to on and change the select and 
        % zoom toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'off';
        pan_toggle.State = 'on';
        
        % Turn the zoom off
        zoom off
        
        % Make the pan enable on the current figure
        pan_object = pan(gcf);
        pan_object.Enable = 'on';
        
        % Set the pan for the x-axis only in the mixture, background, and 
        % foreground signal axes
        setAxesPanConstraint(pan_object,mixturesignal_axes,'x');
        setAxesPanConstraint(pan_object,backgroundsignal_axes,'x');
        setAxesPanConstraint(pan_object,foregroundsignal_axes,'x');
        
    end

end

% Create play icon
function image_data = playicon

    % Create the upper-half of a black play triangle with NaN's everywhere 
    % else
    image_data = [nan(2,16);[nan(6,3),kron(triu(nan(6,5)),ones(1,2)),nan(6,3)]];

    % Make the whole black play triangle image
    image_data = repmat([image_data;image_data(end:-1:1,:)],[1,1,3]);

end
 
% Create stop icon
function image_data = stopicon

    % Create a black stop square with NaN's everywhere else
    image_data = nan(16,16);
    image_data(4:13,4:13) = 0;

    % Make the black stop square an image
    image_data = repmat(image_data,[1,1,3]);

end

% Create repet icon
function image_data = repeticon
    
    % Create a matrix with NaN's
    image_data = nan(16,16,1);
    
    % Create black R, E, P, E, and T letters
    image_data(2:8,2:3) = 0;
    image_data([2,3,5,6],4) = 0;
    image_data([3:5,7:8],5) = 0;

    image_data(2:8,7:8) = 0;
    image_data([2,3,5,7,8],9) = 0;
    image_data([2,3,7,8],10) = 0;

    image_data(10:16,2:3) = 0;
    image_data([10,11,13,14],4) = 0;
    image_data(11:13,5) = 0;

    image_data(10:16,7:8) = 0;
    image_data([10,11,13,15,16],9) = 0;
    image_data([10,11,15,16],10) = 0;

    image_data(10:11,12:15) = 0;
    image_data(12:16,13:14) = 0;
    
    % Make the image
    image_data = repmat(image_data,[1,1,3]);

end

% Read icon from Matlab
function image_data = iconread(icon_name)

    % Read icon image from Matlab ([16x16x3] 16-bit PNG) and also return 
    % its transparency ([16x16] AND mask)
    [image_data,~,image_transparency] ...
        = imread(fullfile(matlabroot,'toolbox','matlab','icons',icon_name),'PNG');

    % Convert the image to double precision (in [0,1])
    image_data = im2double(image_data);

    % Convert the 0's to NaN's in the image using the transparency
    image_data(image_transparency==0) = NaN;

end

% Short-time Fourier transform (STFT) (with zero-padding at the edges)
function audio_stft = stft(audio_signal,window_function,step_length)

% Number of samples and window length
number_samples = length(audio_signal);
window_length = length(window_function);

% Number of time frames
number_times = ceil((window_length-step_length+number_samples)/step_length);

% Zero-padding at the start and end to center the windows
audio_signal = [zeros(window_length-step_length,1);audio_signal; ...
    zeros(number_times*step_length-number_samples,1)];

% Initialize the STFT
audio_stft = zeros(window_length,number_times);

% Loop over the time frames
for time_index = 1:number_times
    
    % Window the signal
    sample_index = step_length*(time_index-1);
    audio_stft(:,time_index) = audio_signal(1+sample_index:window_length+sample_index).*window_function;
    
end

% Fourier transform of the frames
audio_stft = fft(audio_stft);

end

% Close request callback function for the figure
function figurecloserequestfcn(~,~,mixture_player)

% If the playback is in progress
if isplaying(mixture_player)
    
    % Stop the audio
    stop(mixture_player)
    
end

% Delete the current figure
delete(gcf)

end

% Clicked callback function for the play audio toggle buttons
function playaudioclickedcallback(object_handle,~,audio_player)

% Change the toggle button state to off
object_handle.State = 'off';

% If the playback of the audio player is in progress
if isplaying(audio_player)
    
    % Stop the playback
    stop(audio_player)
    
else
    
    % Get the sample range of the audio player from its user data 
    sample_range = audio_player.UserData;
    
    % Play the audio given the sample range
    play(audio_player,sample_range)
    
end

end

% Set a play line on a audio signal axes using an audio player
function playline(audiosignal_axes,audio_player,playaudio_toggle)

% Add callback functions to the audio player
audio_player.StartFcn = @audioplayerstartfcn;
audio_player.StopFcn = @audioplayerstopfcn;
audio_player.TimerFcn = @audioplayertimerfcn;

% Sample rate in Hz from the audio player
sample_rate = audio_player.SampleRate;

% Initialize the play line
play_line = [];

    % Function to execute one time when the playback starts
    function audioplayerstartfcn(~,~)
        
        % Change the play audio toggle button icon to a stop icon and the 
        % tool tip text to 'Stop'
        playaudio_toggle.CData = stopicon;
        playaudio_toggle.TooltipString = 'Stop';
        
        % Get the sample range of the audio player from its user data
        sample_range = audio_player.UserData;
        
        % Create a play line on the audio signal axes
        play_line = line(audiosignal_axes,sample_range(1)/sample_rate*[1,1],[-1,1]);
        
    end
    
    % Function to execute one time when playback stops
    function audioplayerstopfcn(~,~)
        
        % Change the play audio toggle button icon to a play icon and the 
        % tool tip text to 'Play'
        playaudio_toggle.CData = playicon;
        playaudio_toggle.TooltipString = 'Play';
        
        % Delete the play line
        delete(play_line)
        
    end
    
    % Function to execute repeatedly during playback
    function audioplayertimerfcn(~,~)
        
        % Current sample and sample range from the audio player
        current_sample = audio_player.CurrentSample;
        sample_range = audio_player.UserData;
        
        % Make sure the current sample is greater than the start sample (to
        % prevent the audio line from showing up at the start at the end)
        if current_sample > sample_range(1)
        
            % Update the play line
            play_line.XData = current_sample/sample_rate*[1,1];
            
        end
        
    end

end

% Set a select line on a audio signal axes using an audio player
function selectline(audiosignal_axes,audio_player)

% Add mouse-click callback function to the audio signal axes
audiosignal_axes.ButtonDownFcn = @audiosignalaxesbuttondownfcn;

% Initialize the select line as an array for graphic objects (two lines and 
% one patch)
select_line = gobjects(3,1);

    % Mouse-click callback function for the audio signal axes
    function audiosignalaxesbuttondownfcn(~,~)
        
        % Location of the mouse pointer
        current_point = audiosignal_axes.CurrentPoint;
        
        % Sample rate and number of samples from the audio player
        sample_rate = audio_player.SampleRate;
        number_samples = audio_player.TotalSamples;
        
        % Audio range in seconds
        audio_range = [1/sample_rate,number_samples/sample_rate];
        
        % If the current point is out of the audio signal limits, return
        if current_point(1,1) < audio_range(1) || current_point(1,1) > audio_range(2) || ...
                current_point(1,2) < -1 || current_point(1,2) > 1
            return
        end
        
        % Current figure handle
        figure_object = gcf;
        
        % Mouse selection type
        selection_type = figure_object.SelectionType;
        
        % If click left mouse button
        if strcmp(selection_type,'normal')
            
            % If not empty, delete the select line
            if ~isempty(select_line)
                delete(select_line)
            end
            
            % Create a first line on the audio signal axes
            color_value1 = 0.5*[1,1,1];
            select_line(1) = line(audiosignal_axes, ...
                current_point(1,1)*[1,1],[-1,1],'Color',color_value1);
            
            % Create a second line and a patch with different colors
            color_value2 = 0.75*[1,1,1];
            select_line(2) = line(audiosignal_axes, ...
                current_point(1,1)*[1,1],[-1,1],'Color',color_value2);
            select_line(3) = patch(audiosignal_axes, ...
                current_point(1)*[1,1,1,1],[-1,1,1,-1],color_value2,'LineStyle','none');
            
            % Move the second line and the patch at the bottom of the 
            % current stack
            uistack(select_line(2),'bottom')
            uistack(select_line(3),'bottom')
            
            % Change the pointer to a hand when the mouse moves over the 
            % lines, the audio signal axes, or the figure object
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
            iptSetPointerBehavior(select_line(1),enterFcn);
            iptSetPointerBehavior(select_line(2),enterFcn);
            iptSetPointerBehavior(audiosignal_axes,enterFcn);
            iptSetPointerBehavior(figure_object,enterFcn);
            iptPointerManager(figure_object);
            
            % Add mouse-click callback functions to the lines
            select_line(1).ButtonDownFcn = @selectlinebuttondownfcn;
            select_line(2).ButtonDownFcn = @selectlinebuttondownfcn;
            
            % Make the patch not able to capture mouse clicks
            select_line(3).PickableParts = 'none';
            
            % Add window button motion and up callback functions to the 
            % figure
            figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,select_line(1)};
            figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
            
            % Update the start sample of the audio player in its user data 
            audio_player.UserData(1) = round(current_point(1,1)*sample_rate);
            
        % If click right mouse button
        elseif strcmp(selection_type,'alt')
            
            % If not empty, delete the select line
            if ~isempty(select_line)
                delete(select_line)
            end
            
            % Update the sample range of the audio player in its user data 
            audio_player.UserData = [1,number_samples];
            
        end
        
        % Mouse-click callback function for the lines
        function selectlinebuttondownfcn(object_handle,~)
            
            % Mouse selection type
            selection_type = figure_object.SelectionType;
            
            % If click left mouse button
            if strcmp(selection_type,'normal')
                
                % Change the pointer to a hand when the mouse moves over 
                % the audio signal axes or the figure object
                enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
                iptSetPointerBehavior(audiosignal_axes,enterFcn);
                iptSetPointerBehavior(figure_object,enterFcn);
                iptPointerManager(figure_object);
                
                % Add window button motion and up callback functions to 
                % the figure
                figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,object_handle};
                figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
                
            % If click right mouse button
            elseif strcmp(selection_type,'alt')
                
                % Delete the select line
                delete(select_line)
                
                % Update the sample range of the audio player in its user 
                % data
                audio_player.UserData = [1,number_samples];
                
            end
            
        end
        
        % Window button motion callback function for the figure
        function figurewindowbuttonmotionfcn(~,~,select_linei)
            
            % Location of the mouse pointer
            current_point = audiosignal_axes.CurrentPoint;
            
            % If the current point is out of the audio signal x-axis 
            % limits, change it into the x-axis limits
            if current_point(1,1) < audio_range(1)
                current_point(1,1) = audio_range(1);
            elseif current_point(1,1) > audio_range(2)
                current_point(1,1) = audio_range(2);
            end
            
            % Update the coordinates of the audio line that has been 
            % clicked and the coordinates of the audio patch
            select_linei.XData = current_point(1,1)*[1,1];
            select_line(3).XData = [select_line(1).XData,select_line(2).XData];
            
            % If the two lines are at different coordinates and the patch 
            % is a full rectangle
            if select_line(1).XData(1) ~= select_line(2).XData(1)
                
                % Change the color of the first line to match the color of 
                % the second line and the patch, and move it at the bottom 
                % of the current stack
                select_line(1).Color = color_value2;
                uistack(select_line(1),'bottom')
                
            % If the two lines are at the same coordinates and the patch is 
            % a vertical line
            else
                
                % Change the color of the first line back, and move 
                % it at the top of the current stack
                select_line(1).Color = color_value1;
                uistack(select_line(1),'top')
                
            end
            
        end
        
        % Window button up callback function for the figure
        function figurewindowbuttonupfcn(~,~)
            
            % Change the pointer back to a ibeam and an arrow when the 
            % mouse moves over audio the signal axes and the figure object,
            % respectively
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
            iptSetPointerBehavior(signal_axes,enterFcn);
            iptPointerManager(figure_object);
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','arrow');
            iptSetPointerBehavior(figure_object,enterFcn);
            iptPointerManager(figure_object);
            
            % Coordinates of the two audio lines
            x_value1 = select_line(1).XData(1);
            x_value2 = select_line(2).XData(1);
            
            % Update the sample range of the audio player in its user data 
            % depending if the two lines have the same or different 
            % coordinates
            if x_value1 == x_value2
                audio_player.UserData = [round(x_value1*sample_rate),number_samples];
            elseif x_value1 < x_value2
                audio_player.UserData = round([x_value1,x_value2]*sample_rate);
            else
                audio_player.UserData = round([x_value2,x_value1]*sample_rate);
                
            end
            
            % Remove the window button motion and up callback functions of
            % the figure
            figure_object.WindowButtonMotionFcn = '';
            figure_object.WindowButtonUpFcn = '';
            
        end
        
    end

end

% Autocorrelation using the Wiener�Khinchin theorem (faster than using 
% xcorr)
function autocorrelation_matrix = acorr(data_matrix)

% Number of points in each column
number_points = size(data_matrix,1);

% Power Spectral Density (PSD): PSD(X) = fft(X).*conj(fft(X)) (after 
% zero-padding for proper autocorrelation)
data_matrix = abs(fft(data_matrix,2*number_points)).^2;

% Wiener�Khinchin theorem: PSD(X) = fft(acorr(X))
autocorrelation_matrix = ifft(data_matrix);

% Discard the symmetric part
autocorrelation_matrix = autocorrelation_matrix(1:number_points,:);

% Unbiased autocorrelation (lag 0 to number_points-1)
autocorrelation_matrix = autocorrelation_matrix./(number_points:-1:1)';

end
        
% Beat spectrum using the autocorrelation
function beat_spectrum = beatspectrum(audio_spectrogram)

% Autocorrelation of the frequency channels
beat_spectrum = acorr(audio_spectrogram');

% Mean over the frequency channels
beat_spectrum = mean(beat_spectrum,2);

end

% Repeating periods from the beat spectrum
function repeating_periods = periods(beat_spectrum,period_range)

% The repeating periods are the indices of the maxima in the
% beat spectrum for the period range (they do not account for
% lag 0 and should be shorter than a third of the length as at
% least three segments are needed for the median)
[~,repeating_periods] = max(beat_spectrum(period_range(1)+1:min(period_range(2),floor(size(beat_spectrum,1)/3)),:),[],1);

% Re-adjust the index or indices
repeating_periods = repeating_periods+period_range(1);

end

% % Set the beat lines on the beat spectrum axes
% function beat_lines = beatlines(beatline_position,beatspectrum_duration,beatspectrum_axes)
% 
% % Initialize the beat lines as an array for graphic objects
% number_lines = floor(beatspectrum_duration/beatline_position);
% beat_lines = gobjects(number_lines,1);
% 
% % Create the main beat line on the beat spectrum axes
% beat_lines(1) = line(beatspectrum_axes, ...
%     beatline_position*[1,1],[-1,1], ...
%     'Color','r');
% 
% % Create the other beat lines as dotted lines
% for line_index = 2:number_lines
%     beat_lines(line_index) = line(beatspectrum_axes, ...
%         beatline_position*line_index*[1,1],[-1,1], ...
%         'Color','r','LineStyle',':');
% end
% 
% % Current figure handle
% figure_object = gcf;
% 
% % Change the pointer to a hand when the mouse moves over the main line
% enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
% iptSetPointerBehavior(beat_lines(1),enterFcn);
% iptPointerManager(figure_object);
% 
% % Period range for the beat spectrum in seconds
% % period_range = [1/number_times*number_samples/sample_rate,floor(beatspectrum_duration/3)];
% period_range = [1,floor(beatspectrum_duration/3)];
% 
% % Add mouse-click callback functions to the main line
% beat_lines(1).ButtonDownFcn = @beatlinebuttondownfcn;
% 
%     % Mouse-click callback function for the main line
%     function beatlinebuttondownfcn(~,~)
%         
%         % Mouse selection type
%         selection_type = figure_object.SelectionType;
%         
%         % If not click left mouse button, return
%         if ~strcmp(selection_type,'normal')
%             return
%         end
%         
%         % Change the pointer to a hand when the mouse moves over the beat 
%         % spectrum axes and the figure object
%         enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
%         iptSetPointerBehavior(beatspectrum_axes,enterFcn);
%         iptSetPointerBehavior(figure_object,enterFcn);
%         iptPointerManager(figure_object);
%         
%         % Add window button motion and up callback functions to the figure
%         figure_object.WindowButtonMotionFcn = @figurewindowbuttonmotionfcn;
%         figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
%         
%     end
% 
%     % Window button motion callback function for the figure
%     function figurewindowbuttonmotionfcn(~,~)
%         
%         % Location of the mouse pointer
%         current_point = beatspectrum_axes.CurrentPoint;
%         
%         % If the current point is out of the beat spectrum x-axis limits, 
%         % change it into the x-axis limits
%         if current_point(1,1) < period_range(1)
%             current_point(1,1) = period_range(1);
%         elseif current_point(1,1) > period_range(2)
%             current_point(1,1) = period_range(2);
%         end
%         
%         % Delete the beat lines
%         delete(beat_lines)
%         
%         % Create the main beat line on the beat spectrum axes
%         beat_lines(1) = line(beatspectrum_axes, ...
%             current_point(1,1)*[1,1],[-1,1], ...
%             'Color','r');
%         
%         % Create the other beat lines as dotted lines
%         for line_index = 2:number_lines %#ok<*FXUP>
%             beat_lines(line_index) = line(beatspectrum_axes, ...
%                 current_point(1,1)*line_index*[1,1],[-1,1], ...
%                 'Color','r','LineStyle',':');
%         end
%         
%     end
% 
%     % Window button up callback function for the figure
%     function figurewindowbuttonupfcn(~,~)
%         
%         % Change the pointer to a hand, an ibeam, and an arrow when the 
%         % mouse moves over the main line, the beat spectrum axes and the 
%         % figure object, respectively
%         enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
%         iptSetPointerBehavior(beat_lines(1),enterFcn);
%         iptPointerManager(figure_object);
%         enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
%         iptSetPointerBehavior(beatspectrum_axes,enterFcn);
%         iptPointerManager(figure_object);
%         enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','arrow');
%         iptSetPointerBehavior(figure_object,enterFcn);
%         iptPointerManager(figure_object);
%         
%         % Add mouse-click callback functions to the main line
%         beat_lines(1).ButtonDownFcn = @beatlinebuttondownfcn;
%         
%         % Remove the window button motion and up callback functions of
%         % the figure
%         figure_object.WindowButtonMotionFcn = '';
%         figure_object.WindowButtonUpFcn = '';
%         
%     end
% 
% end
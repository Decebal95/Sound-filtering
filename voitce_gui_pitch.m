function voice_gui_pitch()
    % Creează fereastra GUI
    fig = figure('Name', 'Voice Recorder GUI', 'NumberTitle', 'off', ...
        'Position', [500, 300, 500, 350]);

    % Axă pentru semnal audio
    ax = axes('Parent', fig, 'Units', 'pixels', 'Position', [100, 130, 300, 150]);

    % Text Status
    statusText = uicontrol('Style', 'text', 'String', 'Apasă Start pentru a înregistra', ...
        'Position', [150, 20, 200, 20], 'FontSize', 10);

    % Text + slider pentru resampling
    uicontrol('Style', 'text', 'String', 'Factor resampling (0.5 – 2.0)', ...
        'Position', [170, 300, 180, 20]);

    resampleSlider = uicontrol('Style', 'slider', ...
        'Min', 0.5, 'Max', 2, 'Value', 1, ...
        'SliderStep', [0.01 0.1], ...
        'Position', [150, 280, 200, 20], ...
        'Callback', @updateSliderText);

    % Text cu valoarea curentă a sliderului
    resampleText = uicontrol('Style', 'text', ...
        'Position', [360, 280, 50, 20], ...
        'String', '1.00');

    % Buton Start
    uicontrol('Style', 'pushbutton', 'String', 'Start', ...
        'FontSize', 12, ...
        'Position', [200, 80, 100, 30], ...
        'Callback', @startRecording);

    % Actualizare text când sliderul se mișcă
    function updateSliderText(~, ~)
        val = get(resampleSlider, 'Value');
        set(resampleText, 'String', sprintf('%.2f', val));
    end

    % Funcție de înregistrare
    function startRecording(~, ~)
        Fs = 44100;
        recObj = audiorecorder(Fs, 16, 1);
        record(recObj);
        set(statusText, 'String', 'Înregistrează...');

        % Detectare tăcere pentru oprire automată
        frameLength = 0.1;
        frameSamples = round(Fs * frameLength);
        silenceThreshold = 0.01;
        silenceCount = 0;
        maxSilenceFrames = 10;

        while true
            pause(frameLength);
            audioData = getaudiodata(recObj);
            if length(audioData) < frameSamples
                continue;
            end
            recentFrame = audioData(end-frameSamples+1:end);
            frameEnergy = rms(recentFrame);

            if frameEnergy < silenceThreshold
                silenceCount = silenceCount + 1;
            else
                silenceCount = 0;
            end

            if silenceCount >= maxSilenceFrames
                break;
            end
        end

        stop(recObj);
        x = getaudiodata(recObj);
        t = (0:length(x)-1)/Fs;

        % Afișare semnal audio
        plot(ax, t, x);
        xlabel(ax, 'Timp [s]');
        ylabel(ax, 'Amplitudine');
        title(ax, 'Semnal audio înregistrat');
        grid(ax, 'on');
        set(statusText, 'String', 'Înregistrare oprită.');

        % Resampling (pitch shift)
        factor = get(resampleSlider, 'Value');
        p = round(factor * 1000);
        q = 1000;

        try
            x_pitched = resample(x, p, q);
            x_final = x_pitched;
        catch err
            warning('Eroare la resampling: %s', err.message);
            x_final = x;
        end

        % Redare audio
        sound(x_final, Fs);
    end
end

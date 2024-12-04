%% 音のパターンの生成
all_patterns = generate_all_beep_patterns();

%% 音パターンを再生（指定したinterval_indexに基づく）
interval_index = 3; % 任意のインデックスを指定
play_beep_pattern(all_patterns, interval_index);

%%
function all_patterns = generate_all_beep_patterns()
    % 設定
    tap_interval_list = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
    frequency = 500;         % ビープ音の周波数 (Hz)
    beep_duration = 0.03;     % 各ビープ音の長さ（秒）
    sampleRate = 44100;      % サンプリングレート（Hz）
    total_duration = 20;     % ビープ音を鳴らす合計時間（秒）

    % 各interval_indexに対応する音パターンを生成
    all_patterns = cell(1, length(tap_interval_list));
    for idx = 1:length(tap_interval_list)
        % 指定されたインデックスのタップ間隔
        tap_interval = tap_interval_list(idx);

        % ビープ音の基本波形生成
        t_beep = linspace(0, beep_duration, round(beep_duration * sampleRate));
        beep_signal = sin(2 * pi * frequency * t_beep);

        % 20秒間のビープ音パターン生成
        pattern_signal = [];
        current_time = 0;

        while current_time < total_duration
            % パターンにビープ音を追加
            pattern_signal = [pattern_signal, beep_signal];

            % 無音区間を追加
            silence_duration = tap_interval - beep_duration;
            if silence_duration > 0
                silence_signal = zeros(1, round(silence_duration * sampleRate));
                pattern_signal = [pattern_signal, silence_signal];
            end

            % 現在の時間を更新
            current_time = current_time + tap_interval;
        end

        % セル配列にパターンを保存
        all_patterns{idx} = pattern_signal;
    end
end

%%
function play_beep_pattern(all_patterns, interval_index)
    sampleRate = 44100; % サンプリングレート（Hz）
    pattern_signal = all_patterns{interval_index}; % 指定されたインデックスのパターンを取得
    sound(pattern_signal, sampleRate);
end

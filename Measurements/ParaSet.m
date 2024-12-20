%%
jKey = KbName('J');  % 1
eKey = KbName('E');  % 2
iKey = KbName('I');  % 3
fKey = KbName('F');  % 4
list_Key = [jKey,eKey,iKey,fKey];

% キーに対応する番号を定義
keyMapping = [1, 2, 3, 4];  % J, E, I, Fに対応する番号

%% Common Variables
trial_task_time = 20; % 1trial内の1taskの時間
tap_interval_list = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];

num_trials = 20;
num_loops = 30; % 被験者の挑戦する速度レベルによって変わる
num_keys = 4;
required_keystrokes = zeros(num_trials, 1); % そのtrialの要求打鍵数
fail_miss_detector = zeros(num_trials, 1); % FailかMissがあったtrialを1として保存、Perfect_trialsの検出に使用

% Blockごとの結果を保存するための一時変数
block.judge = []; % 提示した数字1つにつき1つ判定値を保存
block.tap_times = zeros(num_trials, num_keys, 11000); % 各trialでどのキーをどの時刻に押したかを記録。最後の要素数は打鍵判定を行うwhileループの回る回数(while_count)より大きい数[要検討]
block.tap_interval = zeros(num_trials, 1); % 各trialでの要求打鍵間隔を記録
block.interval_index_recorder = zeros(num_trials, 1); % そのblockで各trialのinterval_indexの推移を保存
block.success_duration = zeros(num_trials, 1); % 各trialの打鍵成功持続時間
block.beep_start_time = zeros(num_trials, 1); % 各trialでのビープ音開始時刻（黄色数字提示直前）を記録

% Block全ての打鍵受付開始時間を記録する変数（＝一つ前の打鍵受付終了時間を示す）
block.tap_acceptance_start_times = zeros(num_trials, num_loops, num_keys); % そのtrialではどの打鍵をどの時刻に受付開始したかを記録

% Block全ての数字提示時間を記録する変数
block.display_times = zeros(num_trials, num_loops, num_keys); % そのtrialではどの数字をどの時刻に提示したかを記録


% trialごとの結果を保存するための一時変数
% trial_judge = zeros(num_loops, num_keys);
% trial_tap_times = zeros(num_loops, num_keys, num_loops*num_keys*100);

participant_name = '11B5'; % 被験者名とBlock番号をここで設定（例：00B1）

%% 音のパターンの生成
all_patterns = generate_all_beep_patterns();

% 全trial（= 1block）分の最終保存の処理
% block = struct('judge', [], 'tap_times', [] , 'display_times', []); % 全trial（= 1block）の結果を保存するための変数

%% Speed Adjustment Block Variables
determined_interval_index = 0; % 決定したinterval_index
mean_success_duration = zeros(3,1);

%% National Insruments Data Acquisition (by S.Iwama.)
% DevID = 'Dev2'; % Please check
% daq = DAQclass(DevID);
% daq.init_output()


%% ビープ音の配列を生成する関数
function all_patterns = generate_all_beep_patterns()
    % 設定
    tap_interval_list = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
    frequency = 500;         % ビープ音の周波数 (Hz)
    beep_duration = 0.03;     % 各ビープ音の長さ（秒）
    sampleRate = 44100;      % サンプリングレート（Hz）

    % 各interval_indexに対応する音パターンを生成
    all_patterns = cell(1, length(tap_interval_list));
    for idx = 1:length(tap_interval_list)
        % 指定されたインデックスのタップ間隔
        tap_interval = tap_interval_list(idx);

        total_duration = 20 + 8.5 * tap_interval;  % ビープ音を鳴らす合計時間（秒）

        % ビープ音の基本波形生成
        t_beep = linspace(0, beep_duration, round(beep_duration * sampleRate));
        beep_signal = sin(2 * pi * frequency * t_beep);

        % フェードインとフェードアウトの適用
        fade_duration = round(0.1 * length(beep_signal)); % 信号の最初と最後10%をフェード
        fade_in = linspace(0, 1, fade_duration);
        fade_out = linspace(1, 0, fade_duration);

        beep_signal(1:fade_duration) = beep_signal(1:fade_duration) .* fade_in;
        beep_signal(end-fade_duration+1:end) = beep_signal(end-fade_duration+1:end) .* fade_out;

        % 20秒間のビープ音パターン生成
        pattern_signal = zeros(1, round((tap_interval / 2) * sampleRate)); % 最初に無音を追加
        current_time = tap_interval / 2;    % 初期の時間を無音分で進めておく

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

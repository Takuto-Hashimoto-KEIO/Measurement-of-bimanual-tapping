KbName('UnifyKeyNames');
DisableKeysForKbCheck([240, 243, 244]);
figure('Color', 'k', 'Position',[0.0010    0.0490    2.5600    1.3193]*500); % 黒色の背景を持つ新しい図を開く
axis off; % 軸を非表示にする
hold on;

interval_index = 2;  % Main Block単独のテスト用

trial_task_time = 20; % 1trial内の1taskの時間
consecutive_same_speeds = 1; % 同じ速度の連続回数、5以上になると速度移動許可

pause(1); % この間に表示画面を移動

%% Main Block
text(0.5, 0.5, 'Main Block', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の"Main Block"を表示
% sendCommand(daq,1); % main block開始
pause(3); % 3秒間待機
cla;
speed_change = 0; % 0なら速度変更なしだった、1なら速度上昇した、-1なら速度低下した。被験者への画面提示に使用。

for num_trials = 1:20 % 1blockで20trial実施
    fprintf("\n trial%d, 速度レベル = %d \n", num_trials, interval_index)
    cla; % 現在の図をクリア

    % % sendCommand(daq,2); % Rest
    % text(0.5, 0.5, sprintf('Trial %d', num_trials), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
    % pause(1);
    % cla;
    % 
    % pause_rest_time = 7;
    % 
    % % 速度変更を被験者に通知
    % if speed_change == 1
    %     text(0.5, 0.5, sprintf('Speed Up'), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
    %     pause(2);
    %     cla;
    %     speed_change = 0;
    % elseif speed_change == -1
    %     text(0.5, 0.5, sprintf('Speed Down'), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色のセッション番号を表示
    %     pause(2);
    %     cla;
    %     speed_change = 0;
    % else
    %     pause_rest_time = 9;
    % end
    % 
    % text(0.5, 0.5, 'Rest', 'Color', 'b', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 青色の"Rest"を表示
    % pause(pause_rest_time); % 9秒間待機
    % cla;
    % 
    % text(0.5, 0.5, 'Ready', 'Color', 'r', 'FontSize', 100,'HorizontalAlignment', 'center'); % 赤色の"Ready"を表示
    % % sendCommand(daq,3); % Ready
    % pause(2); % 2秒間待機
    % cla;

    tap_interval = tap_interval_list(interval_index); % 打鍵間隔は、interval_indexを参照してtask開始の度に更新

    while_count = 0; % 同一task内での打鍵判定のwhileループの回った回数
    num_keys_num_loops_update_marker = 0; % num_loops, num_keysを更新すると、1を格納して記録
    block.interval_index_recorder(num_trials) = interval_index; % そのblockで各trialのinterval_indexの推移を保存
    num_keystroke_sections = 1; % このtrialで何回目の打鍵判定区間か

    first_answer = 1; % 1task内での最初の打鍵の判定に使う。最初の打鍵が起こると0を保存

    block.tap_interval(num_trials) = tap_interval; % 各trialでの要求打鍵間隔を記録
    task_terminater = 0; % taskの終了時刻になると、1が格納されtask終了処理がアクティブになる
    draw_stopper = 0; % 同じ数字描画を繰り返さないための変数、0で描画可能、描画したら1を格納して描画をロック

    % sendCommand(daq,4); % 速度提示
    play_beep_pattern(all_patterns, interval_index); % ビープ音を再生
    block.beep_start_time(num_trials) = GetSecs; % 各trialでのビープ音開始時刻（黄色数字提示直前）を記録 % ビープ音開始直前＝開始時刻記録直後まで、0.02～0.07秒ずれる

    text(0.5, 0.5, num2str(1), 'Color', 'y', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 音の開始と同時（厳密には直後）に黄色の数字”1”を表示
    drawnow
    count8 = 0; % 黄色の数字提示をした回数を記録
    block.first_beep_time = block.beep_start_time(num_trials) + tap_interval/2; % 最初のビープ音がする時刻を格納

    for num_loops = 1:2  % 2ループで速度提示
        for num_keys = 1:4
            while(1)
                if GetSecs >= block.first_beep_time + count8*tap_interval % 最初のビープ音時を基準に、一つ前の数字提示からtap_interval経過していたら、次の数字提示に切り替える
                    cla;
                    text(0.5, 0.5, num2str(num_keys), 'Color', 'y', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 黄色の数字を表示
                    drawnow
                    count8 = count8 + 1;
                    break; % 数字を提示したらfor文を回す
                end
            end
        end
    end
    cla;

    num_loops = 1;
    num_keys = 1;

    % sendCommand(daq,5); % task
    task_start_time = GetSecs; % taskの開始時刻を保存
    tic;

    while(1) % 1taskを全被験者で時間が一定になるよう変えた
        target_key = list_Key(num_keys);
        ListenChar(2);
        num_answers = 1; % if文分岐（Fail）のために使用
        miss_tap_count = 0; % 同一打鍵受付範囲内でのMiss表示の重複を防ぐ


        while(1) % 最初の打鍵受付開始～最後の打鍵受付終了　数字提示と打鍵判定をセットで回す
            % 数字提示とその時刻の格納
            if GetSecs > block.first_beep_time + (8 + num_keystroke_sections - 1)*tap_interval && draw_stopper == 0 % 最初のビープ音時を基準に、一つ前の数字提示からtap_interval経過していたら、次の(現在成功判定中の打鍵に対応する)数字提示に切り替える
                text(0.5, 0.5, num2str(num_keys), 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の数字を表示
                drawnow
                block.display_times(num_trials, num_loops, num_keys) = GetSecs; % 数字の提示時間を記録、ただしラグがある
                draw_stopper = 1; % 次の打鍵判定区間に切り替わるまで描画をロック
            end

            if num_keys_num_loops_update_marker == 1 || while_count == 0 % num_loops, num_keysを更新して初めての打鍵の受付なら、打鍵受付開始時刻として記録
                % toc; % 次の打鍵判定区間にもう入っているが、打鍵判定できていない時間終了
                block.tap_acceptance_start_times(num_trials, num_loops, num_keys) = GetSecs;
                num_keys_num_loops_update_marker = 0; % num_loops, num_keysを更新すると、1を格納して記録
            end

            while_count = while_count + 1;
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();

            % 時間経過によるFail判定を内包した、1つの打鍵受付の終了判定
            toc;
            tic;
            if GetSecs > block.first_beep_time + (8 + num_keystroke_sections - 1/2)*tap_interval % ビープ音開始時を基準に、一つ前の打鍵受付終了時刻からtap_interval経過
                % tic; % 次の打鍵判定区間にもう入っているが、打鍵判定できていない時間開始
                if num_answers == 1 % SuccessでもMissでもなかったとき
                    fprintf('Fail');
                    fail_miss_detector(num_trials) = 1;
                end

                % task終了判定
                if GetSecs >= block.first_beep_time + 8*tap_interval + trial_task_time % task開始からtrial_task_time秒間以上経過したらそのtaskを終了(1taskを表すwhile文を抜ける)。打鍵判定区間の終わりのみで判定するため、実際には1taskの時間は最大tap_interval分増える可能性がある
                    task_terminater = 1;
                    break

                else % task終了時刻でないなら、成功と判定する打鍵を更新し、次の打鍵判定区間に移行
                    num_keys = num_keys + 1;
                    if num_keys == 5
                        num_keys = 1;
                        num_loops = num_loops + 1; % 打鍵「JEIF」のループ数を更新
                    end

                    num_keystroke_sections = num_keystroke_sections + 1; % このtrialで何回目の打鍵判定区間かを更新
                    num_keys_num_loops_update_marker = 1; % num_loops, num_keysの更新を記録
                    draw_stopper = 0; % 描画のロックを解除
                    cla;
                end
                break % 打鍵判定を行うwhileループを抜ける（各種値をリセットするため）
            end
            
            if keyIsDown == 0 % 打鍵無しの判定
                block.tap_times(num_trials, :, while_count) = 0;

            else % 打鍵があったとき

                pressedKeys = keyMapping(keyCode(list_Key) == 1);
                block.tap_times(num_trials, pressedKeys, while_count) = GetSecs; % 打ったキーの列にその時刻を保存

                if first_answer == 1 % 1task内での最初の打鍵「あり」の判定
                    % sendCommand(daq,10); % Taskで最初の打鍵
                    first_answer = 0;
                end

                % 誤ったキーが押されているかチェック
                wrongKeys = setdiff(keyMapping, num_keys); % 誤ったキー番号を取得
                wrongKeyPressed = any(ismember(pressedKeys, wrongKeys)); % 誤ったキーが押されたか確認

                if wrongKeyPressed % 誤った打鍵があったとき
                    if miss_tap_count == 0
                        fprintf('Miss');
                        num_answers = num_answers + 1; % これ以降この数字提示での成功打鍵受付を無効化（judgeに関して）
                        fail_miss_detector(num_trials) = 1;
                    end
                    miss_tap_count = miss_tap_count + 1;

                elseif all(pressedKeys == num_keys) && isscalar(pressedKeys) % 正しい打鍵だけをしたとき（前後tap_interval÷2秒間で打鍵成功）
                    if num_answers == 1
                        fprintf('Success');
                        num_answers = num_answers + 1; % これ以降この数字提示での成功打鍵受付を無効化（judgeに関して）
                    end
                end
            end
            WaitSecs(0.001);
        end

        fprintf('\n');

        if task_terminater == 1 % task開始からtrial_task_time秒間以上経過したらそのtaskを終了(1taskを表すwhile文を抜ける)
            task_end_time = GetSecs;
            break
        end

    end

    cla;
    text(0.5, 0.5, 'Blank', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
    drawnow

    fprintf('while_count = %d\n', while_count); % 検証用

    %% 速度変更有無の判定（各trial終了時に逐次）
    % 各trialのjudge_typingを実行
    [latest_trial_judge, judge_parameters.keystroke_relaxation_range, judge_parameters.tolerance_percentage_1, judge_parameters.tolerance_percentage_2] = judge_typing(block, tap_interval, num_trials, num_loops, num_keys); % 最新trial
    Past_judge = block.judge; % 最新以外のtrial
    required_keystrokes(num_trials, 1) = size(latest_trial_judge,1);
    fprintf("要求打鍵数 = %d\n", required_keystrokes(num_trials, 1))
    block.judge = NaN(num_trials, max(required_keystrokes)); % 新しくNaNで埋め尽くされたjudge配列を用意
    block.judge(num_trials, 1:required_keystrokes(num_trials, 1)) = latest_trial_judge; % 最新trialを格納

    for i = 1:num_trials-1 % 最新trial以外を格納
        block.judge(i, 1:required_keystrokes(i, 1)) = Past_judge(i, 1:required_keystrokes(i, 1)) ;
    end

    % 打鍵成功持続時間の計算と保存
    success_duration = calculate_success_duration(block, num_trials, trial_task_time, required_keystrokes(num_trials, 1));
    block.success_duration(num_trials) = success_duration;

    fprintf("interval_index = %d, 要求打鍵数 = %d\n", interval_index, required_keystrokes(num_trials, 1));
    fprintf('打鍵成功持続時間 = %d\n', block.success_duration(num_trials));

    % 速度変更有無の判定と適用
    [interval_index, speed_change] = speed_changer(block, interval_index, num_trials, consecutive_same_speeds, trial_task_time);

    % 同一打鍵速度継続数の加算・初期化
    if speed_change == 0
        consecutive_same_speeds = consecutive_same_speeds + 1;
    else
        consecutive_same_speeds = 0;
    end

    blank_time_range = 5 - (GetSecs - task_end_time); % blankの時間が全体で5秒間になるよう調整
    
    % sendCommand(daq,6); % Blank
    text(0.5, 0.5, 'Blank', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
    pause(blank_time_range); % 5秒間待機
    cla;

end

% sendCommand(daq,7); % Block終了




%% 全trial（= 1block）終了後の保存
sum_success_types = sum(block.judge == 1, "all");
num_number_presented = sum(block.judge == 0 | block.judge == 1, "all"); % 数字提示の回数（打鍵すべき回数）（trial数×1trialの数字提示の回数）
overall_sucesss_rate = sum_success_types/num_number_presented; % block全体での打鍵成功率：成功打鍵数を数字提示の回数で割る
overall_mean_success_duration = mean(block.success_duration(1:num_trials)); % block全体での打鍵成功持続時間の平均
num_perfect_trials = sum(all(block.judge ~= 0 | isnan(block.judge), 2)); % 完遂trial数

block_date = datetime('now', 'Format', 'yyyyMMdd_HHmmss');
block_filename = sprintf('Block_Result_%s_%s.mat', block_date, participant_name);
save(block_filename, 'participant_name', 'block', 'judge_parameters', 'overall_sucesss_rate', 'overall_mean_success_duration', 'num_perfect_trials');

fprintf('\n result: sum_success_types = %d, num_number_presented = %d\n', sum_success_types, num_number_presented)
fprintf('overall_sucesss_rate = %d, overall_mean_success_duration = %d, num_perfect_trials = %d\n', overall_sucesss_rate, overall_mean_success_duration, num_perfect_trials);

PTcount = 0; % Perfect trialsがあったら1、無かったら0として判定

for i = 1:num_trials % Perfect trialsを表示
    if fail_miss_detector(i) == 0 % そのtrialが全てSucceessだったとき
        if PTcount == 0
            fprintf('Perfect trials are = trial');
        end
        PTcount = PTcount + 1;
        fprintf(' %d,', i);
    end
end

if PTcount == 0
    fprintf('\nPerfect trials are Nothing!');
else
    fprintf('\nPerfect trials were %d times', PTcount);
end

fprintf('\n');

% generate_Success_Duration_glaph; % 打鍵成功継続時間の分布を見て、tap_intervalを変更するか判断

close all





%% ビープ音の再生
function play_beep_pattern(all_patterns, interval_index)
sampleRate = 44100; % サンプリングレート（Hz）
pattern_signal = all_patterns{interval_index}; % 指定されたインデックスのパターンを取得
sound(pattern_signal, sampleRate);
end


%% judge_typing関数 trialの冒頭は打鍵成功判定を緩める[程度は要検討]
function [judge, keystroke_relaxation_range, tolerance_percentage_1, tolerance_percentage_2] = judge_typing(block, tap_interval, num_trials, num_loops, num_keys)
judge = zeros(4*(num_loops - 1) + num_keys, 1); % judge配列の初期化


%% 打鍵判定の基準となるbeep音が鳴った時刻の配列を作成
% 出力配列の準備
trial_task_time = 20;
required_taps_total = 4*(num_loops - 1) + num_keys; % タップ数を記録
beep_times = NaN(required_taps_total, 1); % 結果配列をNaNで初期化

% beep音が鳴った時刻を計算して格納
t = block.first_beep_time + 8 * tap_interval; % 初期値
current_time = t:tap_interval:(t + trial_task_time); % 時刻の生成
num_beeps = numel(current_time); % ビープ音が鳴った数
beep_times(1:num_beeps) = current_time; % 結果配列に格納
% beep_times = beep_times - t; %% 検証用

% t + trial_task_time以上の値をNaNに置き換え
% beep_times(beep_times >= t + trial_task_time) = NaN;

% 新しい配列 (ループ数 × 4) の作成、block.first_beep_time + 8 * tap_intervalを始点とし、tap_intervalごとにtrial_task_timeを超えるまで加算
beep_times_keys = NaN(num_loops, 4, 'single'); % 新しい配列、keyごとに次元を分ける

for mod_index = 0:3 % mod(インデックス, 4) の結果に基づく次元分け
    % 該当インデックスの抽出
    selected_indices = find(mod(1:size(beep_times, 1), 4) == mod_index);
    if mod_index ~= 0
        beep_times_keys(1:numel(selected_indices), mod_index) = beep_times(selected_indices);
    else
        beep_times_keys(1:numel(selected_indices), 4) = beep_times(selected_indices);
    end
end


%% パラメータの設定
keystroke_relaxation_range = 1/4; % 打鍵成功判定を緩和する割合　task全体での要求打鍵数の1/4　%%%

tolerance_percentage_1 = 0.75; % task開始直後の打鍵成功許容範囲の割合 少し緩める %%%
tolerance_percentage_2 = 0.50; % 通常の打鍵成功許容範囲の割合

correct_key_pressed = zeros(required_taps_total, 1);
incorrect_key_pressed = zeros(required_taps_total, 1);

%% judge配列の生成
for loop = 1:num_loops
    for key = 1:4
        if required_taps_total < 4*(loop - 1) + key
            break;
        end

        if beep_times_keys(loop, key) - beep_times_keys(1, 1) <= (beep_times_keys(num_loops, num_keys) - beep_times_keys(1, 1)) * keystroke_relaxation_range % 打鍵がtrial全体から見て最初の1/4（ほぼ最初の5秒間に相当）
            tolerance_percentage = tolerance_percentage_1; % task開始直後の打鍵成功許容範囲の割合 少し緩める %%%
            rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
        else
            tolerance_percentage = tolerance_percentage_2; % 通常の打鍵成功許容範囲の割合
            rejection_percentage = 1 - tolerance_percentage; % 誤った打鍵の検出を行う範囲の割合
        end

        beep_point = beep_times_keys(loop, key); % この打鍵判定区間の中心時刻。ラグのあるblock.display_timesを使わず、beep_timeを基準に決定
        tap_window_start = beep_point - tap_interval * tolerance_percentage; % 成功判定時間窓の開始時刻 %%%
        tap_window_end = beep_point + tap_interval * tolerance_percentage;   % 成功判定時間窓の終了時刻 %%%


        % 該当キーが押されているか確認
        if any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end)
            correct_key_pressed(4*(loop - 1) + key, 1) = key;
        end

        % correct_key_pressed = any(block.tap_times(num_trials, key, :) >= tap_window_start & block.tap_times(num_trials, key, :) <= tap_window_end);

        % 他のキーが誤って押されていないか確認
        tap_window_start = beep_point - tap_interval * rejection_percentage; % 失敗判定時間窓の開始時刻 %%%
        tap_window_end = beep_point + tap_interval * rejection_percentage;   % 失敗判定時間窓の終了時刻 %%%

        % incorrect_key_pressed = false;
        for other_key = setdiff(1:4, key) % key以外のキーをチェック
            if any(block.tap_times(num_trials, other_key, :) >= tap_window_start & block.tap_times(num_trials, other_key, :) <= tap_window_end)
                incorrect_key_pressed(4*(loop - 1) + key, 1) = other_key;
                break;
            end
        end

        % 該当キーが押され、誤ったキーが押されていない場合、judgeに1を格納
        if correct_key_pressed(4*(loop - 1) + key, 1) == key && incorrect_key_pressed(4*(loop - 1) + key, 1) == 0
            if block.display_times(num_trials, loop, key) == 0 % 画面提示されてない数字の対応打鍵は判定しない
                judge(4*(loop - 1) + key, 1) = NaN;
            else
                judge(4*(loop - 1) + key, 1) = 1;
            end
        end
        % fprintf("%d\n", 4*(loop - 1) + key) % [検証用]
    end
end
end


%% success_durationの計算
function success_duration = calculate_success_duration(block, num_trials, trial_task_time, required_keystrokes)
% 現在のtrialにおいて、成功した打鍵（block.judgeが1の箇所）のインデックスを取得
success_indices = find(block.judge(num_trials, :) == 1);


% 追加処理: 最初の成功インデックスを取得し、それに基づいて条件を判定
if ~isempty(success_indices)
    first_success = success_indices(1);
    % 最初の成功インデックスに基づいてtask開始～最初の打鍵成功までの時間を一時計算
    temp_duration = (first_success / required_keystrokes) * trial_task_time;
    % temp_durationが3秒より大きい場合はsuccess_durationを0とする（最初の打鍵成功が遅すぎるため）
    if temp_duration > 3
        success_duration = 0;
        return;
    end
end


% 成功した打鍵が存在する場合のみ処理を進める
if ~isempty(success_indices)
    % 最初の成功打鍵のインデックスを取得
    first_success = success_indices(1);

    % 最初の成功打鍵以降、連続しない（間が空いた）成功の前までの最後の連続成功を取得
    last_success = success_indices(find(diff(success_indices) ~= 1, 1, 'first'));

    % もし間が空いた成功が見つからない場合、最後の成功打鍵を末尾の成功インデックスとする
    if isempty(last_success)
        last_success = success_indices(end); % 連続成功が末尾まで続いた場合
    end

    % 成功した期間を、試行のタスク時間の割合として計算
    success_duration = ((last_success - first_success + 1) / required_keystrokes) * trial_task_time;
else
    success_duration = 0; % 成功した打鍵が1つもない場合
end
end

% speed_changer関数の変更
function [interval_index, speed_change] = speed_changer(block, interval_index, num_trials, consecutive_same_speeds, trial_task_time)
    speed_change = 0;
    x = 3; % 直近何trialを参照するか[要検討] %%%

    if num_trials >= x %%%
        last_x_durations = block.success_duration(num_trials-(x-1):num_trials);
        fprintf('直近%dtrialの打鍵成功持続時間 = ', x);
        for i = 1:x
            fprintf('%d, ', last_x_durations(i));
        end
        fprintf('consecutive_same_speeds = %d\n', consecutive_same_speeds);

        if consecutive_same_speeds >= 5 % 最低でも連続5trialは同じ要求打鍵速度で %%%
            if all(last_x_durations >= trial_task_time * 0.9) && interval_index <= 10
                interval_index = interval_index + 1; % 速度上昇
                speed_change = 1;
            elseif all(last_x_durations <= trial_task_time * 0.5) && interval_index >= 2
                interval_index = interval_index - 1; % 速度低下
                speed_change = -1;
            end
        % else
        %     last_durations = block.success_duration(1:num_trials);
        %     fprintf('ここまでのtrialの打鍵成功持続時間 = ');
        %     for i = 1:num_trials
        %         fprintf('%d, ', last_durations(i));
        %     end
        %     fprintf('consecutive_same_speeds = %d\n', consecutive_same_speeds);
        end
    end
end
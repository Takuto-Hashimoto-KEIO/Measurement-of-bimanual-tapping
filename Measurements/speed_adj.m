clear
close all
%%
Startup_SA;
%%
ParaSet; % ここまでSpeed Adjustment Block単独でのテスト用

KbName('UnifyKeyNames');
DisableKeysForKbCheck([240, 243, 244]);
figure('Color', 'k', 'Position',[0.0010    0.0490    2.5600    1.3193]*500); % 黒色の背景を持つ新しい図を開く
axis off; % 軸を非表示にする
hold on;

pause(1); % この間に表示画面を移動

%% Speed Adjustment Block
text(0.5, 0.5, 'Speed Adjustment Block', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の"Speed Adjustment Block"を表示
pause(3); % 3秒間待機
cla;

interval_index = 1; % 速度レベルの初期値
block.tap_acceptance_start_times = zeros(30, num_loops, num_keys); % そのtrialではどの打鍵をどの時刻に受付開始したかを記録、speed_adj_blockの都合上１次元の要素数を変更
% tap_interval_list = [1/2, 1/2.3, 1/2.6, 1/2.9, 1/3.2, 1/3.5, 1/3.9, 1/4.3, 1/4.7, 1/5.2, 1/5.7];
Screening1_terminater = 0; % 1が格納されると、whileループを抜けてScreening 1を終了させる
repeat_count = 0; % "Try_again"となったときにnum_trialsを2ずつ増やすための変数

% Screening 1
% sendCommand(daq,1); % Screening 1 開始
text(0.5, 0.5, 'Screening 1', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の"Screening 1"を表示
pause(2);

fprintf("\nScreening 1 start\n")

while(1) % 要求打鍵速度を変えて繰り返す
    tap_interval = tap_interval_list(interval_index);
    cla; % 現在の図をクリア

    for count2 = 1:2 % 1つのtap_intervalにつき2trial行う
        num_trials = 2*(interval_index - 1) + count2 + repeat_count;

        % % sendCommand(daq,2); % Rest
        % text(0.5, 0.5, 'Rest', 'Color', 'b', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 青色の"Rest"を表示
        % pause(5); % 10秒間待機
        % cla;
        %
        % % sendCommand(daq,3); % Ready
        % text(0.5, 0.5, 'Ready', 'Color', 'r', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 赤色の"Ready"を表示
        % pause(2); % 2秒間待機


        while_count = 0; % 同一task内での打鍵判定のwhileループの回った回数
        num_keys_num_loops_update_marker = 0; % num_loops, num_keysを更新すると、1を格納して記録
        block.interval_index_recorder(num_trials) = interval_index; % そのblockで各trialのinterval_indexの推移を保存
        num_keystroke_sections = 1; % このtrialで何回目の打鍵判定区間か

        first_answer = 1; % 1task内での最初の打鍵の判定に使う。最初の打鍵が起こると0を保存

        block.tap_interval(num_trials) = tap_interval; % 各trialでの要求打鍵間隔を記録
        task_terminater = 0; % taskの終了時刻になると、1が格納されtask終了処理がアクティブになる
        draw_stopper = 0; % 同じ数字描画を繰り返さないための変数、0で描画可能、描画したら1を格納して描画をロック

        fprintf("\n速度レベル %d, trial %d\n", interval_index, count2)

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
                    block.tap_acceptance_start_times(num_trials, num_loops, num_keys) = GetSecs;
                    num_keys_num_loops_update_marker = 0; % num_loops, num_keysを更新すると、1を格納して記録
                end

                while_count = while_count + 1;
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();

                % 時間経過によるFail判定を内包した、1つの打鍵受付の終了判定
                if GetSecs > block.first_beep_time + (8 + num_keystroke_sections - 1/2)*tap_interval % ビープ音開始時を基準に、一つ前の打鍵受付終了時刻からtap_interval経過
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


        %% Judge Typing
        [latest_trial_judge, judge_parameters.keystroke_relaxation_range, judge_parameters.tolerance_percentage_1, judge_parameters.tolerance_percentage_2] = judge_typing(block, tap_interval, num_trials, num_loops, num_keys); % 最新trial
        Past_judge = block.judge; % 最新以外のtrial
        required_keystrokes(num_trials, 1) = size(latest_trial_judge,1);
        % fprintf("要求打鍵数 = %d\n", required_keystrokes(num_trials, 1))
        block.judge = NaN(num_trials, max(required_keystrokes)); % 新しくNaNで埋め尽くされたjudge配列を用意
        block.judge(num_trials, 1:required_keystrokes(num_trials, 1)) = latest_trial_judge; % 最新trialを格納

        for i = 1:num_trials-1 % 最新trial以外を格納
            block.judge(i, 1:required_keystrokes(i, 1)) = Past_judge(i, 1:required_keystrokes(i, 1)) ;
        end

        % 打鍵成功持続時間の計算と保存
        success_duration = calculate_success_duration(block, num_trials, trial_task_time, required_keystrokes(num_trials, 1));
        block.success_duration(num_trials) = success_duration;

        fprintf("interval_index = %d, 要求打鍵数 = %d\n", interval_index, required_keystrokes(num_trials, 1));
        fprintf("打鍵成功持続時間 = %d\n", block.success_duration(num_trials));

        % 次の打鍵速度レベルに進むかを判定
        if count2 == 2
            cla;
            fprintf("\n速度レベル適合判定\n")
            if interval_index ~= 1 && block.success_duration(num_trials-1) <= 15 && block.success_duration(num_trials) <= 15 % 2trial両方で15秒以内に打鍵失敗した場合、速度調節Screening1を一旦終了
                fprintf("Dropped out!\n")
                fprintf('直近2trialの打鍵成功持続時間 = %d, %d\n', block.success_duration(num_trials-1:num_trials));
                text(0.5, 0.5, 'Screening 1 Completed', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
                pause(2);
                fprintf("tap_interval = %d\n", tap_interval)
                fprintf("interval_index = %d\n", interval_index)
                cla;
                Screening1_terminater = 1;
                break % 2trial両方で15秒以内に打鍵失敗した場合、速度調節Screening1を一旦終了
            elseif interval_index == 1 && block.success_duration(num_trials - 1) <= 15 && block.success_duration(num_trials) <= 15
                fprintf("Try Again!\n")
                text(0.5, 0.5, 'Try Again!', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 初めの速度レベルで躓いたらやり直し
                pause(1);
                repeat_count = repeat_count + 2;
            else
                fprintf("Clear!\n")
                text(0.5, 0.5, 'Speed Up', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
                pause(1);
                interval_index = interval_index + 1; % 一つ上の速度レベルに移行
            end
            fprintf('直近2trialの打鍵成功持続時間 = %d, %d\n', block.success_duration(num_trials-1:num_trials));
        end

        blank_time_range = 5 - (GetSecs - task_end_time); % blankの時間が全体で5秒間になるよう調整

        cla;
        % sendCommand(daq,6); % Blank
        text(0.5, 0.5, 'Blank', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
        pause(blank_time_range); % 5秒間待機
        cla;

    end

    if Screening1_terminater == 1  % 2trial両方で15秒以内に打鍵失敗した場合、速度調節Screening1を一旦終了
        % sendCommand(daq,7); % 速度調節Screening1終了
        break
    end
end

%% Screening 1 の結果を保存
% 全trial（= 1block）終了後の保存
block_date = datetime('now', 'Format', 'yyyyMMdd_HHmmss');
block_filename = sprintf('Block_Result_S1_%s_%s.mat', block_date, participant_name);
save(block_filename, 'participant_name', 'block', 'interval_index', 'judge_parameters');






%% Screening 2
% sendCommand(daq,1); % Screening 2 開始
text(0.5, 0.5, 'Screening 2', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の"Screening 2"を表示
pause(2);
cla; % 現在の図をクリア

fprintf("\nScreening 2 start\n")

% interval_index = 12; % [Screening 2 単独のテスト用]

interval_index_list = [interval_index-1, interval_index, interval_index+1];  % Screening 1 決めた速度の2段階or1段階下からスタート [要検討]
interval_index = interval_index_list(1);

for num_speed = 1:3 % 3段階の速度で試験したら、Screening 2 を終了
    tap_interval = tap_interval_list(interval_index); % Screening 1 で決めた速度の前後含め3レベルで試験

    for count3 = 1:3 % 1つのtap_intervalにつき3trial行う
        num_trials = 3*(num_speed - 1) + count3;

        % % sendCommand(daq,2); % Rest
        % text(0.5, 0.5, 'Rest', 'Color', 'b', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 青色の"Rest"を表示
        % pause(5); % 10秒間待機
        % cla;
        %
        % % sendCommand(daq,3); % Ready
        % text(0.5, 0.5, 'Ready', 'Color', 'r', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 赤色の"Ready"を表示
        % pause(2); % 2秒間待機



        while_count = 0; % 同一task内での打鍵判定のwhileループの回った回数
        num_keys_num_loops_update_marker = 0; % num_loops, num_keysを更新すると、1を格納して記録
        block.interval_index_recorder(num_trials) = interval_index; % そのblockで各trialのinterval_indexの推移を保存
        num_keystroke_sections = 1; % このtrialで何回目の打鍵判定区間か

        first_answer = 1; % 1task内での最初の打鍵の判定に使う。最初の打鍵が起こると0を保存

        block.tap_interval(num_trials) = tap_interval; % 各trialでの要求打鍵間隔を記録
        task_terminater = 0; % taskの終了時刻になると、1が格納されtask終了処理がアクティブになる
        draw_stopper = 0; % 同じ数字描画を繰り返さないための変数、0で描画可能、描画したら1を格納して描画をロック
        fprintf("\n速度レベル %d, trial %d\n", interval_index, count3)

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
                    block.tap_acceptance_start_times(num_trials, num_loops, num_keys) = GetSecs;
                    num_keys_num_loops_update_marker = 0; % num_loops, num_keysを更新すると、1を格納して記録
                end

                while_count = while_count + 1;
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();

                % 時間経過によるFail判定を内包した、1つの打鍵受付の終了判定
                if GetSecs > block.first_beep_time + (8 + num_keystroke_sections - 1/2)*tap_interval % ビープ音開始時を基準に、一つ前の打鍵受付終了時刻からtap_interval経過
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

        %% Judge Typing
        [latest_trial_judge, judge_parameters.keystroke_relaxation_range, judge_parameters.tolerance_percentage_1, judge_parameters.tolerance_percentage_2] = judge_typing(block, tap_interval, num_trials, num_loops, num_keys); % 最新trial
        Past_judge = block.judge; % 最新以外のtrial
        required_keystrokes(num_trials, 1) = size(latest_trial_judge,1);
        % fprintf("要求打鍵数 = %d\n", required_keystrokes(num_trials, 1))
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


        blank_time_range = 5 - (GetSecs - task_end_time); % blankの時間が全体で5秒間になるよう調整

        % sendCommand(daq,6); % Blank
        text(0.5, 0.5, 'Blank', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
        pause(blank_time_range); % 5秒間待機
        cla;
    end



    fprintf("\n直近3trialの打鍵成功持続時間 = %d, %d, %d\n", block.success_duration(num_trials-2:num_trials));
    mean_success_duration(num_speed) = mean(block.success_duration(num_trials-2:num_trials)); % この速度での打鍵成功持続時間の平均（trial3回分）
    fprintf("mean_success_duration(%d) = %d\n", num_speed, mean_success_duration(num_speed))

    % text(0.5, 0.5, 'Stop', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % [検証用]
    % pause(5); % [検証用]

    % 次の速度へ移行
    interval_index = interval_index + 1;
end

% sendCommand(daq,7); % 速度調節全体の終了

if all(mean_success_duration < 15)
    fprintf("\nどの速度でも打鍵成功持続時間は基準値以下でした\n　速度を変えてやり直しなさい\n");
    max_value = max(mean_success_duration); % mean_error_timeの最大値を取得
    max_indices = find(mean_success_duration == max_value); % 最大値を持つ全インデックスを取得
    max_performance_index = max(max_indices); % 最大のインデックスを取得
    determined_interval_index = interval_index - (4 - max_performance_index); % やり直しでも、一応保存（save）を動かすために仮でinterval_indexを既定

else % Main blockでのスタート速度の決定
    fprintf("試験した速度レベルは%d, %d, %d\n", interval_index_list)
    fprintf("mean_success_duration ＝ %d, %d, %d\n", mean_success_duration);

    max_value = max(mean_success_duration); % mean_error_timeの最大値を取得
    max_indices = find(mean_success_duration == max_value); % 最大値を持つ全インデックスを取得
    max_performance_index = max(max_indices); % 最大のインデックスを取得
    determined_interval_index = interval_index - (4 - max_performance_index);
    fprintf("\nMain blockでの打鍵速度は、レベル%dの%d Hzで始める\n", determined_interval_index, 1/tap_interval_list(determined_interval_index));
    fprintf("ワークスペースで、block.success_durationの全貌を確認し、本当にこの打鍵速度で決定してよいのか検討せよ\n")
end


%% Screening 2 の結果を保存
if determined_interval_index ~= 0
    block_date = datetime('now', 'Format', 'yyyyMMdd_HHmmss');
    Speed_adj_filename = sprintf('Block_Result_S2_%s_%s.mat', block_date, participant_name);
    save(Speed_adj_filename, 'participant_name', 'block', 'mean_success_duration', 'interval_index_list', 'determined_interval_index', 'judge_parameters');
end







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
figure('Color', 'k', 'Position',[0.0010    0.0490    2.5600    1.3193]*500); % 黒色の背景を持つ新しい図を開く
axis off; % 軸を非表示にする
hold on;

text(0.5, 0.5, 'Check Session', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 白色の"Check Session"を表示
pause(3); % 3秒間待機
cla;

text(0.5, 0.5, 'Ready', 'Color', 'r', 'FontSize', 100, 'HorizontalAlignment', 'center'); % 赤色の"Ready"を表示
% sendCommand(daq,1); % Ready
pause(3); % 3秒間待機
cla;
text(0.5, 0.5, 'Go', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
pause(0.5); % 0.5秒間待機
cla;
text(0.5, 0.5, 'Open your eyes', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
drawnow
% sendCommand(daq,2); % 開眼安静開始
display_time = GetSecs;

while(1)
    if GetSecs-display_time > 60  % 60秒間待機
        cla;
        text(0.5, 0.5, 'Finished', 'Color', 'w', 'FontSize', 100, 'HorizontalAlignment', 'center');
        drawnow
        % sendCommand(daq,3); % 開眼安静終了
        break
    end
    WaitSecs(0.001);
end
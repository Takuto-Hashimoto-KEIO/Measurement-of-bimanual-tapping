clear
close all

% addpath('C:\Users\yokuto\OneDrive - keio.jp\牛馬研 M1~\修論研究\toolbox\Psychtoolbox-3-3.0.19.11\Psychtoolbox-3-3.0.19.11C:\Users\yokuto\Documents\MATLAB\Psychtoolbox-3-3.0.19.11\Psychtoolbox-3-3.0.19.11')
% savepath

%%
Startup_SA;
%%
ParaSet;

%%
% eye_open_rest
% eye_close_rest
% speed_adj
% practice_block
main_block


%% whilecount回数（鍵降下検出回数）検証用
% start_time = GetSecs;
% target_key = list_Key(num_keys);
% ListenChar(2);
% [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
% while(1)
%     fprintf('%d', keyIsDown)
%     WaitSecs(0.1);
%     if GetSecs - start_time >= 10
%         break
%     end
% end
% fprintf('\n')
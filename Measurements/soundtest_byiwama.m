Fs = 8192;
t = 1/Fs:1/Fs:14;
x = sin(2*pi*440*t);
sound(x,Fs);

%%
for i = 1 : 100
    fprintf("%02d\n",i);
    pause(0.05);
end
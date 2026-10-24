clear all
close all
clc

[Tempo1,reacaoy,acelz,deslocy]=textread('SIM01.DAT','%f %f %f %f ');

figure(1)

plot(Tempo1,reacaoy,'g-',Tempo1,deslocy,'b-',Tempo1,acelz,'m-');
title('','FontName','Times New Roman Negrito','FontSize',16)
xlabel('time[s]','FontName','Times New Roman','FontSize',24,'Rotation',0)
ylabel('force[N]','FontName','Times New Roman','FontSize',12,'Rotation',90)
grid on

figure(2)

plot(deslocy,reacaoy,'b-');
title('','FontName','Times New Roman Negrito','FontSize',16)
xlabel('d[m]','FontName','Times New Roman','FontSize',24,'Rotation',0)
ylabel('force[N]','FontName','Times New Roman','FontSize',12,'Rotation',90)
grid on

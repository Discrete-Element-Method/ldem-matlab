clear all
close all
clc

[Tempo,enex,Cinetica,Elastica,Dano,amort,Den]=textread('LET.ENE','%f %f %f %f %f %f %f');

figure(1)
plot(Tempo,Cinetica,'b.-',Tempo,Elastica,'m.-',Tempo,Dano,'r.-')
title(' ','FontName','Times New Roman Negrito','FontSize',16)
xlabel('Time [s]','FontName','Times New Roman','FontSize',18,'Rotation',0)
ylabel('Energy [Nm]','FontName','Times New Roman','FontSize',18,'Rotation',90)
legend('Kinetic','Elástic','Dissipate')
grid on


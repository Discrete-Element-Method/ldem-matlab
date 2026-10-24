
%

clear all
close all
clc

[bar, XXg, YYg, ZZg]=textread('BARI.txt','%f %f %f %f ');
%-----        DaDos       ------
M=5;    %nos na direção x
N=5 ;    %nos na direção y
L=706 ;    %nos na direção z
Lc=0.425E-3;
lcorx=Lc*2;%4*Lc
lcory=Lc*2;%4*Lc
lcorz=Lc*2;% 50*Lc
tetax=0%rotation angles to poles dominium respect the DEM dominium 
tetay=0
tetaz=0
Cv=0.20      % CV Gf=100%
semente=515;  % Seed campo

%computation of the bta value  using the CV
%%%%%%%%% RANDMEC %%%%

GM=35.;
err=1;
DG=0.01;

while abs(err)~=0
if err>0
    GM=GM-DG;
    GM
end
if err<0
    GM=GM+DG;
    DG=DG/2; 
    GM
end
DE=Cv^2+1-(gamma(1+2/GM))/(gamma(1+1/GM))^2;
err=fix(10000*DE);
end
BT=gamma(1+1/GM); %(consider that the mean is equal 1) 
GM
BT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%estou asumindo que o M e o mair valor de coord modular
% generation of poles dominium 

rand('seed',semente);

% Precisamos do NBT
NBA=size(bar,1);
NBT=NBA;

 
Xgrmax=0.0;
Xgrmin=0.0;
Ygrmax=0.0;
Ygrmin=0.0;
Zgrmax=0.0;
Zgrmin=0.0;




E=[deg2rad(tetaz), deg2rad(tetay), deg2rad(tetax)];
quat = quaternion(E,'euler','ZYX','frame');
 for i=1:NBT
   pointg=[XXg(i), YYg(i), ZZg(i)];            
   pointgr = rotatepoint(quat,pointg);
   XXgr(i)=pointgr(1);
   YYgr(i)=pointgr(2);
   ZZgr(i)=pointgr(3);
   
   if (XXgr(i)>Xgrmax)
     Xgrmax=XXgr(i);
   end 
  if (XXgr(i)<Xgrmin)
      Xgrmin=XXgr(i);
  end
  if (YYgr(i)>Ygrmax)
     Ygrmax=YYgr(i);
   end 
  if (YYgr(i)<Ygrmin)
      Ygrmin=YYgr(i);
  end
  if (ZZgr(i)>Zgrmax)
     Zgrmax=ZZgr(i);
   end 
  if (ZZgr(i)<Zgrmin)
      Zgrmin=ZZgr(i);
  end
   
 end
 
Xgrmax
Xgrmin
Ygrmax
Ygrmin
Zgrmax
Zgrmin
 Xp=floor((Xgrmin/lcorx)-1): ceil((Xgrmax/lcorx)+1),1;
 Yp=floor((Ygrmin/lcory)-1): ceil((Ygrmax/lcory)+1),1;
 Zp=floor((Zgrmin/lcorz)-1): ceil((Zgrmax/lcorz)+1),1;
 MMP= ceil((Xgrmax/lcorx)+1)-floor((Xgrmin/lcorx)-1)
 NNP=ceil((Ygrmax/lcory)+1)-floor((Ygrmin/lcory)-1)
 LLP=ceil((Zgrmax/lcorz)+1)-floor((Zgrmin/lcorx)-1)
 NPOL=LLP*NNP*MMP
 Xp=Xp*lcorx
 Yp=Yp*lcory
 Zp=Zp*lcorz 

% we create  a random value follows  the weibull distribution in each pole with coordinate xxp(ii),yyp(ii),zzp(ii),
% and keep in Phip(ii)
ii=0;
for k= 1:LLP
 for j=1:NNP
  for i=1:MMP
      ii=ii+1;
 XXp(ii)=Xp(i);
 YYp(ii)=Yp(j);
 ZZp(ii)=Zp(k);
 r=wblrnd(BT,GM);
 PHIp(ii)=r;
  end
 end
end
%only I rotate Xp,Yp,Zp to plot we dont need execute this task 
E=[deg2rad(tetaz), deg2rad(tetay), deg2rad(tetax)];
quat = quaternion(E,'euler','ZYX','frame');
 for i=1:MMP*NNP*LLP
   pointp=[XXp(i), YYp(i), ZZp(i)];            
   pointpr = rotatepoint(quat,pointp);
   XXpr(i)=pointpr(1);
   YYpr(i)=pointpr(2);
   ZZpr(i)=pointpr(3);
 end
 
 
 %computation of the dem PHIb(xgr,ygr,zgr) using the poles information
 NPOL1=((MMP-1)*(LLP-1)*(NNP-1))%Definicao do numer de modulos da malha polar
 
 for  i=1:NBT %llop over the baricentric DEM bars
  i1=i
     for ii=1:NPOL1
      %i2=ii
     K=floor((ii-0.1)/((MMP-1)*(NNP-1)));
     iii=ii-K*(MMP-1)*(NNP-1);
     KK=floor((iii-0.1)/(MMP-1));
     iiv=iii-KK*(MMP-1);
     IM=iiv;
     IN=KK;
     IL=K;
     iip=IM+IN*MMP+IL*MMP*NNP;
     % it is log for logical not for logaritm!!
        logx1= XXgr(i) >= XXp(iip);
        logx2= XXgr(i) <= (XXp(iip)+lcorx);
        logx = logx1 & logx2 ;
        logy1= YYgr(i) >= YYp(iip);
        logy2= YYgr(i) <= (YYp(iip)+lcory);
        logy = logy1 & logy2 ;
        logz1= ZZgr(i) >= ZZp(iip);
        logz2= ZZgr(i) <= (ZZp(iip)+lcorz);
        logz= logz1 & logz2;
       if (logx & logy & logz);
         i;
         iip;
         V1=PHIp(iip);
       
          V2=PHIp(iip+1);    
         
         V4=PHIp(iip+1+(MMP));
         
         V3=PHIp(iip+(MMP));
       
         V5=PHIp(iip+NNP*MMP);
      
         V6=PHIp(iip+1+NNP*MMP);
     
         V8=PHIp(iip+1+NNP*MMP+MMP);
     
         V7=PHIp(iip+NNP*MMP+MMP);
         
         
          
          
%            v7*--------* v8          
%             /:       /: 
%            / :      / :
%           /v5*-----/--*v6
%      v3  *--/----*v4 /   ^y 
%          : /     :  /    :  
%          :/      : /     : 
%       v1 *-------* v2    --->x
       

        PHIb(i)=V1+((V2-V1)*(XXgr(i)-XXp(iip))/lcorx)+((V3-V1)*(YYgr(i)-YYp(iip))/lcory)+((V5-V1)*(ZZgr(i)-ZZp(iip))/lcorz)+((V4-V3-V2+V1)*(XXgr(i)-XXp(iip))*(YYgr(i)-YYp(iip))/(lcorx*lcory))+((V6-V5-V3+V1)*(XXgr(i)-XXp(iip))*(ZZgr(i)-ZZp(ii))/(lcorx*lcorz))+((V7-V5-V3+V1)*(YYgr(i)-YYp(iip))*(ZZgr(i)-ZZp(iip))/(lcory*lcorz))+((V8-V7-V6+V5-V4+V3+V2-V1)*(XXgr(i)-XXp(iip))*(YYgr(i)-YYp(iip))*(ZZgr(i)-ZZp(iip))/(lcorx*lcory*lcorz));
       PHIb(i);
       if PHIb(i)<0
           i;
           iip;
           PHIb(i)=-PHIb(i);
           
       end
        ii=NPOL1;
       end
    end 
end
            
 
%plot the weibull distribution used             
 figure (1)
 x = linspace(0,30);
 plot(x,wblpdf(x,BT,GM),'b.-');
 hold off
 
%store the random values in the DEM nodes to use in the simulation  
 arquivo2='arquivo_rodrigo';
fid = fopen(arquivo2,'w');
fprintf(fid,'%6g\n',PHIb);
fclose(fid);



for j=1:NNP
for i=1:MMP
       
% xx1(i,j)=XXpr((j-1)*MMP+i);
% yy1(i,j)=YYpr((j-1)*MMP+i);
% ep1(i,j)=PHIp((j-1)*MMP+i);
xx1(i,j)=XXp((j-1)*MMP+i);
yy1(i,j)=YYp((j-1)*MMP+i);
ep1(i,j)=PHIp((j-1)*MMP+i);


if (j==1) 
    ep1v(i)=ep1(i,j);
end
 end 
end

figure(2)
mesh(xx1,yy1,ep1)
%pcolor(XXp,YYp,PHIp)
xlabel('x [m]','FontName','Times New Roman','FontSize',12,'Rotation',0)
ylabel('y [m]','FontName','Times New Roman','FontSize',12,'Rotation',0)
zlabel('t*','FontName','Times New Roman','FontSize',12,'Rotation',0)
M1=M-1
N1=N-1

for j=1:N1
for i=1:M1
       
xx2(i,j)=XXg((j-1)*M1+i);
yy2(i,j)=YYg((j-1)*M1+i);
ep2(i,j)=PHIb((j-1)*M1+i);
if (j==1) 
    ep2v(i)=ep2(i,j);
    Xg(i)=XXg(i,j);
end
 end 
end




figure(3)
mesh(xx2,yy2,ep2)
xlabel('x [m]','FontName','Times New Roman','FontSize',12,'Rotation',0)
ylabel('y [m]','FontName','Times New Roman','FontSize',12,'Rotation',0)
zlabel('t*','FontName','Times New Roman','FontSize',12,'Rotation',0)

ep1v(MMP+1)=0
Xp
ep2v

figure(4)
%plot(Xp,ep1v,'r.-')
plot( Xg,ep2v,'b.-',Xp,ep1v,'r.-')
%title('Energias vs. Tempo')
%xlabel('Tempo [s]','FontName','Times New Roman','FontSize',12,'Rotation',0)
xlabel('X[m]')
ylabel('ep')
legend('ep barras','ep polos' )
grid on


% 
% 

% 
% 


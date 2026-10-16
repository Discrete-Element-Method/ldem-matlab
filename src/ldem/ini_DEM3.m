function ini=ini_DEM3() 
%H1 this function  put initial values in  the global variables
% 
global INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED
%
% Variables setting
INT=168000
INB=2300000
U(3,INT)=0.0; % nodal displacement, U=x,V=y,W=z, i-1,i,i+1  time_ step
V(3,INT)=0.0;
W(3,INT)=0.0;
U0(INT)=0.0;% nodal displacements in the initial configuration
V0(INT)=0.0;%
W0(INT)=0.0;%
BDX(INT)=0;% boundary conditions  1=fix, 0=fix
BDY(INT)=0;
BDZ(INT)=0;
VLX(INT)=0.0;% nodal velocities
VLY(INT)=0.0;
VLZ(INT)=0.0;
ACX(INT)=0.0;%nodal acelerations
ACY(INT)=0.0;
ACZ(INT)=0.0;
FRX(INT)=0.0; %Nodal forces  in each step
FRY(INT)=0.0;
FRZ(INT)=0.0;
FX(INT)=0.0; %acumulated nodal forces
FY(INT)=0.0;
FZ(INT)=0.0;
MAS(INT)=0.0; % nodal masses with  corrections taken into account 
MSS(INT)=0.0;
CN(2*INB)=0;
%,ROMP,ROMP_OLD 
%!

%CN(2,INB)=0; %conectivity i, and j of each element
%ENR(INB)=0.0;% normal  specific stifness ENR(i)=YNGB(i)*ALPHA*(LI(i))^2
%EDG(INB)=0.0;% diagonal stifness bar EDG(B)=2.0D00*DELTA*(4.0D00/3.0D00)*ENR(B)/DSQRT(3.0D00)
%E1(INB)=0.0;% Normal stifness  in compression  taking into account if  the bar is in the border or is a internal bar
%E2(INB)=0.0;% Normal stifness  in tension
%LI(INB)=0.0; % cubic module length
%
%DEQB(INB)=0.0;%equivalent  distance for each element
%F(INB)=0.0;%element force
%YNGB(INB)=0.0; %Young modules in each bar
%GFRB(INB)=0.0; %toughness  in each bar
%LCRB(INB)=0.0; %LCR=DEQ*2.0D00*CAF/ALFA
%EPRB(INB)=0.0;% EPRB(i)=DSQRT(GFRB(i)/(YNGB(i)*DEQB(i)))
%EP(INB)=0.0;%the same of EPRB ??? %%%%%%%%
%SS(INB)=0.0; %the strain in the bar  the last step 
%EM(INB)=0.0;% te same that SS ?????? %%%%%%%%
%EN(2,INB)=0.0; %elastic energy in each bar computed in each step, 1 undamage, 2 damage. this information it isnt   used
%KR(INB)=0.0; %er(i)= kr(i)* ep(i) 
%KR1(INB)=0.0;%%%% it is not used 
%DSS(INB)=0.0; %the  derivative  of the strain STRRT in each  step
%DM(INB)=true; % damage index if DM=true bar is undamage
%FS(INB)=true; %failure index if DM= true bar is unfail, with partial damage or not.
%DM1(INB)=true;  
%FS1(INB)=true;
%TR(INB)=0.0;
%ansysColor=0
%
CAF=0.1385; %failure area  of each normal bars An(i)=CAF*LI(i)
%CUT=0.0;
DT=0.0; % time increment
GFR=0.0; %tougnhess , mean value 
DEQ=0.0;% critical distance  mean value 
LCR=0.0; %  critical length  
%SEED=0.0;
TEST=0; %number of test to stablish  characteristic of each specific problem 
EST=0; % establish differetn type of damping  |EstEST=0 ==> Amortecimento padrão (C=DF*M)
%!                           EST=1 ==> EST=0 + um amortecimento introduzido
%!                           na equação constitutiva com CON
%!                           EST=2 ==> EST=0, mas o coefic. de amortecimento
%!                           DF é multiplicado pelo índice de dano
DF=0.0;
DF1=0.0; %input damping value
DF2=0.0;
DMP1=0.0;  %%%  %  DMP1=(1.0D00-DF11*DT/2.0D00)%%%%must be global???
DMP2=0.0; %%%%must be global???
TDAF=0.0; %time in which  the damping 1 change to damping 2
CON=0.0; % values that   introduce  damping proportional to the  stifness  
%Label=0;
M=0; %number of modules Mx, N(y),  L(z) , 
N=0;
L=0;
M1=0;
N1=0;
L1=0;
MNL=0;% M*N*L
NNO=0;% NNO=MNL+M1*N1*L1 %%%%%%%%%%
NNS=0;% %%%%%%%%%
NNT=0;% total number of nodes 
NBA=0;%partial values %%%%%%%
NBS=0;%partial values %%%%%%%%
NBT=0; % total number of elements
INCO(10)=0;%the specific number of node indicated as input %%%%%%%
NCON(10)=0;%Number of nodes that could be identified
% OU2=0; % the number of output for print the results %%%%%%
% OU3=0;
% OU4=0;
% OU5=0;
% OU6=0;
% OU7=0;
% OU8=0;
% OU9=0;     
% PR3=0;  % numer os step to skip  when th result are save
% PR4=0; 
% PR5=0; 
% PR67=0; 
% PR8=0; 
% PR9=0; 
STEP=0;% current number of step  
NSTEP=0;% tital number of steps  
NDAMF=0;% step number correlated with TDAF
RUN=0; %current number of  simulation
NRUN=0; % total number of  simulations
LCO=0.0; %lenth of the cubic module
TIME=0.0; % current time
TTOT=0.0; % total time of the simulation
PSN=0.0;% poisson coeficient 
ROH=0.0; % density 
YNG=0.0; %mean young modulus 
EPR=0.0; %   
EPMAX=0.0; % maximum value of the critical strain
EPMIN=0.0; %minimum value of the critical strain
MEAN=0.0 ; %mean value of critical strain
COEV=0.0 ; %  variation coeficient of critical strain
ENEX=0.0 ;% External energy
ENCN=0.0;% kinetic energy 
ENEL=0.0;% Elastic energy
ENGD=0.0;% damage energy
ENDP=0.0;% damping  energy
ENIN=0.0;% internal  energy
DEN=0.0;% ENEX-ENIN
DERIV=0.0;% derivative of the ENGD
XB(INB)=0.0; %baricentric coordinates fo the elements
YB(INB)=0.0; 
ZB(INB)=0.0;
UBAR(INB)=0.0;%displacement in the baricentric of each bar
VBAR(INB)=0.0;
WBAR(INB)=0.0;

REACAOX=0.0;% summation of the reaction in x diretion
REACAOY=0.0;
REACAOZ=0.0;
STRAIN=0.0;
STRESS=0.0;
SEED=0; %seed number  to generate a perturbed mesh
%X
%Y
%Z
%  ,aaa
%  ,ReaV
%  ,vmax
%  ,tt1
%  ,vmax2
%  ,tt2
% VF1
% ,VF2
% ,VF3
% ,vmax3
% ,tt3
% ,VF4
% ,vmax4
% ,vmax5
% ,tt5
% ,VF6
% ,vmax6
% ,tt6
% ,dmax
% ,dmax2

 %  NK1
 % ,NK2
 % ,NK3
%      D2,PI,K1,K2,K3,DK1,DK2,DK3
%     PHI1,PHI2,PHI3,PHI4,AN
   % CVROH,CVYNG,CVGFR,CORRCAF
     %TENNORMZ,TENTANGX
      % RKX,RKZ,VF
%FOR1
%STR1
%FOR2
%STR2
%FOR3
%STR3
%FOR4
%STR4
%ROHN
     % BTA,GMA,IBT
      % LCORX,LCORY,LCORZ,NPTX,NPTY,NPTZ,NPTOTAL
     
    %  ,IPT
      % MPJ,NPJ,LPJ,MPI,NPI,LPI
     % IPT1,IPT2,IPT3,IPT4,IPT5,IPT6,IPT7,IPT8,IPT9
            % MP2,NP2,LP2,PHI
     % PMI,PNI,PLI,PHIV
     %xc,yc,vfarea,vfareal,time1
       %neib,iicont
      % krs,epp,constB
     % krsc,E2C,EMC
       %g51589,gg51589,g89116,gg89116,ggg89116,giv89116
       %  DESELX,DESELXMEDIO,SOMADESX,DESELY,DESELYMEDIO,      &
      %SOMADESY

ini=1;
end





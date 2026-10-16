
function ini=INTCO1 (MX,NX,LX,ST)
global  INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED 
%---------------------------------------------------
% !
% !  Esta subrotina é chamada pela subrotina conecti para definir as
% !  conectividades das barras internas dos módulos cúbicos.
% !

%!--------------------------------------------------------------------------
%       DO 10 K=1,LX
%       DO 10 J=1,NX
%       DO 10 I=1,MX
% !
%       NO=MNL+(K-1)*M1*N1+(J-1)*M1+I
%       B=NBA+(K-1)*MX*NX+(J-1)*MX+I
% !
%       CN(2*B-1)=NO
%       CN(2*B)=NO+ST
% !
%    10 CONTINUE
% !
%       NBA=NBA+MX*NX*LX 

% Create 3D index grids (I varies fastest)
[I, J, K] = ndgrid(1:MX, 1:NX, 1:LX);

% Compute all NO and B indices at once
NO = MNL + (K - 1) * M1 * N1 + (J - 1) * M1 + I;
B  = NBA + (K - 1) * MX * NX + (J - 1) * MX + I;

% Flatten and assign to CN
CN(2 * B(:) - 1) = NO(:);
CN(2 * B(:))     = NO(:) + ST;

% Update NBA
NBA = NBA + MX * NX * LX;

 ini=1;
 end

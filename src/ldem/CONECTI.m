
function ini=CONECTI()
% CONECTI  Define as conectividades de cada barra do reticulado.
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
% %---------------------------------------------------
%     Esta subrotina define as conectividades de cada barra.
% ------------------------------------------------------------
      NBA=0;
      NBS=0;
      NBT=0;
% !
      M2=M-2;
      N2=N-2;
      L2=L-2;
      MN=M*N;
      MN1=M1*N1;
% !
      ini=EXTCO1(M1,N,L,0,1,1,1);
      ini=EXTCO1(M,N1,L,1,0,1,M);
      ini=EXTCO1(M,N,L1,1,1,0,MN);
% !
      ini=INTCO1(M2,N1,L1,1);
      ini=INTCO1(M1,N2,L1,M1);
      ini=INTCO1(M1,N1,L2,MN1);
% !
      ini=DIACO1;
% !
      NBS=NBA;
      NI=NNO;
% !
      NBT=NBS; 
      
%
 ini=1;
 end


function ini=prepvar()
% PREPVAR  Inicializa variáveis de tempo, energia e dimensões derivadas do modelo.
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
      TIME=0.0D00;
      ENEX=0.0D00;
      ENIN=0.0D00;
      ENCN=0.0D00;
      ENDP=0.0D00;
      ENGD=0.0D00;
      DERIV=0.0D00;
      EPMAX=0.0D00;
      EPMIN=9.9D99;
%
      M1=M-1;
      N1=N-1;
      L1=L-1;
      MNL=M*N*L;
%
      DMP1=1.0D00-DF1*DT/2.0D00;
      DMP2=1.0D00+DF1*DT/2.0D00;
      NSTEP=int32(TTOT/DT);
      NDAMF=int32(TDAF/DT);
      CAF=0.1385D00;
      
      %
 ini=1;
 end

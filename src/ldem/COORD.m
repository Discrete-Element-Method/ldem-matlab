
function ini=COORD()
global   U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
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
% !  Esta subrotina faz a geração automática de coordenadas nodais.
% !
% !--------------------------------------------------------------------------
%!--------------------------------------------------------------------------
%!     DEFINIÇÃO DA QUANTIDADE TOTAL DE NÓS
      NNO=MNL+M1*N1*L1
      NNS=NNO
      NNT=NNS
%
     ini=COORDSUB(2,M1,1,N,1,L,0,M,N,1,2,1,2,1,2,0,0,0)
     ini=COORDSUB(1,1,1,N,1,L,0,M,N,0,0,1,2,1,2,0,0,0)
     ini=COORDSUB(M,M,1,N,1,L,0,M,N,0,-2*M1,1,2,1,2,0,0,0)
     ini=COORDSUB(1,M1,1,N1,1,L1,MNL,M1,N1,1,1,1,1,1,1,0,0,0)
%
      NI=NNO
%!
%       DO NO=1,NNT
%         U0(NO)=U(1,NO)
%         V0(NO)=V(1,NO)
%         W0(NO)=W(1,NO)
%       END DO
U0=U(1,:);
V0=V(1,:);
W0=W(1,:);
%
%
 ini=1;
 end

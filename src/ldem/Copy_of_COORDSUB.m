
function ini=COORDSUB (MI,MF,NI,NF,LLI,LF,ST,MX,NX,X1,Y1,X2,Y2,X3,Y3,C1,C2,C3)
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
%     
% !
% !  Esta subrotina é chamada pela subrotina coord para fazer a geração
% !  automática de coordenadas nodais.
% !
% !--------------------------------------------------------------------------
  

      %INTEGER I,J,K,LLI,LF,NI,NF,MI,MF,MX,NX
      %INTEGER X1,Y1,X2,Y2,X3,Y3,C1,C2,C3,NO,ST
%!--------------------------------------------------------------------------
      for K=LLI:LF
      for J=NI:NF
      for I=MI:MF
%
      NO=ST+(K-1)*MX*NX+(J-1)*MX+I;
%!
      U(1,NO)=(X1*I-Y1/2.0D00)*LCO;
      U(2,NO)=U(1,NO);
      U(3,NO)=U(2,NO);
      V(1,NO)=(X2*J-Y2/2.0D00)*LCO;
      V(2,NO)=V(1,NO);
      V(3,NO)=V(2,NO);
      W(1,NO)=(X3*K-Y3/2.0D00)*LCO;
      W(2,NO)=W(1,NO);
      W(3,NO)=W(2,NO);
%!
      BDX(NO)=C1;
      BDY(NO)=C2;
      BDZ(NO)=C3;
%!
      end
      end
      end
%!
  ini=1;
 end

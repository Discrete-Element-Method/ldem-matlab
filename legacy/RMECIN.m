
function ini=RMECIN (MX,NX,LX,ST)
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
% 
%       SUBROUTINE RMECIN (MX,NX,LX,ST)
% !     =================
% !
% !  Esta subrotina é chamada pela subrotina rmec para definir as
% !  propriedades mecânicas das barras internas dos módulos cúbicos.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER I,J,K,NO,B,MX,NX,LX
%       INTEGER NOI,NOF,ST
% !--------------------------------------------------------------------------
%       DO 10 K=1,LX
%       DO 10 J=1,NX
%       DO 10 I=1,MX
% !
%       NO=MNL+(K-1)*M1*N1+(J-1)*M1+I
%       NOI=NO
%       NOF=NO+ST
%       B=NBA+(K-1)*MX*NX+(J-1)*MX+I
% !
%       CALL DEFEP(B,0)
% 
% !
%    10 CONTINUE
% !
%       NBA=NBA+MX*NX*LX
% !
%       RETURN
%       END

% MODIFICAÇÕES RODRIGO
for K = 1:LX
        for J = 1:NX
            for I = 1:MX
                B = NBA + (K - 1) * MX * NX + (J - 1) * MX + I;
                E1(B) = ENR(B); % Lógica embutida do DEFEP
            end
        end
    end
    NBA = NBA + MX * NX * LX;
    ini = 1;
end
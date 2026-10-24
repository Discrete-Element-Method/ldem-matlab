
function ini=RMECEX (MX,NX,LX,C1,C2,C3,ST)
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
%       SUBROUTINE RMECEX (MX,NX,LX,C1,C2,C3,ST)
% !     =================
% !
% !  Esta subrotina é chamada pela subrotina rmec para definir as
% !  propriedades mecânicas das barras externas dos módulos cúbicos.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER I,J,K,NO,B,MX,NX,LX
%       INTEGER NOI,NOF,ST
%       INTEGER TYPES,C1,C2,C3
% !--------------------------------------------------------------------------
%       DO 10 K=1,LX
%       DO 10 J=1,NX
%       DO 10 I=1,MX
% !
%       TYPES=0
%       IF ((I.EQ.1).OR.(I.EQ.M)) TYPES=TYPES+C1
%       IF ((J.EQ.1).OR.(J.EQ.N)) TYPES=TYPES+C2
%       IF ((K.EQ.1).OR.(K.EQ.L)) TYPES=TYPES+C3
% !
%       NO=(K-1)*M*N+(J-1)*M+I
%       B=NBA+(K-1)*MX*NX+(J-1)*MX+I
%       NOI=NO
%       NOF=NO+ST
% !
%       
%       CALL DEFEP(B,TYPES)
% 
% !
%    10 CONTINUE
% !
%       NBA=NBA+MX*NX*LX
% !
%       RETURN
%       END
% !

for K = 1:LX
    for J = 1:NX
        for I = 1:MX
            TYPES = 0;
            if (I == 1) || (I == M)
                TYPES = TYPES + C1;
            end
            if (J == 1) || (J == N)
                TYPES = TYPES + C2;
            end
            if (K == 1) || (K == L)
                TYPES = TYPES + C3;
            end

            NO  = (K - 1) * M * N + (J - 1) * M + I;
            B   = NBA + (K - 1) * MX * NX + (J - 1) * MX + I;
            NOI = NO;
            NOF = NO + ST;
            
            DEFEP(B, TYPES);

        end
    end
end

%--------------------------------------------------------------------------
% Update global counter
%--------------------------------------------------------------------------
NBA = NBA + MX * NX * LX;
 ini=1;
 end

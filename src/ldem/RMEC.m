function ini=RMEC()
% RMEC  Calcula as propriedades mecânicas das barras (exteriores, interiores e diagonais).
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

 NBA=0
 NBS=0
 NBT=0
%!
M2  = M  - 2;
N2  = N  - 2;
L2  = L  - 2;
MN  = M  * N;
MN1 = M1 * N1;
%--------------------------------------------------------------------------
% Calls to exterior / interior / diagonal routines
%--------------------------------------------------------------------------
RMECEX(M1, N,  L,  0, 1, 1, 1);
RMECEX(M,  N1, L,  1, 0, 1, M);
RMECEX(M,  N,  L1, 1, 1, 0, MN);
%
RMECIN(M2, N1, L1, 1);
RMECIN(M1, N2, L1, M1);
RMECIN(M1, N1, L2, MN1);
%
RMECDI();
%
NBS = NBA;
NI  = NNO;
NBT = NBS;
% 
% !
%       SUBROUTINE RMEC
% !     ===============
% !
% !  
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER M2,N2,L2,MN,MN1
% !--------------------------------------------------------------------------
%       NBA=0
%       NBS=0
%       NBT=0
% !
%       M2=M-2
%       N2=N-2
%       L2=L-2
%       MN=M*N
%       MN1=M1*N1
% !
%       
%       CALL RMECEX (M1,N,L,0,1,1,1)
%       CALL RMECEX (M,N1,L,1,0,1,M)
%       CALL RMECEX (M,N,L1,1,1,0,MN)
% !
%      
%       CALL RMECIN (M2,N1,L1,1)
%       CALL RMECIN (M1,N2,L1,M1)
%       CALL RMECIN (M1,N1,L2,MN1)
%      
%       CALL RMECDI
% !
%       NBS=NBA
%       NI=NNO
%       NBT=NBS
% !
%       RETURN
%       END

% MODIFICAÇÃO RODRIGO
% ========================================================
    % VETORIZAÇÃO GLOBAL: Substitui milhões de chamadas ao DEFEP
    % Aplica as propriedades comuns a todas as barras instantaneamente
    % ========================================================
    EP(1:NBT) = EPRB(1:NBT);
    KR(1:NBT) = LCRB(1:NBT) ./ LI(1:NBT);
    E2(1:NBT) = E1(1:NBT);

    ini = 1;
end
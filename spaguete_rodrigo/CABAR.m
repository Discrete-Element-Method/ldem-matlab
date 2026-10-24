
function ini=  CABAR (fid_Lei)
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

%!--------------------------------------------------------------------------
%       SUBROUTINE CABAR
% !     ================
%       
% !
% !  DATA:  22/03/1993
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina realiza um loop sobre todas as barras para calcular as
% !  novas forças atuantes a partir da nova configuração.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=20,INCON=8)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER B,NOI,NOF,R,II,JJ,KK,IMOD
%       INTEGER VB(26)
%       DOUBLE PRECISION DU,DV,DW,DU1,DV1,DW1,DCX,DCY,DCZ
%       DOUBLE PRECISION LBAR,LBAR1,STR,LSTR,STRRT,FORCE
% !--------------------------------------------------------------------------
%       DO B=1,NBT
%       NOI=CN(2*B-1)
%       NOF=CN(2*B)
%       DU=U(2,NOF)-U(2,NOI)
%       DV=V(2,NOF)-V(2,NOI)
%       DW=W(2,NOF)-W(2,NOI)
%       LBAR=DSQRT(DU*DU+DV*DV+DW*DW) 
%       DU1=U(1,NOF)-U(1,NOI)
%       DV1=V(1,NOF)-V(1,NOI)
%       DW1=W(1,NOF)-W(1,NOI)
%       LBAR1=DSQRT(DU1*DU1+DV1*DV1+DW1*DW1)
%       DCX=DU/LBAR
%       DCY=DV/LBAR
%       DCZ=DW/LBAR
%       STR=(LBAR-LI(B))/LI(B)
%       LSTR=(LBAR1-LI(B))/LI(B)
%       STRRT=(STR-LSTR)/DT
%       DSS(B)=STRRT
%       CALL CONSTIT (B,STR,STRRT,FORCE,R)
%     ! CALL CONSTIT9(B,STR,STRRT,FORCE,R) 
%       FRX(NOI)=FRX(NOI)+FORCE*DCX
%       FRX(NOF)=FRX(NOF)-FORCE*DCX
%       FRY(NOI)=FRY(NOI)+FORCE*DCY
%       FRY(NOF)=FRY(NOF)-FORCE*DCY
%       FRZ(NOI)=FRZ(NOI)+FORCE*DCZ
%       FRZ(NOF)=FRZ(NOF)-FORCE*DCZ
% !
% !     ISSO GRAVA A FORÇA DE CADA BARRA
%       F(B)=FORCE
% !    
%     !if (b.eq.1) then
%   !    write(*,*)b,str,force,LBAR
%    !endif
%       END DO
%       RETURN
%       END

% CABAR
% =====
%
%  DATA:  22/03/1993
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina realiza um loop sobre todas as barras para calcular as
%  novas forças atuantes a partir da nova configuração.
%
%  MATLAB translation. The original Fortran used a COMMON block; here the
%  shared data is passed in/out via a struct S with fields:
%     S.NBT, S.CN, S.U, S.V, S.W, S.LI, S.DT,
%     S.DSS, S.FRX, S.FRY, S.FRZ, S.F
%  (and any other fields needed by the CONSTIT routine).

%--------------------------------------------------------------------------
%  PARAMETER (INN=1.2E6, INB=6E6, IRU=20, INCON=8)
%  These parameters are not used in this routine.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%  Loop over all bars
%--------------------------------------------------------------------------
  
% CABAR
% =====
%
%  DATA:  22/03/1993
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina realiza um loop sobre todas as barras para calcular as
%  novas forças atuantes a partir da nova configuração.
%
%  MATLAB translation using GLOBAL variables instead of COMMON.
%  The following global variables must be defined in the workspace:
%     NBT, CN, U, V, W, LI, DT, DSS, FRX, FRY, FRZ, F
%  (and any others required by CONSTIT).



%--------------------------------------------------------------------------
%  PARAMETER (INN=1.2E6, INB=6E6, IRU=20, INCON=8)
%  These parameters are not used in this routine.
%--------------------------------------------------------------------------
NUMBAR = 518689;

for B = 1:NBT
        NOI = CN(2*B - 1);
        NOF = CN(2*B);

        % Cinemática atual (U,V,W no tempo 2)
        DU = U(2, NOF) - U(2, NOI);
        DV = V(2, NOF) - V(2, NOI);
        DW = W(2, NOF) - W(2, NOI);
        LBAR = sqrt(DU*DU + DV*DV + DW*DW);

        % Cinemática do passo anterior (U,V,W no tempo 1)
        DU1 = U(1, NOF) - U(1, NOI);
       DV1 = V(1, NOF) - V(1, NOI);
        DW1 = W(1, NOF) - W(1, NOI);
        LBAR1 = sqrt(DU1*DU1 + DV1*DV1 + DW1*DW1);

        % Cossenos diretores
        DCX = DU / LBAR;
        DCY = DV / LBAR;
        DCZ = DW / LBAR;

        % Deformações (Strain)
        STR   = (LBAR  - LI(B)) / LI(B);
        LSTR  = (LBAR1 - LI(B)) / LI(B);
        STRRT = (STR - LSTR) / DT;

        DSS(B) = STRRT;

        % =================================================================
        % RELAÇÃO CONSTITUTIVA INCORPORADA (Substitui chamada ao CONSTIT.m)
        % =================================================================
        SS(B) = STR;
        ER    = KR(B) * EP(B);
        
        if STR >= ER
            E2(B) = 0.0;
            FORCE = 0.0;
            EM(B) = ER;
            
            if FS(B)
                FS(B) = false;
                DM(B) = false;
            end
            
        elseif STR >= EM(B)
            AUX   = (STR - EP(B)) / (KR(B) - 1.0);
            AUX   = E1(B) * (EP(B) - AUX);
            E2(B) = AUX / STR;
            EM(B) = STR;
            FORCE = AUX + E2(B) * CON * STRRT;
            
            if DM(B)
                DM(B) = false;
            end
            
        elseif STR >= 0.0
            FORCE = E2(B) * STR + E2(B) * CON * STRRT;
            
        else
            FORCE = E1(B) * STR + E1(B) * CON * STRRT;
        end

        % Gravação isolada da barra de rastreio
        if B == NUMBAR && fid_Lei ~= -1
            fprintf(fid_Lei, '%25.12E   %25.12E   %25.12E   %25.12E   %25.12E   %25.12E\n', ...
                    TIME, STR, SS(B), ER, FORCE, EP(B));
        end
        % =================================================================

        % Montagem do vetor de forças globais nos nós
        FRX(NOI) = FRX(NOI) + FORCE*DCX;
        FRX(NOF) = FRX(NOF) - FORCE*DCX;
        FRY(NOI) = FRY(NOI) + FORCE*DCY;
        FRY(NOF) = FRY(NOF) - FORCE*DCY;
        FRZ(NOI) = FRZ(NOI) + FORCE*DCZ;
        FRZ(NOF) = FRZ(NOF) - FORCE*DCZ;

        F(B) = FORCE;
    end

    ini = 1;
end
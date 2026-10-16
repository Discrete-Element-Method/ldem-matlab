
function ini=DEFEP(B, TYPES)
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
%       SUBROUTINE DEFEP(B,TYPES)
% !     ===================
% !
% !  Esta subrotina é chamada pelas subrotinas rmecex, rmecin e rmecdi para
% !  definir a aleatoriedade das propriedades mecânicas das barras.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER B,TYPES
%       DOUBLE PRECISION RED,NOR,AUX,NOI,NOF
% !--------------------------------------------------------------------------
%       IF (TYPES.EQ.0) RED=1.00D00
%       IF (TYPES.EQ.1) RED=0.50D00
%       IF (TYPES.EQ.2) RED=0.25D00
% !
%       IF (TYPES.LT.3) THEN
%         E1(B)=ENR(B)*RED
%     
%       ELSE
%         E1(B)=EDG(B)
%       END IF
% !
%      
%       E2(B)=E1(B)
%       EP(B)=EPRB(B)
%       KR(B)=(LCRB(B)/LI(B))
%       
%     
%       IF (KR(B).LT.1.01) THEN
%         WRITE (*,*)
%         WRITE (*,*) '  KR < 1.01CCC  '
%         WRITE (*,*)
%         STOP ! CUIDADO COM ISTO. VER EXPLICAÇÃO NA DISSERTAÇÃO DO MARCELO
%       END IF
%       RETURN
%       END
if TYPES == 0
    RED = 1.00;
elseif TYPES == 1
    RED = 0.50;
elseif TYPES == 2
    RED = 0.25;
end

%--------------------------------------------------------------------------
% Assign E1 (random for exterior/interior bars; deterministic for diagonals)
%--------------------------------------------------------------------------
if TYPES < 3
    E1(B) = ENR(B)*RED;
else
    E1(B) = EDG(B);
end

%--------------------------------------------------------------------------
% Other mechanical properties
%--------------------------------------------------------------------------
E2(B) = E1(B);
EP(B) = EPRB(B);
KR(B) = LCRB(B)/ LI(B);

%--------------------------------------------------------------------------
% Sanity check on the stiffness ratio KR
%--------------------------------------------------------------------------
if KR(B)< 1.01
    fprintf('\n');
    fprintf('  KR < 1.01CCC  \n');
    fprintf('\n');
    error('DEFEP: KR < 1.01 — see explanation in Marcelo''s dissertation.');
end

  ini=1;
  end

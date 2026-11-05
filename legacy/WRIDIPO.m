
function ini=WRIDIPO(fid16, fid17)
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
% !
%   !--------------------------------------------------------------------------
% !--------------------------------------------------------------------------
% !
%       SUBROUTINE WRIDIPO
% !     ==================
% !
% !  DATA:  22/03/1993
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina grava os resultados nos arquivos DISNAME e POSNAME.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
% !     ADAPTAR PARA CADA EXEMPLO TESTADO
% !--------------------------------------------------------------------------
%      
%       IF (TEST.EQ.102) THEN
% !
%       WRITE (17,'(3(E25.12,3X))') TIME,                                 
%      &ACX(NCON(1)),ACX(NCON(2))
%       !
%       END IF
% 
%      
% 
%       RETURN
%       END
% !
% !--------------------------------------------------------------------------


% WRIDIPO
% =======
%
%  DATA:  22/03/1993
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina grava os resultados nos arquivos DISNAME e POSNAME.
%
%  MATLAB translation using GLOBAL variables instead of COMMON.
%
%  Inputs:
%     fid16 -> file identifier for LET.DIS  (DISNAME)
%     fid17 -> file identifier for LET.POS  (POSNAME)

% -------------------------------------------------------------------------
%  Global variables (equivalent to the COMMON block)
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
%  ADAPT FOR EACH TEST EXAMPLE
% -------------------------------------------------------------------------
if TEST == 102

    % Write to LET.POS (unit 17 in Fortran -> fid17)
    fprintf(fid17, '%25.12e   %25.12e   %25.12e\n', ...
            TIME, ACX(NCON(1)), ACX(NCON(2)));

end





ini=1;
    end

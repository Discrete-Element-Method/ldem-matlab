
function ini=CALRES()
% CALRES  Calcula valores que serão guardados no arquivo de resultados.
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

%    !--------------------------------------------------------------------------
% !--------------------------------------------------------------------------
% !
%       SUBROUTINE CALRES
% !     =================
% !
% !  DATA:  22/03/1993
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina calcula valores que serão guardados no arquivo RESNAME.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
% 
%       DOUBLE PRECISION ReacaoX2,COD_L,COD_R,DELTA
%          
%    
% 	CHARACTER*20 NAME
% !--------------------------------------------------------------------------
% !     ADAPTAR PARA CADA EXEMPLO TESTADO
% !--------------------------------------------------------------------------
%         if (test.eq.102)then 
%          
%          REACAOX = 0.0D00
%          REACAOY = 0.0D00
%          REACAOZ = 0.0D00
%          REACAOX2 = 0.0D00
%          SOMADESZ = 0.0D00
%          SOMADESY = 0.0D00
%          SOMADESX = 0.0D00
%          COD_L=0.0D00
%          COD_R=0.0D00
%          DELTA=0.0D00
%     !   
%                  DO I=1,NNT
%      
%               IF((BDY(I).EQ.1).AND.(V0(I).GE.(LCO*(N1-0.51)) ))then 
%               
%             REACAOY=REACAOY+FRY(I)
%             
%               END IF
%          END DO
% 
%     !
%       IF (PR9.EQ.OU8) THEN
%         NAME = 'SIM01.DAT'
%         OPEN (21,FILE=NAME)
%       WRITE(21,'(4(E25.12,3X))')TIME,REACAOY,Acz(89214),V(2,154928)
% 	  PR9=1
%       ELSE
%         PR9=PR9+1
%       END IF
%       ENDIF
%       RETURN
%       END
% !--------------------------------------------------------------------------

% CALRES
% ======
%
%  DATA:  22/03/1993
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina calcula valores que serão guardados no arquivo RESNAME.
%
%  MATLAB translation using GLOBAL variables instead of COMMON.

% -------------------------------------------------------------------------
%  Global variables (equivalent to the COMMON block)
% -------------------------------------------------------------------------
%-----------------------------------------------------
%  

% -------------------------------------------------------------------------
%  ADAPT FOR EACH TEST EXAMPLE
% -------------------------------------------------------------------------
if TEST == 102

    REACAOX  = 0.0;
    REACAOY  = 0.0;
    REACAOZ  = 0.0;
    REACAOX2 = 0.0;
    SOMADESZ = 0.0;
    SOMADESY = 0.0;
    SOMADESX = 0.0;
    COD_L    = 0.0;
    COD_R    = 0.0;
    DELTA    = 0.0;

    % ---------------------------------------------------------------------
    for I = 1:NNT
        if (BDY(I) == 1) && (V0(I) >= (LCO*(N1 - 0.51)))
            REACAOY = REACAOY + FRY(I);
        end
    end

    % ---------------------------------------------------------------------
%     if PR9 == OU8
        NAME = 'SIM01.DAT';
        fid21 = fopen(NAME, 'w');
        fprintf(fid21, '%25.12e   %25.12e   %25.12e   %25.12e\n', ...
                TIME, REACAOY, ACZ(100), V(2,100));
        fclose(fid21);
  %      PR9 = 1;
   % else
   %     PR9 = PR9 + 1;
   % end

end

  ini=1;
 end

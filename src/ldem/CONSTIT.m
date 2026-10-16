function ini=  CONSTIT (B,STR,STRRT,FORCE,R,fid_Lei)
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

%   SUBROUTINE CONSTIT (B,STR,STRRT,FORCE,R)
% !     ==================
% !
% !  Esta subrotina é chamada pela subrotina cabar para modelar a relação
% !  constitutiva de cada barra de acordo com um diagrama bilinear força vs.
% !  deformação, com amolecimento ("strain softening'). O processo de
% !  descarga é modelado de acordo com a hipótese de dano-elástico.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=20,INCON=8)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER B,R,RESP,NUMBAR
%       DOUBLE PRECISION AUX,STR,STRRT,ER,FORCE
%  !--------------------------------------------------------------------------
%       SS(B)=STR
%       ER=KR(B)*EP(B)
%       
%       R=0 
%    
% !--------------------------------------------------------------------------
% !     VERIFICA SE OCORRE FRATURA
% !--------------------------------------------------------------------------
% !      IF (STR.GE.EM(B)) THEN
% !        IF (RESP.EQ.1) THEN
% !          GO TO 5
% !        END IF
% ! !       WRITE (*,*)
% !  !      WRITE (*,*) '  OCORREU FRATURA.  DESEJA CONTINUAR?  '
% !  !      WRITE (*,*) '  SE SIM, DIGITE 1. SE NAO, DIGITE 2.  '
% !!       READ (*,*) RESP
% !    !    WRITE (*,*)
% !	resp=1
% !        IF (RESP.EQ.1) THEN
% !          GO TO 5
% !        ELSE
% !          STOP
% !        END IF
% !    5 END IF
% !--------------------------------------------------------------------------
%       IF (STR.GE.ER)     GO TO 30
%       IF (STR.GE.EM(B))  GO TO 20
%       IF (STR.GE.0.0D00) GO TO 10
%   ! PARA ACOMPANHAR A EVOLUCAO DE UMA BARRA, DEFINIR SEU NUMERO EM NUMBAR 
%       NUMBAR=7014    
% !--------------------------------------------------------------------------
% !  Consideração do amortecimento na relação constitutiva: CON > 0.0D00
% !--------------------------------------------------------------------------
%        FORCE=E1(B)*STR+E1(B)*CON*STRRT
%      
%            !      Para acompanhar uma barra
%        IF (B.EQ.NUMBAR) THEN   ! colocar número da barra que se quer seguir
%        WRITE (19,'(6(E25.12,3X))') TIME,STR,SS(B),ER,Force,EP(B)
%      
%         END IF
% 
%           
%       GO TO 40
% !--------------------------------------------------------------------------
%    
% 10    FORCE=E2(B)*STR+E2(B)*CON*STRRT
%           !!     Para acompanhar uma barra
%             IF (B.EQ.NUMBAR) THEN  
%                WRITE (19,'(6(E25.12,3X))') TIME,STR,SS(B),ER,Force,EP(B)
%           !
%          END IF
%           
%       
%       GO TO 40
% !--------------------------------------------------------------------------
%    20 AUX=(STR-EP(B))/(KR(B)-1.0D00)
%       AUX=E1(B)*(EP(B)-AUX)
%       E2(B)=AUX/STR
%       EM(B)=STR
%       FORCE=AUX+E2(B)*CON*STRRT
%      
%               IF (B.EQ.NUMBAR) THEN   ! colocar número da barra que se quer seguir
%         WRITE (19,'(6(E25.12,3X))') TIME,STR,SS(B),ER,Force,EP(B)
%       
%      
%           END IF
%           
%      
%       IF (DM(B)) THEN
%         DM(B)=.FALSE.
%       END IF
% 
%       GO TO 40
% !--------------------------------------------------------------------------
%    30 E2(B)=0.0D00
%       FORCE=0.0D00
%       EM(B)=ER
%    
%       !     !     Para acompanhar uma barra
%             IF (B.EQ.NUMBAR) THEN   ! colocar número da barra que se quer seguir
%         WRITE (19,'(6(E25.12,3X))') TIME,STR,SS(B),ER,Force,EP(B)
%     
%       
%           END IF
%  
%       IF (FS(B)) THEN
%         R=1
%         FS(B)=.FALSE.
%         DM(B)=.FALSE.
%       END IF
%      
%    40  RETURN
%       END
% !
% ==================
%
%  Esta subrotina é chamada pela subrotina CABAR para modelar a relação
%  constitutiva de cada barra de acordo com um diagrama bilinear força vs.
%  deformação, com amolecimento ("strain softening"). O processo de
%  descarga é modelado de acordo com a hipótese de dano-elástico.
%
% Translates the Fortran SUBROUTINE CONSTIT.


%--------------------------------------------------------------------------
% Parameters (preserved for fidelity; unused here)
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%  Record current strain and compute the fracture reference strain
%--------------------------------------------------------------------------
SS(B) = STR;
ER    = KR(B) * EP(B);
R     = 0;

%--------------------------------------------------------------------------
%  Bar to be tracked (writes diagnostic rows to Lei_Barra.TXT)
%--------------------------------------------------------------------------
NUMBAR   = 7014;                  % change to follow a different bar
TrackBar = (B == NUMBAR);

%==========================================================================
%  Branch 1: STR >= ER  -->  bar fully broken (Fortran label 30)
%==========================================================================
if STR >= ER

    E2(B)  = 0.0;
    FORCE  = 0.0;
    EM(B)  = ER;

    if TrackBar
        fprintf(fid_Lei, '%25.12E   %25.12E   %25.12E   %25.12E   %25.12E   %25.12E\n', ...
                TIME, STR, SS(B), ER, FORCE, EP(B));
    end

    if FS(B)
        R     = 1;
        FS(B) = false;
        DM(B) = false;
    end

%==========================================================================
%  Branch 2: EM(B) <= STR < ER  -->  strain softening (Fortran label 20)
%==========================================================================
elseif STR >= EM(B)

    AUX    = (STR - EP(B)) / (KR(B) - 1.0);
    AUX    = E1(B) * (EP(B) - AUX);
    E2(B)  = AUX / STR;
    EM(B)  = STR;
    FORCE  = AUX + E2(B) * CON * STRRT;

    if TrackBar
        fprintf(fid_Lei, '%25.12E   %25.12E   %25.12E   %25.12E   %25.12E   %25.12E\n', ...
                TIME, STR, SS(B), ER, FORCE, EP(B));
    end

    if DM(B)
        DM(B) = false;
    end

%==========================================================================
%  Branch 3: 0 <= STR < EM  -->  elastic reload/unload in tension
%             (Fortran label 10)
%==========================================================================
elseif STR >= 0.0

    FORCE = E2(B) * STR + E2(B) * CON * STRRT;

    if TrackBar
        fprintf(fid_Lei, '%25.12E   %25.12E   %25.12E   %25.12E   %25.12E   %25.12E\n', ...
                TIME, STR, SS(B), ER, FORCE, EP(B));
    end

%==========================================================================
%  Branch 4 (default): STR < 0  -->  linear elastic in compression
%==========================================================================
else

    FORCE = E1(B) * STR + E1(B) * CON * STRRT;

    if TrackBar
        fprintf(fid_Lei, '%25.12E   %25.12E   %25.12E   %25.12E   %25.12E   %25.12E\n', ...
                TIME, STR, SS(B), ER, FORCE, EP(B));
    end

end



ini=1;
 end

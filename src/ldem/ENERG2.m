
function ini=ENERG2(fid_EnB)
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
% !!
%       SUBROUTINE ENERG2
% !     =================
% !
% !  Esta subrotina avalia o desempenho da energia a cada passo de
% !  integração.
% !
% !--------------------------------------------------------------------------
% !  DEFINIÇÃO DAS VARIÁVEIS REFERENTES A DIFERENTES TIPOS DE ENERGIA QUE
% !  SERÃO CALCULADAS
% !
% !  ENEX = Trabalho externo realizado sobre o modelo
% !  ENIN = Energia interna total dissipada ou acumulada
% !  ENCN = Energia cinética total do modelo
% !  ENEL = Energia elástica total presente no modelo
% !  ENDP = Energia dissipada por amortecimento
% !  ENGD = Energia dissipada pelo efeito de amolecimento (strain softening)
% !         (somatória sobre todas as barras)
% !  DEN  = Diferença entre energia externa e interna
% !         (quanto menor este valor, mais preciso é o resultado)
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER B,KL
%       DOUBLE PRECISION DU1,DU2
%       DOUBLE PRECISION DEF,AREA
% !--------------------------------------------------------------------------
%       ENCN=0.0D00
%       ENEL=0.0D00
%       ENGD=0.0D00
%       DERIV=0.0D00
%       DEN=0.0D00 
%       IF (STEP.EQ.1) DU1=0.0D00
%       IF (STEP.EQ.1) DU2=0.0D00
% !--------------------------------------------------------------------------
% !     CÁLCULO DA ENERGIA CINÉTICA ENCN
% !--------------------------------------------------------------------------
%       DO I=1,NNT
%         IF ((I.LE.NNO)) THEN
%           ENCN=ENCN+MAS(I)*VLX(I)*VLX(I)/2.0D00
%           ENCN=ENCN+MAS(I)*VLY(I)*VLY(I)/2.0D00
%           ENCN=ENCN+MAS(I)*VLZ(I)*VLZ(I)/2.0D00
%         END IF
%       END DO
% !--------------------------------------------------------------------------
% !     CÁLCULO DA ENERGIA ELÁSTICA ENEL
% !--------------------------------------------------------------------------
%       DO B=1,NBT
% !
%       KL=2
% !     Divide-se por 2 a expressão se as barras são as da borda ou simétrica
% !     Isto implica KL=4
%       IF (B.GT.NBA) KL=4
%       DEF=SS(B)*SS(B)*LI(B)/KL
%       IF (SS(B).GE.0.0D00) THEN
%         ENEL=ENEL+E2(B)*DEF
%         EN(1,B)=E2(B)*DEF
%       ELSE
%         ENEL=ENEL+E1(B)*DEF
%         EN(1,B)=E1(B)*DEF
%       END IF
% !--------------------------------------------------------------------------
% !     CÁLCULO DA ENERGIA DISSIPADA POR AMOLECIMENTO (STRAIN SOFTENING) ENGD
% !--------------------------------------------------------------------------
% !     Barras rompidas e danificadas
%       IF (.NOT.DM(B)) THEN
%         AREA=E1(B)*EP(B)*EP(B)-E2(B)*EM(B)*EM(B)+(E1(B)*EP(B)+E2(B)*        &
%      &  EM(B))*(EM(B)-EP(B))
%         AREA=LI(B)*AREA/KL
%         
%         IF (B.EQ.7014) THEN   ! colocar número da barra que se quer seguir
%         WRITE (20,'(2(E12.6,3X))') TIME,AREA  
%         END IF
%         
%         ENGD=ENGD+AREA
%         EN(2,B)=AREA
%         
% !---------------------------------------------------------------      
%         
%       END IF
% !
% !     Armazena só energia dissipada pelas barras rompidas
%       IF ((.NOT.DM(B)).AND.(.NOT.FS(B))) THEN
%         DEN=DEN+E1(B)*EP(B)*EP(B)*KR(B)*LI(B)/KL
%       END IF
% !
%       END DO
% !
%       DU2=ENGD
%       DERIV=(DU2-DU1)/DT
%       DU1=DU2
% !
%       RETURN
%       END
%    !-------------

% ENERG2
% ======
%
%  Esta subrotina avalia o desempenho da energia a cada passo de
%  integração.
%
%  MATLAB translation using GLOBAL variables instead of COMMON.
%
%  Energy types:
%     ENEX = External work done on the model
%     ENIN = Total internal energy dissipated or accumulated
%     ENCN = Total kinetic energy of the model
%     ENEL = Total elastic energy present in the model
%     ENDP = Energy dissipated by damping
%     ENGD = Energy dissipated by strain-softening effects
%     DEN  = Difference between external and internal energy

% -------------------------------------------------------------------------
%  Global variables (equivalent to the COMMON block)
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
%  Persistent local variables (keep DU1, DU2 between calls, like Fortran
%  SAVE-less but preserved in the calling program's memory)
% -------------------------------------------------------------------------
persistent DU1 DU2
if isempty(DU1), DU1 = 0.0; end
if isempty(DU2), DU2 = 0.0; end

% -------------------------------------------------------------------------
%  Local variables
% -------------------------------------------------------------------------
DEF  = 0.0;
AREA = 0.0;

ENCN  = 0.0;
ENEL  = 0.0;
ENGD  = 0.0;
DERIV = 0.0;
DEN   = 0.0;

if STEP == 1
    DU1 = 0.0;
    DU2 = 0.0;
end

% -------------------------------------------------------------------------
%  Kinetic energy ENCN
% -------------------------------------------------------------------------
% for I = 1:NNT
%     if I <= NNO
%         ENCN = ENCN + MAS(I)*VLX(I)*VLX(I)/2.0;
%         ENCN = ENCN + MAS(I)*VLY(I)*VLY(I)/2.0;
%         ENCN = ENCN + MAS(I)*VLZ(I)*VLZ(I)/2.0;
%     end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ENCN=ENCN+(MAS.*(VLX.^2.0))./2.0;
ENCN=ENCN+(MAS.*(VLY.^2.0))./2.0;
ENCN=ENCN+(MAS.*(VLZ.^2.0))./2.0;
% -------------------------------------------------------------------------
%  Elastic energy ENEL
% -------------------------------------------------------------------------
for B = 1:NBT
    KL = 2;
    % Divide by 2 the expression if bars are edge or symmetric bars.
    % This implies KL = 4.
    if B > NBA
        KL = 4;
    end

    DEF = SS(B)*SS(B)*LI(B)/KL;

    if SS(B) >= 0.0
        ENEL   = ENEL + E2(B)*DEF;
        EN(1,B) = E2(B)*DEF;
    else
        ENEL   = ENEL + E1(B)*DEF;
        EN(1,B) = E1(B)*DEF;
    end
    % ---------------------------------------------------------------------
    %  Strain-softening dissipated energy ENGD
    % ---------------------------------------------------------------------
    %  Broken and damaged bars
    if ~DM(B)
        AREA = E1(B)*EP(B)*EP(B) - E2(B)*EM(B)*EM(B) + ...
               (E1(B)*EP(B) + E2(B)*EM(B))*(EM(B) - EP(B));
        AREA = LI(B)*AREA/KL;

        if B == 7014   % bar number to be followed
            fprintf(fid_EnB, '%12.6e   %12.6e\n', TIME, AREA);
        end
        ENGD    = ENGD + AREA;
        EN(2,B) = AREA;
    end
    % Store only energy dissipated by broken bars
    if (~DM(B)) && (~FS(B))
        DEN = DEN + E1(B)*EP(B)*EP(B)*KR(B)*LI(B)/KL;
    end
end

DU2   = ENGD;
DERIV = (DU2 - DU1)/DT;
DU1   = DU2;

   ini=1;
   end

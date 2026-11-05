
function ini=CALOAD()
% CALOAD  Aplica as cargas nos nós em cada passo de tempo.
% Calcula também a energia externa fornecida ao sistema.
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

%       SUBROUTINE CALOAD
% !     =================
% !
% !  DATA:  22/03/1993
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina aplica as cargas nos nós em cada passo de tempo e calcula
% !  a energia externa fornecida ao sistema.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%        DOUBLE PRECISION TINI
%        LOGICAL Logic1,logic2,logic3
%      
% !--------------------------------------------------------------------------
%       DO NO=1,NNT
%       FX(NO)=FRX(NO)
%       FY(NO)=FRY(NO)
%       FZ(NO)=FRZ(NO)
%       FRX(NO)=0.0D00
%       FRY(NO)=0.0D00
%       FRZ(NO)=0.0D00
%       END DO
% !
% !--------------------------------------------------------------------------
% !   
% !--------------------------------------------------------------------------
%        
%          IF (TEST.EQ.101) THEN ! prism solicited by prescribed displacement to traction if Vf2 >0 , or to compression if Vf2<0, Vf2 is the displacement velocity
%              !applied in the last column of dentral nodes 
%            VF2=400.e-5!m/s
%               
%            DO I=1,NNT
%          LOGIC1=u0(I).LT.((M1-0.49)*LCo).AND.u0(I).GT.((M1-0.51)*LCo)
%          
%          IF(LOGIC1)THEN
%                        
%                U(2,I)=U0(I)-VF2*TIME
%           
%           !   end if 
%             
%              
%          !   IF(time.GT.5000*DT)THEN
%          !   ! W(2,I)=W(2,I)-(2*v0(I)/(N1*LCO)-1)*VF2*10.0*(time-5000*DT)
%          !    W(2,I)=W(2,I)-(2*v0(I)/(N1*LCO)-1)*VF2*1.0*DT
%          !  END IF
%          END IF
%                 
%            END DO
%   
%            ENDIF   !
%         IF (TEST.EQ.102) THEN  ! prism solicited as beam with two  vertical displacement in L/4 and (3/4)L by prescribed displacement, 
%             !the prism are supported by vertical support in the endsx=L/2 to rpoduce a  to traction if Vf2 >0 , or to compression if Vf2<0, Vf2 is the displacement velocity
%             
%            VF2=400.e-5!m/s
%               
%            DO I=1,NNT
%          LOGIC1=u0(I).LT.((M1-33.49)*LCo).AND.u0(I).GT.((M1-33.51)*LCo)
%          LOGIC3=v0(I).LT.((N1-0.49)*LCo).AND.v0(I).GT.((N1-0.51)*LCo)
%          LOGIC2=u0(I).LT.((33.51)*LCo).AND.u0(I).GT.((33.49)*LCo)     
%          IF(LOGIC1.AND.LOGIC3)THEN
%            V(2,I)=V0(I)-VF2*TIME
%          endif
%           IF(LOGIC1.AND.LOGIC2)THEN
%            V(2,I)=V0(I)-VF2*TIME
%          endif
%                                   
%            END DO
%   
%            ENDIF   !
%          RETURN
%       END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    FX  = FRX;
    FY  = FRY;
    FZ  = FRZ;
    FRX = zeros(1,NNT);
    FRY = zeros(1,NNT);
    FRZ = zeros(1,NNT);


%==========================================================================
% TEST 101: prism under prescribed axial (X) displacement
%==========================================================================
if TEST == 101
    VF2 = 400.0e-5;   % m/s displacement velocity

    for I = 1:NNT
        LOGIC1 = (U0(I) < (M1 - 0.49) * LCO) && ...
                 (U0(I) > (M1 - 0.51) * LCO);

        if LOGIC1
            U(2,I) = U0(I) - VF2 * TIME;

            % --- commented-out block from Fortran, kept for reference ----
            % if TIME > 5000*DT
            %     W(2,I) = W(2,I) - (2*V0(I)/(N1*LCO) - 1) * VF2 * 1.0 * DT;
            % end
        end
    end
end

%==========================================================================
% TEST 102: prism as beam, prescribed vertical displacements at L/4 & 3L/4
%==========================================================================
if TEST == 102
    VF2 = 400.0e-5;   % m/s

    for I = 1:NNT
        LOGIC1 = (U0(I) < (M1 - 33.49) * LCO) && ...
                 (U0(I) > (M1 - 33.51) * LCO);
        LOGIC3 = (V0(I) < (N1 - 0.49)  * LCO) && ...
                 (V0(I) > (N1 - 0.51)  * LCO);
        LOGIC2 = (U0(I) <  33.51 * LCO)       && ...
                 (U0(I) >  33.49 * LCO);

        if LOGIC1 && LOGIC3
            V(2,I) = V0(I) - VF2 * TIME;
        end
        if LOGIC1 && LOGIC2
            V(2,I) = V0(I) - VF2 * TIME;
        end
    end
end

ini=1;
 end

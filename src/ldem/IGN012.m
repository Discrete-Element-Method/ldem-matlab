
function ini=IGN012()
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
%!
%       SUBROUTINE IGN012
% !     =================
% !
% !  DATA:  08/04/1994
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina redefine as posições a cada passo de integração.
% !
% !--------------------------------------------------------------------------
% !  DESCRIÇÃO DAS VARIÁVEIS
% !--------------------------------------------------------------------------
% !
% !  (C)    ==>  O VALOR DAS VARIÁVEIS MUDAM DENTRO DESTA SUBROTINA
% !  (NC)   ==>  O VALOR DAS VARIÁVEIS NÃO MUDAM DENTRO DESTA SUBROTINA
% !  (INB)  ==>  ÍNDICE DE BARRAS
% !  (INN)  ==>  ÍNDICE DE NÓS
% !
% !  EST:(NC)       int.var   Índice que identifica o tipo de amortecimento
% !                           EST=0 ==> Amortecimento padrão (C=DF*M)
% !                           EST=1 ==> EST=0 + um amortecimento introduzido
% !                           na equação constitutiva com CON
% !                           EST=2 ==> EST=0, mas o coefic. de amortecimento
% !                           DF é multiplicado pelo índice de dano
% !  NNO:
% !  NNT:(NC)       int.var   Número de nós
% !  NBA:
% !  NBS:
% !  NBT:(NC)       int.var   Número de barras
% !  CN(2*INB):(NC) int.arr   Conectividade das barras
% !  E2(INB):
% !  E1(INB):(NC)   dp.arr    Módulo de Young das barras inalteradas
% !
% !  U0(INN):
% !  V0(INN):
% !  W0(INN):(NC)   dp.arr    Coordenadas nodais na forma inalterada
% !  U(3,INN):
% !  V(3,INN):
% !  W(3,INN):      dp.arr    Coordenadas nodais da estrutura
% !  BDX(INN):
% !  BDY(INN):
% !  BDZ(INN):(NC)  int.arr   Condições de contorno aplicadas sobre os nós
% !  ACX(INN):
% !  ACY(INN):
% !  ACZ(INN):(C)   dp.arr    Acelerações nodais
% !  VLX(INN):
% !  VLY(INN):
% !  VLZ(INN):(C)   dp.arr    Velocidades nodais
% !  MAS(INN):(NC)  dp.arr    Massa nodal
% !  FRX(INN):
% !  FRY(INN):
% !  FRZ(INN):(NC)  dp.arr    Forças nodais
% !  DF1:(C)        dp.var    Coeficiente de amortecimento
% !  ENDP:(C)       dp.var    Porção da energia dissipada por amortecimento
% !  LCO:(C)        dp.var    Comprimento original do elemento
% !  LI(INB):(NC)   dp.var    Comprimento de cada elemento
% !  DT:(NC)        dp.var    Incremento de integração
% !  CON:(NC)       dp.var    Coeficiente de amortecimento se EST=1
% !  DSS(INB):(NC)  dp.arr    Velocidades de deformação em cada elemento
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=20,INCON=8)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       DOUBLE PRECISION DDT,SDT,DF11,TM,DISS
% !--------------------------------------------------------------------------
% !
%       DO I=1,NNT
% !--------------------------------------------------------------------------
% !     CÁLCULO DE COEFICIENTES
% !--------------------------------------------------------------------------
%       DDT=2.0D00*DT
%       SDT=DT*DT
%       DF11=DF1
% !
%       IF (MAS(I).NE.0.0D00) THEN
%         TM=SDT/MAS(I)
%       END IF
% !
%       DMP1=(1.0D00-DF11*DT/2.0D00)
%       DMP2=(1.0D00+DF11*DT/2.0D00)
% !--------------------------------------------------------------------------
% !     CÁLCULO DAS NOVAS COORDENADAS POR DIFERENÇAS FINITAS CENTRAIS
% !--------------------------------------------------------------------------
%       IF (BDX(I)) 10,10,20
%    10 U(3,I)=(TM*FRX(I)+2.0D00*U(2,I)-DMP1*U(1,I))/DMP2
%       GO TO 30
%    20 U(3,I)=U(2,I)
%    30 CONTINUE
% !
%       IF (BDY(I)) 40,40,50
%    40 V(3,I)=(TM*FRY(I)+2.0D00*V(2,I)-DMP1*V(1,I))/DMP2
%       GO TO 60
%    50 V(3,I)=V(2,I)
%    60 CONTINUE
% !
%       IF (BDZ(I)) 70,70,80
%    70 W(3,I)=(TM*FRZ(I)+2.0D00*W(2,I)-DMP1*W(1,I))/DMP2
%       GO TO 90
%    80 W(3,I)=W(2,I)
%    90 CONTINUE
% !--------------------------------------------------------------------------
%       END DO
% !--------------------------------------------------------------------------
% !     CÁLCULO DAS VELOCIDADES E ACELERAÇÕES
% !--------------------------------------------------------------------------
%       DO I=1,NNT
% !
%       VLX(I)=(U(3,I)-U(1,I))/DDT
%       VLY(I)=(V(3,I)-V(1,I))/DDT
%       VLZ(I)=(W(3,I)-W(1,I))/DDT
%       ACX(I)=(U(3,I)-2.0D00*U(2,I)+U(1,I))/SDT
%       ACY(I)=(V(3,I)-2.0D00*V(2,I)+V(1,I))/SDT
%       ACZ(I)=(W(3,I)-2.0D00*W(2,I)+W(1,I))/SDT
% !--------------------------------------------------------------------------
% !     CÁLCULO DA ENERGIA DISSIPADA POR AMORTECIMENTO ENDP
% !--------------------------------------------------------------------------
%       DISS=DF11*MAS(I)/2.0D00
%       ENDP=ENDP+DISS*VLX(I)*(U(3,I)-U(1,I))
%       ENDP=ENDP+DISS*VLY(I)*(V(3,I)-V(1,I))
%       ENDP=ENDP+DISS*VLZ(I)*(W(3,I)-W(1,I))
% !
%       END DO
% !--------------------------------------------------------------------------
% ! 
% !--------------------------------------------------------------------------
%            DO B=1,NBT
%           KL=2
%           IF ((B.GT.NBA).AND.(B.LE.NBS)) KL=4
%           IF (SS(B).LT.0.0D00) THEN
%             ENDP=ENDP+2.0D00*(E1(B)*CON*DSS(B)*DSS(B)*DT*LI(B)/KL)
%           ELSE
%             ENDP=ENDP+2.0D00*(E2(B)*CON*DSS(B)*DSS(B)*DT*LI(B)/KL)
%           END IF
%         END DO
% !--------------------------------------------------------------------------
% !     ATUALIZA AS COORDENADAS
% !--------------------------------------------------------------------------
%       DO I=1,NNT
%       U(1,I)=U(2,I)
%       U(2,I)=U(3,I)
%       V(1,I)=V(2,I)
%       V(2,I)=V(3,I)
%       W(1,I)=W(2,I)
%       W(2,I)=W(3,I)
%       END DO
% !
%       RETURN
%       END
% !
function ign012
% IGN012
% ======
%
%  DATA:  08/04/1994
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina redefine as posições a cada passo de integração.
%
%  MATLAB translation using GLOBAL variables instead of COMMON.
%  The following globals must be defined in the workspace:
%     NNT, NBT, NBA, NBS, DT, DF1, MAS,
%     BDX, BDY, BDZ, FRX, FRY, FRZ,
%     U, V, W, VLX, VLY, VLZ, ACX, ACY, ACZ,
%     ENDP, SS, E1, E2, CON, DSS, LI
%
%  Note: The Fortran PARAMETER statement is not used here.


%--------------------------------------------------------------------------
%  Local variables
%--------------------------------------------------------------------------
TM = 0.0;   % initialize to avoid undefined use (Fortran local variable)

DDT  = 2.0 * DT;
SDT  = DT * DT;
DF11 = DF1;

DMP1 = (1.0 - DF11*DT/2.0);
DMP2 = (1.0 + DF11*DT/2.0);

%--------------------------------------------------------------------------
%  Calculate new coordinates by central finite differences
%--------------------------------------------------------------------------
for I = 1:NNT
    if MAS(I) ~= 0.0
        TM = SDT / MAS(I);
    end
    % If MAS(I) == 0, TM retains its previous value (as in Fortran)

    % X direction
    if BDX(I) <= 0
        U(3,I) = (TM*FRX(I) + 2.0*U(2,I) - DMP1*U(1,I)) / DMP2;
    else
        U(3,I) = U(2,I);
    end

    % Y direction
    if BDY(I) <= 0
        V(3,I) = (TM*FRY(I) + 2.0*V(2,I) - DMP1*V(1,I)) / DMP2;
    else
        V(3,I) = V(2,I);
    end

    % Z direction
    if BDZ(I) <= 0
        W(3,I) = (TM*FRZ(I) + 2.0*W(2,I) - DMP1*W(1,I)) / DMP2;
    else
        W(3,I) = W(2,I);
    end
end

%--------------------------------------------------------------------------
%  Calculate velocities and accelerations
%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for I = 1:NNT
%     VLX(I) = (U(3,I) - U(1,I)) / DDT;
%     VLY(I) = (V(3,I) - V(1,I)) / DDT;
%     VLZ(I) = (W(3,I) - W(1,I)) / DDT;
% 
%     ACX(I) = (U(3,I) - 2.0*U(2,I) + U(1,I)) / SDT;
%     ACY(I) = (V(3,I) - 2.0*V(2,I) + V(1,I)) / SDT;
%     ACZ(I) = (W(3,I) - 2.0*W(2,I) + W(1,I)) / SDT;
% 
%     % Dissipated energy by damping ENDP
%     DISS = DF11 * MAS(I) / 2.0;
%     ENDP = ENDP + DISS*VLX(I)*(U(3,I) - U(1,I));
%     ENDP = ENDP + DISS*VLY(I)*(V(3,I) - V(1,I));
%     ENDP = ENDP + DISS*VLZ(I)*(W(3,I) - W(1,I));
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    VLX = (U(3,:) - U(1,:))./ DDT;
    VLY = (V(3,:) - V(1,:))./ DDT;
    VLZ = (W(3,:) - W(1,:))./ DDT;
    ACX = (U(3,:) -U(2,:).*2.0 + U(1,:))./ SDT;
    ACY = (V(3,:) - V(2,I).*2.0 + V(1,:))./ SDT;
    ACZ = (W(3,:) - W(2,:).*2.0 + W(1,:))./ SDT;
 % Dissipated energy by damping ENDP
     ENDP = ENDP + (DF11.*(MAS./2.0)).*VLX.*(U(3,:)-U(1,:));
     ENDP = ENDP + (DF11.*(MAS./2.0)).*VLY.*(V(3,:)-V(1,:));
     ENDP = ENDP + (DF11.*(MAS./2.0)).*VLZ.*(W(3,:)-W(1,:));
%--------------------------------------------------------------------------
%  Additional damping energy in bars
%--------------------------------------------------------------------------
for B = 1:NBT
    KL = 2;
    if (B > NBA) && (B <= NBS)
        KL = 4;
    end

    if SS(B) < 0.0
        ENDP = ENDP + 2.0*(E1(B)*CON*DSS(B)*DSS(B)*DT*LI(B)/KL);
    else
        ENDP = ENDP + 2.0*(E2(B)*CON*DSS(B)*DSS(B)*DT*LI(B)/KL);
    end
end

%--------------------------------------------------------------------------
%  Update coordinates
%--------------------------------------------------------------------------
    U(1,:) = U(2,:);
    U(2,:) = U(3,:);
    V(1,:) = V(2,:);
    V(2,:) = V(3,:);
    W(1,:) = W(2,:);
    W(2,:) = W(3,:);
end


ini=1;
 end

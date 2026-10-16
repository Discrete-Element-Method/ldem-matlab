
function ini= ANSYS(IFILE,CONT1,CONT2,CONT3,CONT4,CONT5,CONT6)
global  INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED DM DS

%  SUBROUTINE ANSYS (IFILE,CONT1,CONT2,CONT3,CONT4,CONT5,CONT6)
% !     ================
% !
% !  DATA:  14/10/1992
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina gera arquivos *.ans (arquivos que permitem realizar
% !  saída gráfica compatível com o Ansys).
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER NOI,NOF
%       LOGICAL LABEL1,LABEL2,LABEL3,LABEL4,LABEL5,LABEL6
%       DOUBLE PRECISION ro,ri(INN),aba
%       LOGICAL logic1,logic2,logic3,Logic4,logic5
%       integer cont1,cont2,cont3,cont4,cont5,cont6
%          !variables for the test 5102( fretting test)
%        LOGICAL LABEL31,LABEL32,LABEL41,LABEL42
%        DOUBLE PRECISION Asigmax,a,th,AP,AQ,cfric,alph_sig,alph_q,Qast
%        DOUBLE PRECISION Past,po,c,xmid,Q,cp,sigmab,eep,pp,xi,ee
%        DOUBLE PRECISION Atemp,Qtpdt,qq,coef,rad_noi,rad_nof
% !--------------------------------------------------------------------------
%       !
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '/PREP7'
%       WRITE (IFILE,*) '/TITLE, TEMPO =',TIME
%       WRITE (IFILE,*) 'ET,1,4'
%       WRITE (IFILE,*) 'ET,2,4'
%       WRITE (IFILE,*) 'ET,IFILE,4'
%       WRITE (IFILE,*) 'ET,4,4'
%       WRITE (IFILE,*) 'ET,5,4'
%       WRITE (IFILE,*) 'ET,6,4'
%       WRITE (IFILE,*) 'ET,8,4'
%        WRITE (IFILE,*) 'ET,9,4'
%         WRITE (IFILE,*) 'ET,10,4'
%        WRITE (IFILE,*) 'ET,11,4'
%          WRITE (IFILE,*) 'ET,12,4'
%       WRITE (IFILE,*) 'MP,EX,1,2E10'
%       WRITE (IFILE,*) 'MP,PRXY,1,0.25'
%       WRITE (IFILE,*) 'MP,DENS,1,2500'
%       WRITE (IFILE,*) 'R,1,0.13,0.0014,0.36'
%       WRITE (IFILE,*)
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '!COORDENADAS NODAIS'
% !--------------------------------------------------------------------------
%       DO I=1,NNT
% 
%         WRITE (IFILE,*) 'N,',I,',',SNGL(U(3,I)),',',SNGL(V(3,I)),',',   &
%      &  SNGL(W(3,I))
%       END DO
%       WRITE (IFILE,*)
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '!CONECTIVIDADES DOS ELEMENTOS'
% !--------------------------------------------------------------------------
%       CONT1=0
%       CONT2=0
%       CONT3=0
%       CONT4=0
%       CONT5=0
%       CONT6=0
%       CONT7=0
%      
%       Write(*,*)DM(1),FS(1)
%            
%        DO I=1,NBT
%       NOI=CN(2*I-1)
%       NOF=CN(2*I)
%       
% !
%              
%   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    
%  
%       IF((DM(I)))THEN
%      
%       WRITE (IFILE,*) 'TYPE,1'
%       WRITE (IFILE,*) 'E',',',CN(2*I-1),',',CN(2*I),',!EL',I
%       CONT1=CONT1+1
%       else
%         
%       IF (FS(I)) THEN
% !     BARRAS DANIFICADAS - COR LARANJA
%       WRITE (IFILE,*) 'TYPE,2'
%       WRITE (IFILE,*) 'E',',',CN(2*I-1),',',CN(2*I),',!EL',I
%       CONT2=CONT2+1
%       ELSE
% !     BARRAS ROMPIDAS - COR VERMELHA
%       WRITE (IFILE,*) 'TYPE,5'
%       WRITE (IFILE,*) 'E',',',CN(2*I-1),',',CN(2*I),',!EL',I
%       CONT5=CONT5+1
%       END IF
%       END IF
% !
%       END DO
%        
%       WRITE (IFILE,*)
%       WRITE (IFILE,*) '!CORES DOS ELEMENTOS'
% !--------------------------------------------------------------------------
%    
%     
%       WRITE (IFILE,*) 'ESEL,S,TYPE,,1'
%       WRITE (IFILE,*) '/COLOR,ELEM,GCYA'
%       WRITE (IFILE,*) '/PNUM,TYPE,0'
%       WRITE (IFILE,*) '/NUMBER,1'
%       WRITE (IFILE,*) 'ESEL,ALL'
%       
%       WRITE (IFILE,*) 'ESEL,S,TYPE,,2'
%       WRITE (IFILE,*) '/COLOR,ELEM,ORAN'
%       WRITE (IFILE,*) '/PNUM,TYPE,0'
%       WRITE (IFILE,*) '/NUMBER,1'
%       WRITE (IFILE,*) 'ESEL,ALL'
% ! 
%       WRITE (IFILE,*) 'ESEL,S,TYPE,,5'
%       WRITE (IFILE,*) '/COLOR,ELEM,RED'
%       WRITE (IFILE,*) '/PNUM,TYPE,0'
%       WRITE (IFILE,*) '/NUMBER,1'
%       WRITE (IFILE,*) 'ESEL,ALL'
%      
%       WRITE (IFILE,*) 'ESEL,S,TYPE,,6'
%       WRITE (IFILE,*) '/COLOR,ELEM,GREE'
%       WRITE (IFILE,*) '/PNUM,TYPE,0'
%       WRITE (IFILE,*) '/NUMBER,1'
%       WRITE (IFILE,*) 'ESEL,ALL'
%       
%       
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '!CONDIÇÕES DE CONTORNO'
% !--------------------------------------------------------------------------
% 	IF (TEST.EQ.102) THEN
% 	  DO I=1,NNT
%           IF (BDX(I).EQ.1) THEN
%             WRITE (IFILE,*) 'D,',I,',','UX'
%           END IF
%          IF (BDY(I).EQ.1) THEN
%             WRITE (IFILE,*) 'D,',I,',','UY'
%           END IF
%           IF (BDZ(I).EQ.1) THEN
%             WRITE (IFILE,*) 'D,',I,',','UZ'
%           END IF
%         END DO
% 	END IF
%       WRITE (IFILE,*)
%       !WRITE (IFILE,*) 'D,',ncon(1),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(2),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(3),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(4),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(5),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(6),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(7),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(8),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(9),',','UY'
%       !WRITE (IFILE,*) 'D,',ncon(10),',','UY'
%       
%       
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '!CARGAS APLICADAS'
% !--------------------------------------------------------------------------
%       IF (TEST.EQ.102) THEN
%    
%          
%       
%           DO I=1,NNT
%         LOGIC1=u0(I).LT.((M1-0.49)*LCo).AND.u0(I).GT.((M1-0.51)*LCo)
%          LOGIC2=(V0(i).GT.(50.5-0.1)*Lco).AND.(V0(i).LT.(51.5+0.1)*Lco)
%          IF(LOGIC1.AND.LOGIC2)THEN
%       
%         WRITE (IFILE,*) 'F,',I,',','Fx',',',-10 
%       END IF
%       ENDDO
%       END IF
% !
%       WRITE (IFILE,*)
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '/VIEW,1,0,-1,0'
%       WRITE (IFILE,*) 'EPLOT'
%       WRITE (IFILE,*)
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*) '!ESTADO DAS BARRAS'
% !--------------------------------------------------------------------------
%       WRITE (IFILE,*)'!BARRAS INTACTAS =','    ',CONT1+CONT3+CONT6
%       WRITE (IFILE,*)'!BARRAS DANIFICADAS =',' ',CONT2+CONT4
%       WRITE (IFILE,*)'!BARRAS ROMPIDAS =','    ',CONT5
%       WRITE (IFILE,*)
% 
% !     Imprimir número de barras e em que estado estão
%       OPEN (UNIT=30,ACCESS='SEQUENTIAL',FILE='BARR_ROMP.dat',            &
%      &        STATUS='UNKNOWN') 
%       WRITE (30,100) TIME,VF,CONT1,CONT2,CONT5
%   100 FORMAT (E12.6,3X,E12.6,3X,I7,3X,I7,3X,I7)
% !
% 
%       RETURN
%       END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  DATA:  14/10/1992
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina gera arquivos *.ans (arquivos que permitem realizar
%  saída gráfica compatível com o Ansys).
%
% Translates the Fortran SUBROUTINE ANSYS.
% IFILE = open file handle for the *.ans output file.

%==========================================================================
% HEADER / SETUP
%==========================================================================
fprintf(IFILE, '/PREP7\n');
fprintf(IFILE, '/TITLE, TEMPO =%g\n', TIME);
fprintf(IFILE, 'ET,1,4\n');
fprintf(IFILE, 'ET,2,4\n');
fprintf(IFILE, 'ET,IFILE,4\n');
fprintf(IFILE, 'ET,4,4\n');
fprintf(IFILE, 'ET,5,4\n');
fprintf(IFILE, 'ET,6,4\n');
fprintf(IFILE, 'ET,8,4\n');
fprintf(IFILE, 'ET,9,4\n');
fprintf(IFILE, 'ET,10,4\n');
fprintf(IFILE, 'ET,11,4\n');
fprintf(IFILE, 'ET,12,4\n');
fprintf(IFILE, 'MP,EX,1,2E10\n');
fprintf(IFILE, 'MP,PRXY,1,0.25\n');
fprintf(IFILE, 'MP,DENS,1,2500\n');
fprintf(IFILE, 'R,1,0.13,0.0014,0.36\n');
fprintf(IFILE, '\n');

%--------------------------------------------------------------------------
% NODAL COORDINATES
%--------------------------------------------------------------------------
fprintf(IFILE, '!COORDENADAS NODAIS\n');

for I = 1:NNT
    fprintf(IFILE, 'N,%d,%g,%g,%g\n', ...
            I, single(U(3,I)), single(V(3,I)), single(W(3,I)));
end
fprintf(IFILE, '\n');

%--------------------------------------------------------------------------
% ELEMENT CONNECTIVITIES
%--------------------------------------------------------------------------
fprintf(IFILE, '!CONECTIVIDADES DOS ELEMENTOS\n');

CONT1 = 0;
CONT2 = 0;
CONT3 = 0;
CONT4 = 0;
CONT5 = 0;
CONT6 = 0;
CONT7 = 0;

fprintf(1, '%d %d\n', DM(1), FS(1));

for I = 1:NBT
    NOI = CN(2*I - 1);
    NOF = CN(2*I);

    if DM(I)
        % --- intact bars (not yet damaged) ------------------------------
        fprintf(IFILE, 'TYPE,1\n');
        fprintf(IFILE, 'E,%d,%d,!EL%d\n', CN(2*I-1), CN(2*I), I);
        CONT1 = CONT1 + 1;

    elseif FS(I)
        % --- damaged bars (orange) --------------------------------------
        fprintf(IFILE, 'TYPE,2\n');
        fprintf(IFILE, 'E,%d,%d,!EL%d\n', CN(2*I-1), CN(2*I), I);
        CONT2 = CONT2 + 1;

    else
        % --- broken bars (red) ------------------------------------------
        fprintf(IFILE, 'TYPE,5\n');
        fprintf(IFILE, 'E,%d,%d,!EL%d\n', CN(2*I-1), CN(2*I), I);
        CONT5 = CONT5 + 1;
    end
end

fprintf(IFILE, '\n');
fprintf(IFILE, '!CORES DOS ELEMENTOS\n');

%--------------------------------------------------------------------------
% ELEMENT COLORS (per TYPE)
%--------------------------------------------------------------------------
fprintf(IFILE, 'ESEL,S,TYPE,,1\n');
fprintf(IFILE, '/COLOR,ELEM,GCYA\n');
fprintf(IFILE, '/PNUM,TYPE,0\n');
fprintf(IFILE, '/NUMBER,1\n');
fprintf(IFILE, 'ESEL,ALL\n');

fprintf(IFILE, 'ESEL,S,TYPE,,2\n');
fprintf(IFILE, '/COLOR,ELEM,ORAN\n');
fprintf(IFILE, '/PNUM,TYPE,0\n');
fprintf(IFILE, '/NUMBER,1\n');
fprintf(IFILE, 'ESEL,ALL\n');

fprintf(IFILE, 'ESEL,S,TYPE,,5\n');
fprintf(IFILE, '/COLOR,ELEM,RED\n');
fprintf(IFILE, '/PNUM,TYPE,0\n');
fprintf(IFILE, '/NUMBER,1\n');
fprintf(IFILE, 'ESEL,ALL\n');

fprintf(IFILE, 'ESEL,S,TYPE,,6\n');
fprintf(IFILE, '/COLOR,ELEM,GREE\n');
fprintf(IFILE, '/PNUM,TYPE,0\n');
fprintf(IFILE, '/NUMBER,1\n');
fprintf(IFILE, 'ESEL,ALL\n');

%--------------------------------------------------------------------------
% BOUNDARY CONDITIONS
%--------------------------------------------------------------------------
fprintf(IFILE, '!CONDIÇÕES DE CONTORNO\n');

if TEST == 102
    for I = 1:NNT
        if BDX(I) == 1
            fprintf(IFILE, 'D,%d,UX\n', I);
        end
        if BDY(I) == 1
            fprintf(IFILE, 'D,%d,UY\n', I);
        end
        if BDZ(I) == 1
            fprintf(IFILE, 'D,%d,UZ\n', I);
        end
    end
end

fprintf(IFILE, '\n');
% --- Commented-out D-constraints from original code kept here for reference
% fprintf(IFILE, 'D,%d,UY\n', ncon(1));
% ... (etc.)

%--------------------------------------------------------------------------
% APPLIED LOADS
%--------------------------------------------------------------------------
fprintf(IFILE, '!CARGAS APLICADAS\n');

if TEST == 102
    for I = 1:NNT
        LOGIC1 = (U0(I) < (M1 - 0.49) * LCO) && (U0(I) > (M1 - 0.51) * LCO);
        LOGIC2 = (V0(I) > (50.5 - 0.1) * LCO) && (V0(I) < (51.5 + 0.1) * LCO);

        if LOGIC1 && LOGIC2
            fprintf(IFILE, 'F,%d,Fx,%d\n', I, -10);
        end
    end
end

fprintf(IFILE, '\n');

%--------------------------------------------------------------------------
% VIEW / PLOT
%--------------------------------------------------------------------------
fprintf(IFILE, '/VIEW,1,0,-1,0\n');
fprintf(IFILE, 'EPLOT\n');
fprintf(IFILE, '\n');

%--------------------------------------------------------------------------
% BAR STATE SUMMARY
%--------------------------------------------------------------------------
fprintf(IFILE, '!ESTADO DAS BARRAS\n');
fprintf(IFILE, '!BARRAS INTACTAS =    %d\n',    CONT1 + CONT3 + CONT6);
fprintf(IFILE, '!BARRAS DANIFICADAS = %d\n',   CONT2 + CONT4);
fprintf(IFILE, '!BARRAS ROMPIDAS =    %d\n',    CONT5);
fprintf(IFILE, '\n');

%--------------------------------------------------------------------------
% Separate bar-state summary file
% Fortran: OPEN (UNIT=30,FILE='BARR_ROMP.dat',STATUS='UNKNOWN')
% FORMAT (E12.6,3X,E12.6,3X,I7,3X,I7,3X,I7)
%--------------------------------------------------------------------------
VF=1.0
fid30 = fopen('BARR_ROMP.dat', 'w');
fprintf(fid30, '%12.6E   %12.6E   %7d   %7d   %7d\n', ...
        TIME, VF, CONT1, CONT2, CONT5);
fclose(fid30);
 ini=1;
 end
